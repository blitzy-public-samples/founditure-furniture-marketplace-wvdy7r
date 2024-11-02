# Human Tasks:
# 1. Ensure AWS provider is configured with appropriate permissions for ElastiCache management
# 2. Verify VPC and subnet configurations are properly set up for ElastiCache deployment
# 3. Review security group rules to allow required Redis port access
# 4. Confirm parameter group family compatibility with desired Redis version

# AWS Provider version ~> 4.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Requirement: Cache Layer Configuration (8.2 Cloud Services/Core Services Configuration)
variable "environment" {
  description = "Deployment environment identifier (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "node_type" {
  description = "Instance type for Redis nodes"
  type        = string
  default     = "cache.t3.medium"

  validation {
    condition     = can(regex("^cache\\.[a-z0-9]+\\.[a-z0-9]+$", var.node_type))
    error_message = "Node type must be a valid ElastiCache instance type"
  }
}

variable "num_cache_nodes" {
  description = "Number of cache nodes in the Redis cluster"
  type        = number
  default     = 3

  validation {
    condition     = var.num_cache_nodes >= 1 && var.num_cache_nodes <= 6
    error_message = "Number of cache nodes must be between 1 and 6"
  }
}

variable "vpc_id" {
  description = "ID of the VPC where Redis cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for Redis cluster deployment"
  type        = list(string)
}

variable "parameter_group_family" {
  description = "Redis parameter group family"
  type        = string
  default     = "redis6.x"
}

variable "port" {
  description = "Port number for Redis cluster"
  type        = number
  default     = 6379
}

# Requirement: High Availability Setup (3.5 Scalability Architecture/Cache Layer)
variable "at_rest_encryption" {
  description = "Enable encryption at rest for Redis cluster"
  type        = bool
  default     = true
}

variable "transit_encryption" {
  description = "Enable in-transit encryption for Redis cluster"
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Enable Multi-AZ deployment for Redis cluster"
  type        = bool
  default     = true
}

variable "automatic_failover" {
  description = "Enable automatic failover for Redis cluster"
  type        = bool
  default     = true
}