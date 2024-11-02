# Human Tasks:
# 1. Review and configure AWS credentials for target environment
# 2. Verify VPC CIDR ranges don't conflict with existing networks
# 3. Ensure EKS version compatibility with your deployment requirements
# 4. Review RDS and ElastiCache instance types for cost optimization
# 5. Configure S3 bucket names according to your naming convention
# 6. Set up required SSL certificates for CloudFront distribution
# 7. Review and adjust resource capacity based on environment needs

# Requirement: Cloud Infrastructure - AWS provider configuration
# AWS Provider version ~> 4.0
terraform {
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

  backend "s3" {
    # Backend configuration should be provided through backend.tf or during init
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Requirement: Cloud Infrastructure - Common resource tagging
locals {
  common_tags = {
    Project     = "founditure"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Requirement: Cloud Infrastructure - Network infrastructure
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr     = var.vpc_cidr
  environment  = var.environment
  project_name = "founditure"
}

# Requirement: Container Orchestration - EKS cluster setup
module "eks" {
  source = "./modules/eks"

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  cluster_version     = var.eks_cluster_version
  node_instance_types = var.eks_node_instance_types

  # Pass through common tags
  environment  = var.environment
  project_name = "founditure"
}

# Requirement: AWS Services Configuration - RDS setup
module "rds" {
  source = "./modules/rds"

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  instance_class  = var.rds_instance_class
  engine_version  = var.rds_engine_version

  # Database configuration
  database_name = "founditure"
  multi_az     = var.environment == "prod" ? true : false

  # Pass through common tags
  environment  = var.environment
  project_name = "founditure"
}

# Requirement: AWS Services Configuration - ElastiCache setup
module "elasticache" {
  source = "./modules/elasticache"

  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  node_type        = var.elasticache_node_type
  num_cache_nodes  = var.elasticache_num_cache_nodes

  # Redis configuration
  engine_version = "6.x"
  port          = 6379

  # Pass through common tags
  environment  = var.environment
  project_name = "founditure"
}

# Requirement: AWS Services Configuration - S3 bucket setup
module "s3" {
  source = "./modules/s3"

  environment         = var.environment
  versioning_enabled = var.s3_versioning_enabled

  # S3 configuration
  bucket_prefix = "founditure"
  force_destroy = var.environment != "prod"

  # Pass through common tags
  project_name = "founditure"
}

# Configure Kubernetes provider after EKS cluster is created
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
}

# Configure Helm provider for Kubernetes package management
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name
      ]
    }
  }
}

# Output important infrastructure values
output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint for Kubernetes access"
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "RDS instance endpoint for database connections"
  value       = module.rds.instance_endpoint
}

output "redis_endpoint" {
  description = "Redis cluster endpoint for caching"
  value       = module.elasticache.cluster_endpoint
}

output "s3_bucket_name" {
  description = "S3 bucket name for object storage"
  value       = module.s3.bucket_name
}