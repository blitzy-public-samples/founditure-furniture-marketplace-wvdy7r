# Human Tasks:
# 1. Verify AWS regions align with latency and compliance requirements
# 2. Review instance types for production workload requirements
# 3. Confirm RDS configuration meets backup and retention policies
# 4. Validate ElastiCache cluster size for production traffic
# 5. Review monitoring retention periods for compliance requirements
# 6. Ensure logging configuration meets audit requirements

# Requirement: Production Environment Configuration - Environment identifier
environment = "prod"

# Requirement: High Availability Infrastructure - Multi-region deployment
aws_regions = [
  "us-west-2",  # Primary region
  "us-east-1"   # Secondary region for disaster recovery
]

# Requirement: Production Environment Configuration - VPC settings
vpc_config = {
  cidr               = "10.0.0.0/16"
  public_subnets     = 3  # One per AZ for high availability
  private_subnets    = 3  # One per AZ for high availability
  enable_nat_gateway = true
  single_nat_gateway = false  # Multiple NAT gateways for HA
}

# Requirement: High Availability Infrastructure - EKS cluster configuration
eks_cluster_config = {
  version = "1.24"
  node_groups = {
    min_size       = 3      # Minimum nodes for HA
    max_size       = 20     # Maximum nodes for peak load
    desired_size   = 5      # Initial cluster size
    instance_types = [
      "t3.large",   # General purpose workloads
      "t3.xlarge"   # CPU-intensive workloads
    ]
  }
}

# Requirement: High Availability Infrastructure - RDS configuration
rds_config = {
  instance_class          = "db.t3.large"
  engine_version         = "14.6"
  multi_az              = true              # Enable multi-AZ for HA
  backup_retention_period = 30               # 30 days retention for backups
  deletion_protection    = true             # Prevent accidental deletion
}

# Requirement: High Availability Infrastructure - ElastiCache configuration
elasticache_config = {
  node_type                 = "cache.t3.medium"
  num_cache_clusters        = 3                # Three nodes for HA
  automatic_failover_enabled = true            # Enable automatic failover
  multi_az_enabled          = true            # Enable multi-AZ deployment
}

# Requirement: Security Architecture - Monitoring configuration
monitoring_config = {
  prometheus_retention_period = "30d"          # 30 days metrics retention
  grafana_instance_type      = "t3.medium"
  enable_alerting            = true           # Enable production alerts
}

# Requirement: Security Architecture - Logging configuration
logging_config = {
  elasticsearch_instance_type = "t3.medium.elasticsearch"
  retention_period           = "90d"           # 90 days log retention
  enable_audit_logs          = true           # Enable security audit logs
}