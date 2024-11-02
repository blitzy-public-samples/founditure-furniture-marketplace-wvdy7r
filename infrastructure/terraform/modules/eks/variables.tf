# Human Tasks:
# 1. Ensure AWS provider is configured with appropriate permissions for EKS cluster creation
# 2. Configure AWS CLI with proper credentials for kubectl integration
# 3. Review and adjust node group configurations based on workload requirements
# 4. Set up proper IAM roles and policies for EKS service account integration
# 5. Configure AWS Load Balancer Controller after cluster deployment

# Requirement: Container Orchestration (8.2 Cloud Services/Core Services Configuration)
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  
  validation {
    condition     = length(var.cluster_name) <= 40
    error_message = "Cluster name must be 40 characters or less"
  }
}

# Requirement: Kubernetes Infrastructure (8.4 Orchestration)
variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.27"
}

# Requirement: Network Infrastructure (3.1 High-Level Architecture Overview)
variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be deployed"
  type        = string
}

# Requirement: Multi-AZ Deployment (3.5 Scalability Architecture)
variable "subnet_ids" {
  description = "List of subnet IDs where the EKS cluster and nodes will be deployed"
  type        = list(string)
}

# Requirement: Auto-scaling (3.5 Scalability Architecture)
variable "node_groups" {
  description = "Map of EKS node group configurations"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size      = number
    max_size      = number
    disk_size     = number
    labels        = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
}

# Requirement: Kubernetes Infrastructure (8.4 Orchestration)
variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint access"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint access"
  type        = bool
  default     = false
}

# Requirement: Container Orchestration (8.2 Cloud Services/Core Services Configuration)
variable "cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# Requirement: Infrastructure Management (8.1 Deployment Environment)
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}