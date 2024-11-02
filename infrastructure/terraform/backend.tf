# Human Tasks:
# 1. Create the S3 bucket 'founditure-terraform-state' with versioning enabled
# 2. Create the DynamoDB table 'founditure-terraform-locks' with 'LockID' as primary key
# 3. Configure AWS credentials with appropriate permissions for state management
# 4. Verify cross-region replication settings for the state bucket
# 5. Review bucket policies and access controls

# Requirement: State Management - Secure and distributed state management for multi-region infrastructure deployment
terraform {
  # Requirement: Infrastructure Security - Secure state storage with encryption and access controls
  required_version = ">= 1.0.0"
  
  backend "s3" {
    # Main state bucket configuration
    bucket = "founditure-terraform-state"
    key    = "terraform.tfstate"
    region = "us-west-2"
    
    # Requirement: Infrastructure Security - Server-side encryption for state files
    encrypt = true
    
    # Requirement: Team Collaboration - DynamoDB table for state locking
    dynamodb_table = "founditure-terraform-locks"
    
    # Requirement: State Management - Support for workspace-based environment separation
    workspace_key_prefix = "${var.environment}"
  }

  # Requirement: Infrastructure Security - AWS provider version control
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Outputs for state management resources
# Requirement: State Management - Resource tracking
output "backend_bucket" {
  description = "S3 bucket name storing terraform state"
  value       = "founditure-terraform-state"
}

output "lock_table" {
  description = "DynamoDB table name for state locking"
  value       = "founditure-terraform-locks"
}