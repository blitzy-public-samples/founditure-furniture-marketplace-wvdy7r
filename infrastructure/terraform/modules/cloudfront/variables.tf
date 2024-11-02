# Human Tasks:
# 1. Ensure AWS credentials are properly configured for CloudFront access
# 2. Verify that the S3 buckets referenced in media_bucket_id and logging_bucket_id exist and have proper permissions
# 3. Review price_class selection based on target market regions and budget constraints

# Core Terraform functionality for variable definitions
# Required version: ~> 1.0
terraform {
  required_version = "~> 1.0"
}

# Requirement: Content Delivery Network (3.1 High-Level Architecture Overview/External Services)
# Environment variable for resource naming and tagging
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod) for resource naming and tagging"
  
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod"
  }
}

# Requirement: Media Assets (1.2 Scope/Core System Components/Data Management)
# S3 bucket ID for media assets
variable "media_bucket_id" {
  type        = string
  description = "ID of the S3 bucket containing media assets to be served through CloudFront"
}

# Requirement: High Availability (3.1 High-Level Architecture Overview)
# S3 bucket ID for access logging
variable "logging_bucket_id" {
  type        = string
  description = "ID of the S3 bucket for CloudFront access logs"
}

# Requirement: Content Delivery Network
# Price class for edge location coverage
variable "price_class" {
  type        = string
  description = "CloudFront distribution price class determining edge location coverage"
  default     = "PriceClass_100"
  
  validation {
    condition     = can(regex("^PriceClass_(100|200|All)$", var.price_class))
    error_message = "Price class must be PriceClass_100, PriceClass_200, or PriceClass_All"
  }
}

# Requirement: Media Assets
# Allowed HTTP methods
variable "allowed_methods" {
  type        = list(string)
  description = "List of HTTP methods allowed by the CloudFront distribution"
  default     = ["GET", "HEAD", "OPTIONS"]
}

# Requirement: Media Assets
# Cached HTTP methods
variable "cached_methods" {
  type        = list(string)
  description = "List of HTTP methods that should be cached by CloudFront"
  default     = ["GET", "HEAD"]
}

# Requirement: Content Delivery Network
# Compression settings
variable "enable_compression" {
  type        = bool
  description = "Enable compression for supported content types"
  default     = true
}

# Requirement: High Availability
# Cache TTL settings
variable "min_ttl" {
  type        = number
  description = "Minimum time to live (in seconds) for cached objects"
  default     = 0
}

variable "default_ttl" {
  type        = number
  description = "Default time to live (in seconds) for cached objects"
  default     = 3600
}

variable "max_ttl" {
  type        = number
  description = "Maximum time to live (in seconds) for cached objects"
  default     = 86400
}

# Requirement: Content Delivery Network
# Resource tagging
variable "tags" {
  type        = map(string)
  description = "Tags to be applied to all resources created by this module"
  default     = {}
}