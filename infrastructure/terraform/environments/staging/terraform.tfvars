# Human Tasks:
# 1. Verify AWS credentials are properly configured for staging account
# 2. Confirm VPC CIDR range doesn't conflict with other networks
# 3. Review EKS node group sizing for staging workload requirements
# 4. Validate backup retention period meets staging data requirements
# 5. Ensure monitoring and logging configurations align with staging SLAs

# Core project configuration
# Requirement: Staging Environment Configuration - Fixed deployment configuration for staging environment
project_name = "founditure"
environment  = "staging"
aws_region   = "us-west-2"

# Network configuration
# Requirement: Cloud Services Configuration - AWS services configuration including VPC for staging environment
vpc_cidr = "10.1.0.0/16"

# Kubernetes configuration
# Requirement: Staging Environment Configuration - Fixed (2 nodes) deployment configuration for staging environment
eks_cluster_version = "1.24"
eks_node_groups = {
  staging-workload = {
    instance_types = ["t3.medium"]
    desired_size   = 2
    min_size      = 2
    max_size      = 4
    disk_size     = 50
  }
}

# Database configuration
# Requirement: Cloud Services Configuration - RDS configuration for staging environment
rds_instance_class  = "db.t3.medium"
rds_engine_version  = "14.6"

# Cache configuration
# Requirement: Cloud Services Configuration - ElastiCache configuration for staging environment
elasticache_node_type       = "cache.t3.small"
elasticache_num_cache_nodes = 2

# Storage configuration
# Requirement: Cloud Services Configuration - S3 configuration for staging environment
s3_versioning_enabled = true

# Monitoring and logging configuration
# Requirement: Security Controls - Environment-specific security configurations for staging deployment
enable_monitoring = true
enable_logging   = true

# Backup configuration
# Requirement: Security Controls - Environment-specific security configurations for staging deployment
backup_retention_period = 7