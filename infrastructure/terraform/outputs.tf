# Human Tasks:
# 1. Ensure AWS credentials are properly configured with necessary permissions
# 2. Verify that all referenced modules are properly initialized
# 3. Confirm that sensitive values are properly handled in your CI/CD pipeline
# 4. Review and update any hardcoded values in referenced modules if needed

# Requirement: Cloud Infrastructure (8. Infrastructure/8.1 Deployment Environment)
# Export VPC infrastructure details for multi-region deployment
output "vpc" {
  description = "VPC infrastructure details"
  value = {
    vpc_id             = module.vpc.vpc_id
    private_subnet_ids = module.vpc.private_subnet_ids
    public_subnet_ids  = module.vpc.public_subnet_ids
  }
  sensitive = false
}

# Requirement: Container Orchestration (8.4 Orchestration)
# Provide Kubernetes cluster access information
output "eks" {
  description = "EKS cluster information"
  value = {
    cluster_endpoint            = module.eks.cluster_endpoint
    cluster_name               = module.eks.cluster_id
    certificate_authority_data = module.eks.cluster_certificate_authority_data
  }
  sensitive = true
}

# Requirement: AWS Services Configuration (8. Infrastructure/8.2 Cloud Services)
# Expose RDS database endpoints and configuration
output "rds" {
  description = "RDS database endpoints"
  value = {
    endpoint      = module.rds.instance_endpoint
    port          = module.rds.instance_port
    database_name = module.rds.database_name
  }
  sensitive = true
}

# Requirement: AWS Services Configuration (8. Infrastructure/8.2 Cloud Services)
# Expose Redis cache endpoints for application caching
output "redis" {
  description = "Redis cache endpoints"
  value = {
    endpoint = module.elasticache.cluster_endpoint
    port     = module.elasticache.cluster_port
  }
  sensitive = true
}

# Requirement: AWS Services Configuration (8. Infrastructure/8.2 Cloud Services)
# Expose S3 bucket information for media storage
output "s3" {
  description = "S3 bucket information"
  value = {
    bucket_name        = module.s3.bucket_name
    bucket_arn         = module.s3.bucket_arn
    bucket_domain_name = module.s3.bucket_domain_name
  }
  sensitive = false
}

# Requirement: AWS Services Configuration (8. Infrastructure/8.2 Cloud Services)
# Expose CloudFront distribution details for CDN configuration
output "cloudfront" {
  description = "CloudFront distribution"
  value = {
    distribution_id = module.cloudfront.distribution_id
    domain_name    = module.cloudfront.domain_name
  }
  sensitive = false
}