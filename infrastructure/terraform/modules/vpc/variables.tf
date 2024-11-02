# Human Tasks:
# 1. Review and adjust CIDR ranges for each environment
# 2. Verify subnet counts align with availability zone requirements
# 3. Confirm NAT Gateway configuration matches cost requirements
# 4. Ensure VPC tagging aligns with organization standards

# Requirement: Network Infrastructure - Define variables for configuring secure VPC infrastructure
variable "vpc_cidr" {
  description = "CIDR block for the VPC network"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR block must be a valid IPv4 CIDR notation"
  }
}

# Requirement: Multi-AZ Deployment - Variables for configuring network infrastructure across multiple availability zones
variable "public_subnet_count" {
  description = "Number of public subnets to create across availability zones"
  type        = number
  default     = 3

  validation {
    condition     = var.public_subnet_count > 0 && var.public_subnet_count <= 3
    error_message = "Public subnet count must be between 1 and 3"
  }
}

variable "private_subnet_count" {
  description = "Number of private subnets to create across availability zones"
  type        = number
  default     = 3

  validation {
    condition     = var.private_subnet_count > 0 && var.private_subnet_count <= 3
    error_message = "Private subnet count must be between 1 and 3"
  }
}

# Requirement: Security Architecture - Network security configuration variables for subnet isolation
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost savings for non-prod)"
  type        = bool
  default     = false
}

# Import common variables from root module
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

# Additional resource tagging
variable "tags" {
  description = "Additional tags for VPC resources"
  type        = map(string)
  default     = {}
}