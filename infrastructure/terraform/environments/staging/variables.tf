# Human Tasks:
# 1. Verify AWS region matches your staging environment requirements
# 2. Review EKS node group sizing for staging workload requirements
# 3. Confirm RDS and ElastiCache instance types are cost-optimized for staging
# 4. Validate backup retention periods align with staging data requirements
# 5. Ensure monitoring and logging configurations meet staging SLAs

# Requirement: Staging Environment Configuration - Fixed deployment configuration for staging environment
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws" # version ~> 4.0
      version = "~> 4.0"
    }
  }
}

# Environment identifier
# Requirement: Staging Environment Configuration - Environment-specific configuration
variable "environment" {
  description = "Deployment environment identifier"
  type        = string
  default     = "staging"

  validation {
    condition     = var.environment == "staging"
    error_message = "This is a staging environment configuration file"
  }
}

# Region configuration
# Requirement: Cloud Infrastructure - AWS services configuration for staging environment
variable "aws_region" {
  description = "AWS region for staging deployment"
  type        = string
  default     = "us-west-2"
}

# Network configuration
# Requirement: Cloud Infrastructure - VPC configuration for staging
variable "vpc_cidr" {
  description = "CIDR block for staging VPC"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR block must be a valid IPv4 CIDR notation"
  }
}

# EKS configuration
# Requirement: Staging Environment Configuration - Fixed node deployment configuration
variable "eks_node_groups" {
  description = "EKS node group configuration for staging"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size      = number
    max_size      = number
    disk_size     = number
  }))
  default = {
    staging-workload = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size      = 2
      max_size      = 4
      disk_size     = 50
    }
  }
}

# RDS configuration
# Requirement: Cloud Infrastructure - RDS configuration for staging
variable "rds_instance_class" {
  description = "RDS instance class for staging"
  type        = string
  default     = "db.t3.medium"
}

# ElastiCache configuration
# Requirement: Cloud Infrastructure - ElastiCache configuration for staging
variable "elasticache_node_type" {
  description = "ElastiCache node type for staging"
  type        = string
  default     = "cache.t3.small"
}

variable "elasticache_num_cache_nodes" {
  description = "Number of cache nodes for staging"
  type        = number
  default     = 2

  validation {
    condition     = var.elasticache_num_cache_nodes >= 1 && var.elasticache_num_cache_nodes <= 3
    error_message = "Number of cache nodes must be between 1 and 3 for staging environment"
  }
}

# Monitoring and logging configuration
# Requirement: Security Controls - Environment-specific security configurations
variable "enable_monitoring" {
  description = "Enable monitoring stack in staging"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging stack in staging"
  type        = bool
  default     = true
}

# Backup configuration
# Requirement: Security Controls - Data protection configuration for staging
variable "backup_retention_period" {
  description = "Backup retention period in days for staging"
  type        = number
  default     = 7
}