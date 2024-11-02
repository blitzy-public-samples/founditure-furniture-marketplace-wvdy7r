#!/bin/bash

# HUMAN TASKS:
# 1. Ensure AWS CLI v2.0+ is installed and configured with KMS permissions
# 2. Configure kubectl v1.24+ with appropriate cluster access
# 3. Install jq v1.6+ for JSON processing
# 4. Create required log directory: /var/log/founditure
# 5. Create backup directory: /var/backup/keys
# 6. Set up appropriate IAM roles for KMS key management
# 7. Configure Kubernetes namespace permissions

# Required tool versions
# aws-cli: 2.0+
# kubectl: 1.24+
# jq: 1.6+

# Import health check functionality
source "$(dirname "${BASH_SOURCE[0]}")/health-check.sh"

# Global variables from specification
ROTATION_INTERVAL=86400
KEY_TYPES='["user-data", "location-data", "messages", "media-files"]'
LOG_FILE="/var/log/founditure/key-rotation.log"
BACKUP_DIR="/var/backup/keys"

# Initialize required directories
mkdir -p "$(dirname "${LOG_FILE}")" "${BACKUP_DIR}"

# Requirement: Key Management (7.2.1 Encryption Standards/Key Management)
rotate_kms_key() {
    local key_alias=$1
    local key_type=$2
    local new_key_id=""
    
    # Verify current key status
    local current_key=$(aws kms describe-key --key-id "alias/${key_alias}" --output json)
    if [ $? -ne 0 ]; then
        log_rotation "${key_type}" "ERROR" "Failed to retrieve current key status"
        return 1
    }
    
    # Backup old key metadata
    local timestamp=$(date +%Y%m%d-%H%M%S)
    echo "${current_key}" > "${BACKUP_DIR}/${key_type}-${timestamp}.json"
    
    # Create new key version
    local new_key=$(aws kms create-key --description "Founditure ${key_type} encryption key" --output json)
    if [ $? -eq 0 ]; then
        new_key_id=$(echo "${new_key}" | jq -r '.KeyMetadata.KeyId')
        
        # Update key alias
        aws kms update-alias \
            --alias-name "alias/${key_alias}" \
            --target-key-id "${new_key_id}"
            
        if [ $? -eq 0 ]; then
            log_rotation "${key_type}" "SUCCESS" "New key created with ID: ${new_key_id}"
        else
            log_rotation "${key_type}" "ERROR" "Failed to update alias for new key"
            return 1
        fi
    else
        log_rotation "${key_type}" "ERROR" "Failed to create new key"
        return 1
    fi
    
    echo "${new_key_id}"
}

# Requirement: Security Controls (7.3.3 Security Controls/Security Compliance)
update_k8s_secrets() {
    local namespace=$1
    local secret_name=$2
    local key_data=$3
    
    # Backup existing secret
    local timestamp=$(date +%Y%m%d-%H%M%S)
    kubectl get secret "${secret_name}" -n "${namespace}" -o yaml > \
        "${BACKUP_DIR}/${namespace}-${secret_name}-${timestamp}.yaml"
    
    # Create new secret version
    local secret_json=$(echo "${key_data}" | base64)
    kubectl create secret generic "${secret_name}" \
        --from-literal="key_data=${secret_json}" \
        --namespace="${namespace}" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    if [ $? -eq 0 ]; then
        # Verify secret propagation
        local verify_attempts=0
        while [ $verify_attempts -lt 5 ]; do
            if kubectl get secret "${secret_name}" -n "${namespace}" &>/dev/null; then
                return 0
            fi
            verify_attempts=$((verify_attempts + 1))
            sleep 5
        done
        return 1
    fi
    return 1
}

# Requirement: Data Protection (7.2 Data Security/7.2.1 Encryption Standards)
rotate_service_keys() {
    local service_name=$1
    local key_type=$2
    local status=0
    
    # Identify service key dependencies
    local key_alias="founditure-${service_name}-${key_type}"
    
    # Generate new key material
    local new_key_id=$(rotate_kms_key "${key_alias}" "${key_type}")
    if [ $? -eq 0 ] && [ ! -z "${new_key_id}" ]; then
        # Update service configuration
        local key_data=$(aws kms describe-key --key-id "${new_key_id}" --output json)
        
        # Update Kubernetes secrets
        if update_k8s_secrets "${service_name}" "${key_type}-key" "${key_data}"; then
            # Verify service health
            if ! check_all_components "${service_name}"; then
                log_rotation "${key_type}" "ERROR" "Service health check failed after key rotation"
                status=1
            fi
        else
            log_rotation "${key_type}" "ERROR" "Failed to update Kubernetes secrets"
            status=1
        fi
    else
        log_rotation "${key_type}" "ERROR" "Failed to rotate KMS key"
        status=1
    fi
    
    # Return status object
    echo "{\"status\": ${status}, \"key_id\": \"${new_key_id}\"}"
}

validate_rotation() {
    local service_name=$1
    local new_key_id=$2
    
    # Check service health
    if ! check_all_components "${service_name}"; then
        log_rotation "${service_name}" "ERROR" "Service health validation failed"
        return 1
    }
    
    # Verify key usage
    local key_check=$(aws kms describe-key --key-id "${new_key_id}" --output json)
    if [ $? -ne 0 ]; then
        log_rotation "${service_name}" "ERROR" "Key validation failed"
        return 1
    }
    
    # Test encryption/decryption
    local test_data="key-rotation-test-$(date +%s)"
    local encrypted=$(aws kms encrypt \
        --key-id "${new_key_id}" \
        --plaintext "${test_data}" \
        --output text \
        --query CiphertextBlob)
    
    if [ $? -eq 0 ]; then
        local decrypted=$(aws kms decrypt \
            --ciphertext-blob "${encrypted}" \
            --output text \
            --query Plaintext | base64 --decode)
        
        if [ "${decrypted}" = "${test_data}" ]; then
            log_rotation "${service_name}" "SUCCESS" "Key validation successful"
            return 0
        fi
    fi
    
    log_rotation "${service_name}" "ERROR" "Key encryption test failed"
    return 1
}

log_rotation() {
    local key_type=$1
    local status=$2
    local details=$3
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Format log entry
    local log_entry="${timestamp} [${key_type}] ${status}: ${details}"
    echo "${log_entry}" >> "${LOG_FILE}"
    
    # Archive old logs if needed
    if [ $(stat -f%z "${LOG_FILE}") -gt 104857600 ]; then # 100MB
        mv "${LOG_FILE}" "${LOG_FILE}.$(date +%Y%m%d-%H%M%S)"
        touch "${LOG_FILE}"
    fi
    
    # Send notifications if needed
    if [ "${status}" = "ERROR" ]; then
        aws sns publish \
            --topic-arn "${SNS_TOPIC_ARN}" \
            --message "Key rotation error for ${key_type}: ${details}"
    fi
}

# Main rotation process
main_rotation_process() {
    while true; do
        for key_type in $(echo "${KEY_TYPES}" | jq -r '.[]'); do
            # Get services using this key type
            local services=$(kubectl get namespaces -l "uses-key-type=${key_type}" \
                -o jsonpath='{.items[*].metadata.name}')
            
            for service in ${services}; do
                echo "Rotating keys for service ${service}, type ${key_type}"
                
                # Perform key rotation
                local rotation_result=$(rotate_service_keys "${service}" "${key_type}")
                local status=$(echo "${rotation_result}" | jq -r '.status')
                local new_key_id=$(echo "${rotation_result}" | jq -r '.key_id')
                
                if [ "${status}" -eq 0 ] && [ ! -z "${new_key_id}" ]; then
                    # Validate rotation
                    if ! validate_rotation "${service}" "${new_key_id}"; then
                        log_rotation "${key_type}" "ERROR" "Validation failed for ${service}"
                    fi
                fi
            done
        done
        
        sleep "${ROTATION_INTERVAL}"
    done
}

# Start key rotation if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_rotation_process
fi