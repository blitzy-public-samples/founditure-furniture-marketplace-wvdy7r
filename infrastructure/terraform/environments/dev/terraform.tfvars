# Human Tasks:
# 1. Verify VPC CIDR range doesn't conflict with other networks in development environment
# 2. Review EKS node count and instance types for development cost optimization
# 3. Confirm Redis node count is sufficient for development workload
# 4. Ensure monitoring and logging settings align with development requirements

# Requirement: Development Environment Configuration - Fixed node counts and single region deployment
project_name = "founditure"
environment  = "dev"
aws_region   = "us-west-2"

# Requirement: Development Environment Configuration - Single region deployment with fixed network configuration
vpc_cidr = "10.0.0.0/16"

# Requirement: Container Orchestration - Development environment Kubernetes cluster configuration with minimal resources
eks_cluster_version = "1.24"
eks_node_count     = 2
eks_instance_types = ["t3.medium"]

# Requirement: AWS Services Configuration - Development-specific AWS services configuration including RDS
rds_instance_class  = "db.t3.medium"
rds_engine_version  = "14.6"

# Requirement: AWS Services Configuration - Development-specific AWS services configuration including ElastiCache
elasticache_node_type = "cache.t3.medium"
elasticache_nodes     = 1

# Requirement: AWS Services Configuration - Development-specific AWS services configuration including S3
s3_versioning_enabled = true

# Requirement: Development Environment Configuration - Development environment monitoring and logging configuration
enable_monitoring = true
enable_logging    = true