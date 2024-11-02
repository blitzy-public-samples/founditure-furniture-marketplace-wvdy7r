# Human Tasks:
# 1. Ensure AWS credentials are properly configured in your environment
# 2. Verify EKS cluster exists before applying Kubernetes provider configuration
# 3. Review and adjust provider version constraints based on your infrastructure requirements
# 4. Configure additional AWS provider aliases if needed for multi-region deployment

# Required provider versions and configurations
# Requirement: Cloud Provider Configuration - Primary cloud provider AWS configuration
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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# AWS provider configuration
# Requirement: Multi-Region Deployment - Support for multi-region infrastructure deployment
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project   = "founditure"
      ManagedBy = "terraform"
    }
  }
}

# Kubernetes provider configuration
# Requirement: Container Orchestration - Kubernetes and Helm provider configuration
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Helm provider configuration for Kubernetes package management
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Data sources for EKS cluster configuration
data "aws_eks_cluster" "cluster" {
  name       = "founditure-cluster"
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = "founditure-cluster"
}