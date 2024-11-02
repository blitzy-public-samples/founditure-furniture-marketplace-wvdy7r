# Human Tasks:
# 1. Verify AWS regions align with latency and compliance requirements
# 2. Review instance types for production workload requirements
# 3. Confirm RDS configuration meets backup and retention policies
# 4. Validate ElastiCache cluster size for production traffic
# 5. Review monitoring retention periods for compliance requirements
# 6. Ensure logging configuration meets audit requirements

# Import common variables from root module
# Requirement: Production Environment Configuration - Common infrastructure variables
variable "project_name" {
  description = "Project name identifier"
  type        = string
  default     = "founditure"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "Project name must start with a letter and only contain lowercase alphanumeric characters and hyphens"
  }
}

variable "environment" {
  description = "Production environment identifier"
  type        = string
  default     = "prod"

  validation {
    condition     = var.environment == "prod"
    error_message = "Environment must be 'prod' for production configuration"
  }
}

# Requirement: Cloud Services Configuration - Multi-region deployment
variable "aws_regions" {
  description = "List of AWS regions for multi-region deployment"
  type        = list(string)
  default     = ["us-west-2", "us-east-1"]

  validation {
    condition     = length(var.aws_regions) >= 2
    error_message = "Production requires at least two regions for high availability"
  }
}

# Requirement: Production Environment Configuration - EKS cluster configuration
variable "eks_cluster_config" {
  description = "EKS cluster configuration for production"
  type = object({
    version = string
    node_groups = object({
      min_size       = number
      max_size       = number
      desired_size   = number
      instance_types = list(string)
    })
  })
  default = {
    version = "1.24"
    node_groups = {
      min_size       = 3
      max_size       = 20
      desired_size   = 5
      instance_types = ["t3.large", "t3.xlarge"]
    }
  }
}

# Requirement: Cloud Services Configuration - RDS configuration
variable "rds_config" {
  description = "RDS configuration for production"
  type = object({
    instance_class          = string
    engine_version         = string
    multi_az              = bool
    backup_retention_period = number
    deletion_protection    = bool
  })
  default = {
    instance_class          = "db.t3.large"
    engine_version         = "14.6"
    multi_az              = true
    backup_retention_period = 30
    deletion_protection    = true
  }
}

# Requirement: Cloud Services Configuration - ElastiCache configuration
variable "elasticache_config" {
  description = "ElastiCache Redis configuration for production"
  type = object({
    node_type                 = string
    num_cache_clusters        = number
    automatic_failover_enabled = bool
    multi_az_enabled          = bool
  })
  default = {
    node_type                 = "cache.t3.medium"
    num_cache_clusters        = 3
    automatic_failover_enabled = true
    multi_az_enabled          = true
  }
}

# Requirement: Production Environment Configuration - VPC configuration
variable "vpc_config" {
  description = "VPC configuration for production"
  type = object({
    cidr               = string
    public_subnets     = number
    private_subnets    = number
    enable_nat_gateway = bool
    single_nat_gateway = bool
  })
  default = {
    cidr               = "10.0.0.0/16"
    public_subnets     = 3
    private_subnets    = 3
    enable_nat_gateway = true
    single_nat_gateway = false
  }
}

# Requirement: Production Environment Configuration - Monitoring configuration
variable "monitoring_config" {
  description = "Monitoring stack configuration for production"
  type = object({
    prometheus_retention_period = string
    grafana_instance_type      = string
    enable_alerting            = bool
  })
  default = {
    prometheus_retention_period = "30d"
    grafana_instance_type      = "t3.medium"
    enable_alerting            = true
  }
}

# Requirement: Production Environment Configuration - Logging configuration
variable "logging_config" {
  description = "Logging stack configuration for production"
  type = object({
    elasticsearch_instance_type = string
    retention_period           = string
    enable_audit_logs          = bool
  })
  default = {
    elasticsearch_instance_type = "t3.medium.elasticsearch"
    retention_period           = "90d"
    enable_audit_logs          = true
  }
}

# Variable validation blocks for production environment
# Requirement: Security Requirements - Production environment validation
variable "vpc_cidr" {
  description = "CIDR block for the VPC network"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR block must be a valid IPv4 CIDR notation"
  }
}