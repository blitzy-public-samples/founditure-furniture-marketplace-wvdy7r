# Human Tasks:
# 1. Review and configure AWS credentials for development environment
# 2. Verify VPC CIDR range doesn't conflict with existing networks
# 3. Ensure EKS cluster version is compatible with your deployment requirements
# 4. Review RDS and ElastiCache instance types for development environment
# 5. Configure S3 bucket naming convention for development environment

# Requirement: Development Environment Infrastructure - Development environment configuration
# AWS Provider version ~> 4.0
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "founditure"
      ManagedBy   = "terraform"
    }
  }
}

# Requirement: Container Orchestration - Kubernetes provider configuration for development environment
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token                  = module.eks.cluster_token
}

# Requirement: Development Environment Infrastructure - VPC configuration
module "vpc" {
  source = "../../modules/vpc"

  environment        = "dev"
  vpc_cidr          = var.vpc_cidr
  enable_vpn_gateway = false
}

# Requirement: Container Orchestration - EKS cluster for development
module "eks" {
  source = "../../modules/eks"

  environment      = "dev"
  cluster_name     = "founditure-dev"
  cluster_version  = var.eks_cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  node_count      = var.eks_node_count
  instance_types  = var.eks_instance_types
}

# Requirement: Cloud Services Configuration - Development RDS instance
module "rds" {
  source = "../../modules/rds"

  environment             = "dev"
  instance_class         = var.rds_instance_class
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  multi_az              = false
  backup_retention_period = 7
}

# Requirement: Cloud Services Configuration - Development Redis cluster
module "elasticache" {
  source = "../../modules/elasticache"

  environment      = "dev"
  node_type       = var.elasticache_instance_type
  num_cache_nodes = var.elasticache_nodes
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
}

# Requirement: Cloud Services Configuration - Development S3 bucket
module "s3" {
  source = "../../modules/s3"

  environment          = "dev"
  versioning_enabled  = true
  lifecycle_rules_enabled = true
}

# Outputs for development environment resources
output "vpc_id" {
  description = "ID of the development VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the development EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "Endpoint of the development RDS instance"
  value       = module.rds.instance_endpoint
}

output "redis_endpoint" {
  description = "Endpoint of the development Redis cluster"
  value       = module.elasticache.cluster_endpoint
}

output "s3_bucket_name" {
  description = "Name of the development S3 bucket"
  value       = module.s3.bucket_name
}