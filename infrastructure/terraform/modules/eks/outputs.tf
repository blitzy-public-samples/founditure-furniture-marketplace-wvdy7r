# Requirement: Container Orchestration (8.2 Cloud Services/Core Services Configuration)
# Expose essential EKS cluster information for infrastructure configuration
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_endpoint" {
  description = "The endpoint URL for the EKS cluster API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

# Requirement: Kubernetes Infrastructure (8.4 Orchestration)
# Expose OIDC provider URL for service account integration
output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Requirement: Container Orchestration (8.2 Cloud Services/Core Services Configuration)
# Expose node group information for infrastructure management
output "node_groups" {
  description = "Map of node groups created and their attributes"
  value       = aws_eks_node_group.main
}

output "cluster_version" {
  description = "The Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.main.version
}