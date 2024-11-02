# Human Tasks:
# 1. Ensure AWS credentials are properly configured with appropriate permissions
# 2. Verify the staging environment's AWS region has sufficient capacity
# 3. Review and adjust resource sizing based on actual workload requirements
# 4. Configure any required AWS service quotas/limits
# 5. Set up required AWS KMS keys for encryption

# Requirement: Infrastructure as Code (5.5.1 DevOps Tools)
# AWS Provider configuration with version constraint
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    # Configure your Terraform state backend
    bucket = "founditure-terraform-state"
    key    = "staging/terraform.tfstate"
    region = "us-west-2"
  }
}

# Configure AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Environment = "staging"
      Project     = "founditure"
      ManagedBy  = "terraform"
    }
  }
}

# Requirement: Staging Environment Infrastructure (8.1 Deployment Environment/Environment Matrix)
# Local variables for staging environment configuration
locals {
  environment   = "staging"
  project_name  = "founditure"
  vpc_cidr      = "10.1.0.0/16"
  eks_node_groups = {
    general = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size      = 2
      max_size      = 4
    }
  }
}

# Requirement: Cloud Infrastructure (8.2 Cloud Services)
# VPC Module for network infrastructure
module "vpc" {
  source = "../modules/vpc"

  environment         = local.environment
  project_name        = local.project_name
  vpc_cidr           = local.vpc_cidr
  public_subnet_count = 2
  private_subnet_count = 2
  enable_nat_gateway = true
  single_nat_gateway = true # Cost optimization for staging
}

# Requirement: Container Orchestration (8.2 Cloud Services/Core Services Configuration)
# EKS Module for Kubernetes cluster
module "eks" {
  source = "../modules/eks"

  environment         = local.environment
  cluster_name        = "${local.project_name}-${local.environment}"
  kubernetes_version  = "1.24"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  node_groups        = local.eks_node_groups

  # Staging-specific configurations
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# Requirement: Primary Database (3.3.3 Data Storage)
# RDS Module for PostgreSQL database
module "rds" {
  source = "../modules/rds"

  environment          = local.environment
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  # Staging database configuration
  instance_class         = "db.t3.medium"
  allocated_storage     = 50
  max_allocated_storage = 100
  backup_retention_period = 7
  read_replica_count    = 1 # Single read replica for staging

  # Security configuration
  allowed_cidr_blocks = [local.vpc_cidr]
  db_username         = "founditure_app"
  db_password         = var.db_password # Sensitive value from variables
}

# Outputs for reference and integration
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "Endpoint of the primary RDS instance"
  value       = module.rds.primary_endpoint
}

# Additional staging-specific resources can be added here
# Examples:
# - CloudWatch Alarms for monitoring
# - S3 buckets for storage
# - ElastiCache for caching
# - Route53 records for DNS