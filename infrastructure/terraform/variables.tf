# Human Tasks:
# 1. Review and adjust default values for each environment (dev/staging/prod)
# 2. Ensure AWS credentials are properly configured for the target account
# 3. Verify VPC CIDR ranges don't conflict with existing networks
# 4. Confirm EKS version compatibility with your deployment requirements
# 5. Review instance types for cost optimization per environment

# Core project configuration
# Requirement: Cloud Infrastructure - Multi-region deployment environment configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "founditure"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "Project name must start with a letter and only contain lowercase alphanumeric characters and hyphens"
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-west-2"
}

# Network configuration
# Requirement: Cloud Infrastructure - Proper environment segregation
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR block must be a valid IPv4 CIDR notation"
  }
}

# Kubernetes configuration
# Requirement: Container Orchestration - Kubernetes cluster configuration
variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.24"

  validation {
    condition     = can(regex("^\\d+\\.\\d+$", var.eks_cluster_version))
    error_message = "EKS version must be in format: 1.24, 1.25, etc."
  }
}

variable "eks_node_instance_types" {
  description = "Instance types for EKS node groups"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

# Database configuration
# Requirement: AWS Services Configuration - RDS configuration
variable "rds_instance_class" {
  description = "Instance class for RDS PostgreSQL"
  type        = string
  default     = "db.t3.large"
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "14.6"
}

# Cache configuration
# Requirement: AWS Services Configuration - ElastiCache configuration
variable "elasticache_node_type" {
  description = "Node type for Redis cluster"
  type        = string
  default     = "cache.t3.medium"
}

variable "elasticache_num_cache_nodes" {
  description = "Number of cache nodes in Redis cluster"
  type        = number
  default     = 3

  validation {
    condition     = var.elasticache_num_cache_nodes >= 1 && var.elasticache_num_cache_nodes <= 6
    error_message = "Number of cache nodes must be between 1 and 6"
  }
}

# Storage configuration
# Requirement: AWS Services Configuration - S3 configuration
variable "s3_versioning_enabled" {
  description = "Enable versioning for S3 buckets"
  type        = bool
  default     = true
}

# Monitoring and logging configuration
# Requirement: Cloud Infrastructure - Infrastructure monitoring
variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus/Grafana)"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging stack (ELK)"
  type        = bool
  default     = true
}