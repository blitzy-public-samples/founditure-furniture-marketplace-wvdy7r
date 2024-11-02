#!/bin/bash

# Human Tasks:
# 1. Configure AWS CLI with appropriate credentials and region
# 2. Set up encryption key in AWS KMS for backup encryption
# 3. Create S3 bucket for backup storage with appropriate lifecycle policies
# 4. Configure database credentials in environment variables or AWS Secrets Manager
# 5. Set up appropriate IAM roles and policies for S3 and KMS access
# 6. Ensure MongoDB authentication is configured if using MongoDB backups

# Required tool versions:
# - aws-cli v2.x
# - postgresql-client v14.x
# - mongodb-database-tools v100.x

# Requirement: Data Storage Backup (3.3.3 Data Storage/Primary Database)
# Requirement: Document Store Backup (3.3.3 Data Storage/Document Store)
# Requirement: Data Security (7.2 Data Security/7.2.1 Encryption Standards)

# Set strict error handling
set -euo pipefail

# Default values
DEFAULT_RETENTION_DAYS=30
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/backup.log"

# Logging function
log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" | tee -a "$LOG_FILE"
}

# Check prerequisites for backup operations
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check required tools
    command -v aws >/dev/null 2>&1 || { log "Error: aws-cli is required but not installed"; return 1; }
    command -v pg_dump >/dev/null 2>&1 || { log "Error: pg_dump is required but not installed"; return 1; }
    command -v mongodump >/dev/null 2>&1 || { log "Error: mongodump is required but not installed"; return 1; }
    
    # Verify environment variables
    [[ -z "${BACKUP_BUCKET:-}" ]] && { log "Error: BACKUP_BUCKET environment variable is not set"; return 1; }
    [[ -z "${ENCRYPTION_KEY:-}" ]] && { log "Error: ENCRYPTION_KEY environment variable is not set"; return 1; }
    
    # Test AWS credentials
    aws sts get-caller-identity >/dev/null 2>&1 || { log "Error: Invalid AWS credentials"; return 1; }
    
    # Test S3 bucket access
    aws s3 ls "s3://${BACKUP_BUCKET}" >/dev/null 2>&1 || { log "Error: Cannot access S3 bucket ${BACKUP_BUCKET}"; return 1; }
    
    return 0
}

# Create encrypted backup of PostgreSQL database
backup_postgresql() {
    local environment="$1"
    local retention_days="${2:-$DEFAULT_RETENTION_DAYS}"
    local backup_file="postgresql_${environment}_${TIMESTAMP}.sql.gz"
    local encrypted_file="${backup_file}.enc"
    
    log "Starting PostgreSQL backup for environment: ${environment}"
    
    # Get database connection parameters from environment or RDS outputs
    local db_host="${POSTGRES_HOST:-$(aws rds describe-db-instances --query 'DBInstances[0].Endpoint.Address' --output text)}"
    local db_name="${POSTGRES_DB:-$(aws rds describe-db-instances --query 'DBInstances[0].DBName' --output text)}"
    
    # Create backup with compression
    PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump \
        -h "$db_host" \
        -U "${POSTGRES_USER}" \
        -d "$db_name" \
        -F c \
        -Z 9 \
        -f "$backup_file" || { log "Error: PostgreSQL backup failed"; return 1; }
    
    # Encrypt backup using AWS KMS
    aws kms encrypt \
        --key-id "${ENCRYPTION_KEY}" \
        --plaintext fileb://"${backup_file}" \
        --output text \
        --query CiphertextBlob \
        --output text > "${encrypted_file}"
    
    # Upload to S3
    aws s3 cp "${encrypted_file}" "s3://${BACKUP_BUCKET}/${environment}/postgresql/${encrypted_file}"
    
    # Cleanup local files
    rm -f "${backup_file}" "${encrypted_file}"
    
    # Remove old backups
    cleanup_old_backups "$environment" "$retention_days" "postgresql"
    
    log "PostgreSQL backup completed successfully"
    return 0
}

# Create encrypted backup of MongoDB database
backup_mongodb() {
    local environment="$1"
    local retention_days="${2:-$DEFAULT_RETENTION_DAYS}"
    local backup_dir="mongodb_${environment}_${TIMESTAMP}"
    local backup_archive="${backup_dir}.tar.gz"
    local encrypted_file="${backup_archive}.enc"
    
    log "Starting MongoDB backup for environment: ${environment}"
    
    # Create backup using mongodump
    mongodump \
        --uri="${MONGO_URI}" \
        --gzip \
        --archive="$backup_archive" || { log "Error: MongoDB backup failed"; return 1; }
    
    # Encrypt backup using AWS KMS
    aws kms encrypt \
        --key-id "${ENCRYPTION_KEY}" \
        --plaintext fileb://"${backup_archive}" \
        --output text \
        --query CiphertextBlob \
        --output text > "${encrypted_file}"
    
    # Upload to S3
    aws s3 cp "${encrypted_file}" "s3://${BACKUP_BUCKET}/${environment}/mongodb/${encrypted_file}"
    
    # Cleanup local files
    rm -f "${backup_archive}" "${encrypted_file}"
    
    # Remove old backups
    cleanup_old_backups "$environment" "$retention_days" "mongodb"
    
    log "MongoDB backup completed successfully"
    return 0
}

# Clean up old backups based on retention policy
cleanup_old_backups() {
    local environment="$1"
    local retention_days="$2"
    local db_type="$3"
    local cutoff_date
    
    log "Cleaning up old ${db_type} backups for environment: ${environment}"
    
    # Calculate cutoff date
    cutoff_date=$(date -d "${retention_days} days ago" +%Y-%m-%d)
    
    # List and delete old backups
    aws s3 ls "s3://${BACKUP_BUCKET}/${environment}/${db_type}/" | while read -r line; do
        local backup_date=$(echo "$line" | awk '{print $1}')
        local backup_file=$(echo "$line" | awk '{print $4}')
        
        if [[ "$backup_date" < "$cutoff_date" ]]; then
            log "Deleting old backup: ${backup_file}"
            aws s3 rm "s3://${BACKUP_BUCKET}/${environment}/${db_type}/${backup_file}"
        fi
    done
    
    log "Cleanup completed"
    return 0
}

# Main execution
main() {
    local environment="${1:-production}"
    local retention_days="${2:-$DEFAULT_RETENTION_DAYS}"
    
    log "Starting database backup process for environment: ${environment}"
    
    # Check prerequisites
    check_prerequisites || { log "Prerequisites check failed"; exit 1; }
    
    # Perform PostgreSQL backup
    backup_postgresql "$environment" "$retention_days" || { log "PostgreSQL backup failed"; exit 1; }
    
    # Perform MongoDB backup
    backup_mongodb "$environment" "$retention_days" || { log "MongoDB backup failed"; exit 1; }
    
    log "All database backups completed successfully"
}

# Execute main function with command line arguments
main "$@"