# Human Tasks:
# 1. Review and adjust lifecycle rules for each environment
# 2. Verify bucket names comply with your organization's naming conventions
# 3. Ensure encryption settings meet security requirements
# 4. Confirm replication settings align with disaster recovery needs
# 5. Review tags for compliance with organization's tagging strategy

# Import common variables from root
# Requirement: Object Storage Configuration - Core infrastructure variables
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
}

# Media storage bucket configuration
# Requirement: Object Storage Configuration - Media assets storage
variable "media_bucket_name" {
  description = "Name for the media storage bucket"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.media_bucket_name))
    error_message = "Bucket name must contain only lowercase letters, numbers, dots, and hyphens"
  }
}

# Backup storage configuration
# Requirement: Object Storage Configuration - Backup storage
variable "backup_bucket_name" {
  description = "Name for the backup storage bucket"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.backup_bucket_name))
    error_message = "Bucket name must contain only lowercase letters, numbers, dots, and hyphens"
  }
}

# Access logging configuration
# Requirement: Object Storage Configuration - Access logging
variable "logging_bucket_name" {
  description = "Name for the access logging bucket"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.logging_bucket_name))
    error_message = "Bucket name must contain only lowercase letters, numbers, dots, and hyphens"
  }
}

# Versioning configuration
# Requirement: Data Security Parameters - Data protection
variable "enable_versioning" {
  description = "Enable versioning for media and backup buckets"
  type        = bool
  default     = true
}

# Encryption configuration
# Requirement: Data Security Parameters - Encryption standards
variable "enable_encryption" {
  description = "Enable server-side encryption for all buckets"
  type        = bool
  default     = true
}

# Replication configuration
# Requirement: Data Security Parameters - Disaster recovery
variable "enable_replication" {
  description = "Enable cross-region replication for disaster recovery"
  type        = bool
  default     = true
}

# Lifecycle rules configuration
# Requirement: Storage Lifecycle Management - Data lifecycle policies
variable "lifecycle_rules" {
  description = "Lifecycle rules for media and backup storage"
  type        = map(object({
    transition_days = number
    expiration_days = number
  }))

  validation {
    condition     = alltrue([for rule in var.lifecycle_rules : rule.transition_days > 0 && rule.expiration_days > rule.transition_days])
    error_message = "Transition days must be positive and less than expiration days"
  }
}

# Resource tagging
# Requirement: Object Storage Configuration - Resource organization
variable "tags" {
  description = "Additional tags to apply to all S3 resources"
  type        = map(string)
  default     = {}
}