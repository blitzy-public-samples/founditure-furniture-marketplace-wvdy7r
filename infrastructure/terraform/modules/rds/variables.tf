# Human Tasks:
# 1. Ensure AWS provider is configured with appropriate permissions for RDS operations
# 2. Configure AWS KMS key for RDS encryption if not using default AWS managed key
# 3. Review and adjust default values based on environment-specific requirements
# 4. Set up AWS Secrets Manager or SSM Parameter Store for database credentials

# AWS Provider version: ~> 4.0

# Requirement: Primary Database Configuration (3.3.3 Data Storage/Primary Database)
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "instance_class" {
  description = "Instance class for the primary RDS instance"
  type        = string
  default     = "db.t3.large"
}

variable "replica_instance_class" {
  description = "Instance class for read replica instances"
  type        = string
  default     = "db.t3.medium"
}

# Requirement: Database High Availability (3.5 Scalability Architecture/Database Tier)
variable "allocated_storage" {
  description = "Allocated storage size in GB for the primary instance"
  type        = number
  default     = 100
  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 16384
    error_message = "Allocated storage must be between 20GB and 16TB"
  }
}

variable "max_allocated_storage" {
  description = "Maximum storage size in GB for autoscaling"
  type        = number
  default     = 500
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days"
  }
}

variable "read_replica_count" {
  description = "Number of read replicas to create"
  type        = number
  default     = 1
  validation {
    condition     = var.read_replica_count >= 0 && var.read_replica_count <= 5
    error_message = "Read replica count must be between 0 and 5"
  }
}

# Requirement: Database Security (7.2 Data Security/7.2.1 Encryption Standards)
variable "db_username" {
  description = "Master username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database"
  type        = list(string)
  default     = []
}

# VPC Configuration imported from VPC module
variable "vpc_id" {
  description = "ID of the VPC where RDS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS deployment"
  type        = list(string)
}