#!/bin/bash

# HUMAN TASKS:
# 1. Configure AWS credentials and region in Jenkins credentials store
# 2. Set up Kubernetes cluster access in Jenkins configuration
# 3. Configure environment-specific variables in Jenkins credentials
# 4. Set up monitoring alerts for deployment status
# 5. Configure deployment approval gates for production
# 6. Ensure proper IAM roles for ECR access
# 7. Set up Slack/Email notifications for deployment status

# Required tool versions:
# kubectl: v1.24+
# aws-cli: v2.x
# jq: v1.6

set -euo pipefail

# Source directory for health check functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/health-check.sh"

# Global variables from specification
ENVIRONMENTS=('dev' 'staging' 'prod')
DEPLOYMENT_STRATEGIES=('direct' 'blue-green' 'canary')
DOCKER_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Requirement: Deployment Strategy - Environment-specific deployment strategies
deploy_to_environment() {
    local environment=$1
    local version=$2
    local exit_code=0

    echo "Starting deployment to ${environment} environment with version ${version}"

    # Configure AWS credentials
    aws configure set aws_access_key_id "${AWS_ACCESS_KEY_ID}"
    aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}"
    aws configure set region "${AWS_REGION}"

    # Connect to EKS cluster
    aws eks update-kubeconfig --name "founditure-${environment}" --region "${AWS_REGION}"

    # Select deployment strategy based on environment
    case "${environment}" in
        dev)
            deploy_direct "${environment}" "${version}" || exit_code=$?
            ;;
        staging)
            deploy_blue_green "${environment}" "${version}" || exit_code=$?
            ;;
        prod)
            deploy_canary "${environment}" "${version}" 10 || exit_code=$?
            ;;
        *)
            echo "Invalid environment: ${environment}"
            return 1
            ;;
    esac

    # Verify deployment health
    if [ ${exit_code} -eq 0 ]; then
        verify_deployment "${environment}" "founditure-backend" || exit_code=$?
    fi

    # Update deployment status
    if [ ${exit_code} -eq 0 ]; then
        echo "Deployment to ${environment} completed successfully"
    else
        echo "Deployment to ${environment} failed with exit code ${exit_code}"
        rollback_deployment "${environment}" "founditure-backend" "${version}"
    fi

    return ${exit_code}
}

# Requirement: Direct Push for Development - Simple deployment for dev environment
deploy_direct() {
    local namespace=$1
    local version=$2
    local deployment_name="founditure-backend"

    echo "Executing direct deployment to ${namespace}"

    # Apply Kubernetes manifests
    kubectl apply -f "${SCRIPT_DIR}/../../kubernetes/backend/deployment.yml" -n "${namespace}"

    # Update container image
    kubectl set image deployment/${deployment_name} \
        ${deployment_name}="${DOCKER_REGISTRY}/founditure-backend:${version}" \
        -n "${namespace}"

    # Wait for rollout completion
    kubectl rollout status deployment/${deployment_name} -n "${namespace}" --timeout=300s

    # Verify pod health
    local ready_pods=$(kubectl get pods -n "${namespace}" -l app=${deployment_name} \
        -o jsonpath='{.items[*].status.containerStatuses[0].ready}' | tr ' ' '\n' | grep -c "true")
    
    [ "${ready_pods}" -gt 0 ] || return 1

    return 0
}

# Requirement: Blue/Green for Staging - Zero-downtime deployment for staging
deploy_blue_green() {
    local namespace=$1
    local version=$2
    local deployment_name="founditure-backend"
    local blue_green_suffix

    echo "Executing blue/green deployment to ${namespace}"

    # Determine current active deployment (blue or green)
    if kubectl get service ${deployment_name} -n "${namespace}" -o jsonpath='{.spec.selector.color}' | grep -q "blue"; then
        blue_green_suffix="green"
    else
        blue_green_suffix="blue"
    fi

    # Create new deployment
    sed "s/\${COLOR}/${blue_green_suffix}/g" "${SCRIPT_DIR}/../../kubernetes/backend/deployment.yml" | \
        kubectl apply -f - -n "${namespace}"

    # Update container image in new deployment
    kubectl set image deployment/${deployment_name}-${blue_green_suffix} \
        ${deployment_name}="${DOCKER_REGISTRY}/founditure-backend:${version}" \
        -n "${namespace}"

    # Wait for new pods
    kubectl rollout status deployment/${deployment_name}-${blue_green_suffix} \
        -n "${namespace}" --timeout=300s

    # Verify new deployment
    if verify_deployment "${namespace}" "${deployment_name}-${blue_green_suffix}"; then
        # Switch service selector to new deployment
        kubectl patch service ${deployment_name} -n "${namespace}" -p \
            "{\"spec\":{\"selector\":{\"color\":\"${blue_green_suffix}\"}}}"

        # Verify traffic routing
        sleep 30
        if verify_deployment "${namespace}" "${deployment_name}-${blue_green_suffix}"; then
            # Remove old deployment
            local old_suffix=$([ "${blue_green_suffix}" == "blue" ] && echo "green" || echo "blue")
            kubectl delete deployment ${deployment_name}-${old_suffix} -n "${namespace}"
            return 0
        fi
    fi

    return 1
}

# Requirement: Canary for Production - Gradual rollout for production
deploy_canary() {
    local namespace=$1
    local version=$2
    local canary_percentage=$3
    local deployment_name="founditure-backend"
    local exit_code=0

    echo "Executing canary deployment to ${namespace} with initial ${canary_percentage}% traffic"

    # Deploy canary pods
    sed "s/\${REPLICAS}/1/g" "${SCRIPT_DIR}/../../kubernetes/backend/deployment.yml" | \
        kubectl apply -f - -n "${namespace}" --suffix="-canary"

    # Update canary image
    kubectl set image deployment/${deployment_name}-canary \
        ${deployment_name}="${DOCKER_REGISTRY}/founditure-backend:${version}" \
        -n "${namespace}"

    # Wait for canary pods
    kubectl rollout status deployment/${deployment_name}-canary -n "${namespace}" --timeout=300s

    # Configure initial traffic split
    kubectl patch service ${deployment_name} -n "${namespace}" -p \
        "{\"spec\":{\"trafficPolicy\":{\"canary\":{\"weight\":${canary_percentage}}}}}"

    # Monitor metrics
    local step=10
    local max_percentage=100
    local current_percentage=${canary_percentage}

    while [ ${current_percentage} -lt ${max_percentage} ]; do
        sleep 60
        
        # Check health metrics
        if ! verify_deployment "${namespace}" "${deployment_name}-canary"; then
            echo "Canary deployment health check failed"
            exit_code=1
            break
        fi

        # Gradually increase traffic
        current_percentage=$((current_percentage + step))
        kubectl patch service ${deployment_name} -n "${namespace}" -p \
            "{\"spec\":{\"trafficPolicy\":{\"canary\":{\"weight\":${current_percentage}}}}}"
    done

    if [ ${exit_code} -eq 0 ]; then
        # Promote canary to main deployment
        kubectl apply -f "${SCRIPT_DIR}/../../kubernetes/backend/deployment.yml" -n "${namespace}"
        kubectl set image deployment/${deployment_name} \
            ${deployment_name}="${DOCKER_REGISTRY}/founditure-backend:${version}" \
            -n "${namespace}"
        
        # Remove canary deployment
        kubectl delete deployment ${deployment_name}-canary -n "${namespace}"
    else
        # Rollback canary deployment
        rollback_deployment "${namespace}" "${deployment_name}-canary" "${version}"
    fi

    return ${exit_code}
}

# Requirement: High Availability - Deployment verification
verify_deployment() {
    local namespace=$1
    local deployment_name=$2
    local timeout=300
    local interval=10
    local elapsed=0

    echo "Verifying deployment health for ${deployment_name} in ${namespace}"

    # Check pod status
    while [ ${elapsed} -lt ${timeout} ]; do
        local ready_pods=$(kubectl get deployment ${deployment_name} -n "${namespace}" \
            -o jsonpath='{.status.readyReplicas}')
        local desired_pods=$(kubectl get deployment ${deployment_name} -n "${namespace}" \
            -o jsonpath='{.spec.replicas}')

        if [ "${ready_pods}" == "${desired_pods}" ]; then
            # Verify replicas
            if [ ${ready_pods} -gt 0 ]; then
                # Check health endpoints
                if check_api_health "${namespace}" && \
                   check_database_health "${namespace}" && \
                   check_cache_health "${namespace}" && \
                   check_kubernetes_health "${namespace}" && \
                   check_messaging_health "${namespace}"; then
                    return 0
                fi
            fi
        fi

        sleep ${interval}
        elapsed=$((elapsed + interval))
    done

    echo "Deployment verification failed for ${deployment_name} in ${namespace}"
    return 1
}

# Requirement: High Availability - Rollback procedure
rollback_deployment() {
    local namespace=$1
    local deployment_name=$2
    local previous_version=$3

    echo "Initiating rollback for ${deployment_name} in ${namespace} to version ${previous_version}"

    # Stop current deployment
    kubectl rollout pause deployment/${deployment_name} -n "${namespace}"

    # Revert to previous version
    kubectl rollout undo deployment/${deployment_name} -n "${namespace}"

    # Wait for rollback completion
    kubectl rollout status deployment/${deployment_name} -n "${namespace}" --timeout=300s

    # Verify rollback success
    if verify_deployment "${namespace}" "${deployment_name}"; then
        echo "Rollback completed successfully"
        return 0
    else
        echo "Rollback failed"
        return 1
    fi
}

# Main execution
main() {
    local environment=$1
    local version=$2

    if [[ ! " ${ENVIRONMENTS[@]} " =~ " ${environment} " ]]; then
        echo "Invalid environment: ${environment}"
        echo "Valid environments are: ${ENVIRONMENTS[*]}"
        exit 1
    fi

    # Execute deployment
    if deploy_to_environment "${environment}" "${version}"; then
        echo "Deployment completed successfully"
        exit 0
    else
        echo "Deployment failed"
        exit 1
    fi
}

# Execute main function with provided arguments
main "$@"