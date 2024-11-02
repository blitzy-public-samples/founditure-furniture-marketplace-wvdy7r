#!/bin/bash

# HUMAN TASKS:
# 1. Configure AWS credentials and region in Jenkins credentials store
# 2. Set up Kubernetes cluster access in Jenkins configuration
# 3. Configure environment-specific variables in Jenkins credentials
# 4. Set up monitoring alerts for rollback status
# 5. Configure rollback approval gates for production
# 6. Ensure proper IAM roles for EKS access
# 7. Set up Slack/Email notifications for rollback status

# Required tool versions:
# kubectl: v1.24+
# aws-cli: v2.x
# jq: v1.6

set -euo pipefail

# Source directory for dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/health-check.sh"

# Global variables from specification
ENVIRONMENTS=('dev' 'staging' 'prod')
ROLLBACK_TIMEOUT=300
MAX_RETRY_ATTEMPTS=3
LOG_DIR="/var/log/founditure/rollbacks"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Requirement: Automated rollback capabilities for different environments
perform_rollback() {
    local environment=$1
    local deployment_name=$2
    local previous_version=$3
    local exit_code=0

    echo "Initiating rollback for ${deployment_name} in ${environment} to version ${previous_version}"
    log_rollback_status "${environment}" "${deployment_name}" "STARTED" "Initiating rollback to version ${previous_version}"

    # Configure AWS credentials
    aws configure set aws_access_key_id "${AWS_ACCESS_KEY_ID}"
    aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}"
    aws configure set region "${AWS_REGION}"

    # Connect to appropriate EKS cluster
    aws eks update-kubeconfig --name "founditure-${environment}" --region "${AWS_REGION}"

    # Execute rollback based on environment
    case "${environment}" in
        dev)
            rollback_kubernetes_deployment "${environment}" "${deployment_name}" "${previous_version}" || exit_code=$?
            ;;
        staging)
            rollback_kubernetes_deployment "${environment}" "${deployment_name}" "${previous_version}" || exit_code=$?
            verify_rollback_health "${environment}" "${deployment_name}" || exit_code=$?
            ;;
        prod)
            # Production requires additional verification
            if rollback_kubernetes_deployment "${environment}" "${deployment_name}" "${previous_version}"; then
                verify_rollback_health "${environment}" "${deployment_name}" || exit_code=$?
            else
                exit_code=1
            fi
            ;;
        *)
            log_rollback_status "${environment}" "${deployment_name}" "FAILED" "Invalid environment specified"
            return 1
            ;;
    esac

    if [ ${exit_code} -eq 0 ]; then
        log_rollback_status "${environment}" "${deployment_name}" "SUCCESS" "Rollback completed successfully"
    else
        log_rollback_status "${environment}" "${deployment_name}" "FAILED" "Rollback failed with exit code ${exit_code}"
    fi

    return ${exit_code}
}

# Requirement: Container Orchestration - Manages Kubernetes rollback operations
rollback_kubernetes_deployment() {
    local namespace=$1
    local deployment_name=$2
    local revision=$3
    local attempt=1

    echo "Executing Kubernetes rollback for ${deployment_name} in ${namespace}"

    while [ ${attempt} -le ${MAX_RETRY_ATTEMPTS} ]; do
        echo "Rollback attempt ${attempt}/${MAX_RETRY_ATTEMPTS}"

        # Get deployment history
        local history=$(kubectl rollout history deployment/${deployment_name} -n "${namespace}")
        if [ $? -ne 0 ]; then
            echo "Failed to get deployment history"
            return 1
        fi

        # Pause current deployment
        kubectl rollout pause deployment/${deployment_name} -n "${namespace}"

        # Execute rollback
        if [ -n "${revision}" ]; then
            kubectl rollout undo deployment/${deployment_name} -n "${namespace}" --to-revision=${revision}
        else
            kubectl rollout undo deployment/${deployment_name} -n "${namespace}"
        fi

        # Wait for rollback completion
        if kubectl rollout status deployment/${deployment_name} -n "${namespace}" --timeout=${ROLLBACK_TIMEOUT}s; then
            # Resume deployment
            kubectl rollout resume deployment/${deployment_name} -n "${namespace}"
            return 0
        fi

        echo "Rollback attempt ${attempt} failed, retrying..."
        ((attempt++))
        sleep 10
    done

    echo "Rollback failed after ${MAX_RETRY_ATTEMPTS} attempts"
    return 1
}

# Requirement: High Availability - Ensures zero-downtime during rollback
verify_rollback_health() {
    local namespace=$1
    local deployment_name=$2
    local health_check_passed=false

    echo "Verifying system health after rollback"

    # Check backend health
    if ! check_backend_health "${namespace}"; then
        echo "Backend health check failed"
        return 1
    fi

    # Check monitoring health
    if ! check_monitoring_health "${namespace}"; then
        echo "Monitoring health check failed"
        return 1
    fi

    # Verify pod status
    local ready_pods=$(kubectl get deployment ${deployment_name} -n "${namespace}" \
        -o jsonpath='{.status.readyReplicas}')
    local desired_pods=$(kubectl get deployment ${deployment_name} -n "${namespace}" \
        -o jsonpath='{.spec.replicas}')

    if [ "${ready_pods}" != "${desired_pods}" ]; then
        echo "Pod readiness check failed. Ready: ${ready_pods}, Desired: ${desired_pods}"
        return 1
    fi

    # Verify service endpoints
    local endpoints=$(kubectl get endpoints ${deployment_name} -n "${namespace}" \
        -o jsonpath='{.subsets[*].addresses[*].ip}')
    if [ -z "${endpoints}" ]; then
        echo "No endpoints available for service"
        return 1
    fi

    return 0
}

# Requirement: Logging and Monitoring - Logs rollback operation details
log_rollback_status() {
    local environment=$1
    local deployment_name=$2
    local status=$3
    local message=$4
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="${LOG_DIR}/rollback-${environment}-${deployment_name}.log"

    # Format log message
    local log_entry="${timestamp} [${status}] ${message}"
    echo "${log_entry}" >> "${log_file}"

    # Send notification based on status
    case "${status}" in
        "STARTED"|"FAILED")
            # Send alert notification
            if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
                curl -s -X POST -H 'Content-type: application/json' \
                    --data "{\"text\":\"Rollback ${status} - ${environment}/${deployment_name}: ${message}\"}" \
                    "${SLACK_WEBHOOK_URL}"
            fi
            ;;
        "SUCCESS")
            # Update metrics
            if [ -n "${PROMETHEUS_PUSHGATEWAY:-}" ]; then
                echo "rollback_success{environment=\"${environment}\",deployment=\"${deployment_name}\"} 1" | \
                    curl -s --data-binary @- "${PROMETHEUS_PUSHGATEWAY}/metrics/job/rollback"
            fi
            ;;
    esac
}

# Main execution
main() {
    if [ $# -ne 3 ]; then
        echo "Usage: $0 <environment> <deployment_name> <previous_version>"
        echo "Environments: ${ENVIRONMENTS[*]}"
        exit 1
    fi

    local environment=$1
    local deployment_name=$2
    local previous_version=$3

    if [[ ! " ${ENVIRONMENTS[@]} " =~ " ${environment} " ]]; then
        echo "Invalid environment: ${environment}"
        echo "Valid environments are: ${ENVIRONMENTS[*]}"
        exit 1
    fi

    # Execute rollback
    if perform_rollback "${environment}" "${deployment_name}" "${previous_version}"; then
        echo "Rollback completed successfully"
        exit 0
    else
        echo "Rollback failed"
        exit 1
    fi
}

# Execute main function with provided arguments
main "$@"