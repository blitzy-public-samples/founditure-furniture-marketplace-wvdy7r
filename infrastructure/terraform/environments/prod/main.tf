# Human Tasks:
# 1. Verify AWS credentials and permissions for production deployment
# 2. Confirm multi-region deployment strategy and replication settings
# 3. Review backup retention periods and disaster recovery configurations
# 4. Validate security group rules and network ACLs
# 5. Ensure monitoring and alerting thresholds are properly configured
# 6. Verify SSL/TLS certificates are properly provisioned

# Requirement: Production Environment Configuration (8.1 Deployment Environment)
terraform {
  required_version = ">= 1.0.0"
  
  # Requirement: Infrastructure/8.1 Deployment Environment - Production state management
  backend "s3" {
    bucket         = "founditure-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "founditure-terraform-locks-prod"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# Requirement: Multi-region deployment (8.1 Deployment Environment)
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "prod"
      Project     = "founditure"
      ManagedBy   = "terraform"
    }
  }
}

# Requirement: High Availability Infrastructure (8.2 Cloud Services/Core Services Configuration)
module "vpc" {
  source = "../../modules/vpc"

  environment        = "prod"
  vpc_cidr          = var.vpc_cidr
  enable_nat_gateway = true
  single_nat_gateway = false
  enable_vpn_gateway = true

  tags = local.common_tags
}

# Requirement: Production Environment - Auto-scaling (2-20 nodes)
module "eks" {
  source = "../../modules/eks"

  cluster_name    = "founditure-prod"
  cluster_version = var.eks_cluster_config.version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  
  min_nodes       = var.eks_cluster_config.node_groups.min_size
  max_nodes       = var.eks_cluster_config.node_groups.max_size
  instance_types  = var.eks_cluster_config.node_groups.instance_types

  tags = local.common_tags
}

# Requirement: High Availability Infrastructure - Multi-AZ RDS
module "rds" {
  source = "../../modules/rds"

  identifier             = "founditure-prod"
  instance_class        = var.rds_config.instance_class
  engine_version        = var.rds_config.engine_version
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  multi_az             = var.rds_config.multi_az
  backup_retention_period = var.rds_config.backup_retention_period
  deletion_protection   = var.rds_config.deletion_protection

  tags = local.common_tags
}

# Requirement: High Availability Infrastructure - Multi-AZ ElastiCache
module "elasticache" {
  source = "../../modules/elasticache"

  cluster_id                  = "founditure-prod"
  node_type                  = var.elasticache_config.node_type
  num_cache_clusters         = var.elasticache_config.num_cache_clusters
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  automatic_failover_enabled = var.elasticache_config.automatic_failover_enabled
  multi_az_enabled          = var.elasticache_config.multi_az_enabled

  tags = local.common_tags
}

# Requirement: Security Architecture - Secure storage configuration
module "s3" {
  source = "../../modules/s3"

  bucket_name         = "founditure-storage-prod"
  versioning_enabled = true
  replication_enabled = var.enable_disaster_recovery
  
  lifecycle_rules = {
    enabled         = true
    transition_days = 90
    storage_class   = "STANDARD_IA"
  }

  tags = local.common_tags
}

# Requirement: Production Environment - Common resource tags
locals {
  common_tags = {
    Environment = "prod"
    Project     = "founditure"
    ManagedBy   = "terraform"
    CostCenter  = "production"
  }
}

# Requirement: Infrastructure monitoring and management
output "vpc_id" {
  description = "ID of the production VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "Endpoint for production EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "Endpoint for production RDS instance"
  value       = module.rds.instance_endpoint
}

output "redis_endpoint" {
  description = "Endpoint for production Redis cluster"
  value       = module.elasticache.cluster_endpoint
}

output "s3_bucket_name" {
  description = "Name of the production S3 bucket"
  value       = module.s3.bucket_name
}