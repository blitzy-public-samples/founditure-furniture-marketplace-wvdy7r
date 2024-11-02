#!/bin/bash

# HUMAN TASKS:
# 1. Ensure AWS CLI v2.x is installed and configured with appropriate permissions
# 2. Install required tools: curl (7.x), redis-cli (6.x), kubectl (1.24+)
# 3. Configure environment-specific variables in /etc/founditure/env.conf
# 4. Set up appropriate IAM roles and security group access for monitoring
# 5. Configure alert notification endpoints (email, Slack, etc.)
# 6. Ensure log directory exists and has appropriate permissions

# Required tool versions
# curl: 7.x
# aws-cli: 2.x
# kubectl: 1.24+
# redis-cli: 6.x

# Global variables from specification
CHECK_INTERVAL=300
HEALTH_LOG="/var/log/founditure/health-check.log"
ALERT_THRESHOLD=3
ENVIRONMENTS='["dev", "staging", "prod"]'

# Additional configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/founditure-health"
ALERT_COUNT_FILE="${TEMP_DIR}/alert_count"
CONFIG_FILE="/etc/founditure/env.conf"

# Initialize
mkdir -p "${TEMP_DIR}"
touch "${HEALTH_LOG}"

# Load environment configuration
if [ -f "${CONFIG_FILE}" ]; then
    source "${CONFIG_FILE}"
fi

# Requirement: System Health Monitoring (3.5 Scalability Architecture/System Health Metrics)
log_health_status() {
    local component=$1
    local status=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="${timestamp} [${component}] ${status}"
    
    echo "${log_entry}" >> "${HEALTH_LOG}"
    
    # Check alert threshold
    if [[ "${status}" == *"CRITICAL"* ]] || [[ "${status}" == *"ERROR"* ]]; then
        local current_count=$(cat "${ALERT_COUNT_FILE}" 2>/dev/null || echo 0)
        current_count=$((current_count + 1))
        echo "${current_count}" > "${ALERT_COUNT_FILE}"
        
        if [ "${current_count}" -ge "${ALERT_THRESHOLD}" ]; then
            # Send alert notification
            send_alert "${component}" "${status}"
            echo 0 > "${ALERT_COUNT_FILE}"
        fi
    fi
}

# Requirement: API Health Verification (6.3 API Design/6.3.1 RESTful Endpoints)
check_api_health() {
    local env=$1
    local status="OK"
    local endpoints=(
        "/api/v1/health"
        "/api/v1/furniture/health"
        "/api/v1/messages/health"
        "/api/v1/users/health"
    )
    
    for endpoint in "${endpoints[@]}"; do
        local response=$(curl -s -o /dev/null -w "%{http_code}" \
            "https://api.${env}.founditure.com${endpoint}")
        
        if [ "${response}" != "200" ]; then
            status="CRITICAL - API endpoint ${endpoint} returned ${response}"
            break
        fi
    done
    
    echo "${status}"
}

# Requirement: Infrastructure Monitoring (8.1 Deployment Environment/Environment Matrix)
check_database_health() {
    local env=$1
    local status="OK"
    
    # Check RDS primary connection using imported primary_endpoint
    local db_response=$(PGPASSWORD="${DB_PASSWORD}" psql -h "${primary_endpoint}" \
        -U "${DB_USER}" -d "${DB_NAME}" -c "SELECT 1" 2>&1)
    
    if [ $? -ne 0 ]; then
        status="CRITICAL - Database connection failed: ${db_response}"
    else
        # Check replication lag
        local lag_check=$(PGPASSWORD="${DB_PASSWORD}" psql -h "${primary_endpoint}" \
            -U "${DB_USER}" -d "${DB_NAME}" \
            -c "SELECT EXTRACT(EPOCH FROM NOW() - pg_last_xact_replay_timestamp())::INT as lag" \
            -t -A 2>&1)
        
        if [ $? -eq 0 ] && [ "${lag_check}" -gt 300 ]; then
            status="WARNING - Replication lag: ${lag_check} seconds"
        fi
    fi
    
    echo "${status}"
}

check_cache_health() {
    local env=$1
    local status="OK"
    
    # Check Redis connection and replication
    local redis_response=$(redis-cli -h "redis.${env}.founditure.com" PING 2>&1)
    
    if [ "${redis_response}" != "PONG" ]; then
        status="CRITICAL - Redis connection failed: ${redis_response}"
    else
        # Check memory usage
        local memory_usage=$(redis-cli -h "redis.${env}.founditure.com" INFO memory | \
            grep "used_memory_rss" | cut -d: -f2)
        
        if [ "${memory_usage}" -gt 1073741824 ]; then # 1GB threshold
            status="WARNING - High memory usage: ${memory_usage} bytes"
        fi
    fi
    
    echo "${status}"
}

check_kubernetes_health() {
    local env=$1
    local status="OK"
    
    # Check node status
    local nodes_status=$(kubectl get nodes --context="${env}" -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}')
    
    if [[ "${nodes_status}" == *"False"* ]]; then
        status="CRITICAL - Unhealthy nodes detected"
    else
        # Check pod health
        local unhealthy_pods=$(kubectl get pods --context="${env}" --all-namespaces \
            -o jsonpath='{.items[?(@.status.phase!="Running")].metadata.name}')
        
        if [ ! -z "${unhealthy_pods}" ]; then
            status="WARNING - Unhealthy pods: ${unhealthy_pods}"
        fi
    fi
    
    echo "${status}"
}

check_messaging_health() {
    local env=$1
    local status="OK"
    
    # Check MQTT broker
    local mqtt_response=$(timeout 5 mosquitto_sub -h "mqtt.${env}.founditure.com" \
        -t "health/check" -C 1 2>&1)
    
    if [ $? -ne 0 ]; then
        status="CRITICAL - MQTT broker connection failed: ${mqtt_response}"
    else
        # Check WebSocket connection
        local ws_response=$(curl -s -N -i "wss://ws.${env}.founditure.com/health" \
            --max-time 5 2>&1)
        
        if [[ ! "${ws_response}" =~ "101 Switching Protocols" ]]; then
            status="CRITICAL - WebSocket connection failed"
        fi
    fi
    
    echo "${status}"
}

send_alert() {
    local component=$1
    local status=$2
    
    # Send to multiple alert channels
    # Email
    aws ses send-email \
        --from "alerts@founditure.com" \
        --to "oncall@founditure.com" \
        --subject "Health Check Alert: ${component}" \
        --text "${status}"
    
    # Slack
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"Health Check Alert - ${component}: ${status}\"}" \
        "${SLACK_WEBHOOK_URL}"
}

# Main health check loop
main() {
    while true; do
        for env in $(echo "${ENVIRONMENTS}" | jq -r '.[]'); do
            # API Health
            local api_status=$(check_api_health "${env}")
            log_health_status "API-${env}" "${api_status}"
            
            # Database Health
            local db_status=$(check_database_health "${env}")
            log_health_status "Database-${env}" "${db_status}"
            
            # Cache Health
            local cache_status=$(check_cache_health "${env}")
            log_health_status "Cache-${env}" "${cache_status}"
            
            # Kubernetes Health
            local k8s_status=$(check_kubernetes_health "${env}")
            log_health_status "Kubernetes-${env}" "${k8s_status}"
            
            # Messaging Health
            local msg_status=$(check_messaging_health "${env}")
            log_health_status "Messaging-${env}" "${msg_status}"
        done
        
        # Rotate log file if it exceeds 100MB
        if [ $(stat -f%z "${HEALTH_LOG}") -gt 104857600 ]; then
            mv "${HEALTH_LOG}" "${HEALTH_LOG}.$(date +%Y%m%d-%H%M%S)"
            touch "${HEALTH_LOG}"
        fi
        
        sleep "${CHECK_INTERVAL}"
    done
}

# Start health checks
main