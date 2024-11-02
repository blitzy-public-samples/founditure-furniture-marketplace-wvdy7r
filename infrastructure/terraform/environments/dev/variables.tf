# Human Tasks:
# 1. Verify VPC CIDR range doesn't conflict with other networks in development environment
# 2. Review EKS node count and instance types for development cost optimization
# 3. Confirm Redis node count is sufficient for development workload
# 4. Ensure monitoring and logging settings align with development requirements

# Import root variables
# Requirement: Development Environment Configuration - Fixed node counts and single region deployment
variable "environment" {
  description = "Development environment identifier"
  type        = string
  default     = "dev"

  validation {
    condition     = var.environment == "dev"
    error_message = "This is a development environment configuration, environment must be 'dev'"
  }
}

# Network configuration
# Requirement: Development Environment Configuration - Single region deployment
variable "vpc_cidr" {
  description = "CIDR block for development VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR block must be a valid IPv4 CIDR notation"
  }
}

# EKS configuration
# Requirement: Container Orchestration - Kubernetes cluster configuration for development environment
variable "eks_node_count" {
  description = "Number of nodes in development EKS cluster"
  type        = number
  default     = 2

  validation {
    condition     = var.eks_node_count >= 1 && var.eks_node_count <= 3
    error_message = "Development EKS node count must be between 1 and 3"
  }
}

variable "eks_instance_types" {
  description = "Instance types for development EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

# RDS configuration
# Requirement: AWS Services Configuration - Development-specific AWS services configuration
variable "rds_instance_class" {
  description = "Instance class for development RDS instance"
  type        = string
  default     = "db.t3.medium"
}

# ElastiCache configuration
variable "elasticache_instance_type" {
  description = "Instance type for development Redis cluster"
  type        = string
  default     = "cache.t3.medium"
}

variable "elasticache_nodes" {
  description = "Number of nodes in development Redis cluster"
  type        = number
  default     = 1

  validation {
    condition     = var.elasticache_nodes == 1
    error_message = "Development Redis cluster should have exactly 1 node"
  }
}

# Monitoring and logging configuration
# Requirement: Development Environment Configuration - Development-specific infrastructure parameters
variable "enable_monitoring" {
  description = "Enable monitoring stack in development"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging stack in development"
  type        = bool
  default     = true
}