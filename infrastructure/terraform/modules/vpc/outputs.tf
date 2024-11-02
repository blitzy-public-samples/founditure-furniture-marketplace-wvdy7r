# Requirement: Network Infrastructure (3.1 High-Level Architecture Overview/Network Layer)
# Export VPC and subnet resources for other infrastructure components
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The primary IPv4 CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Requirement: Multi-AZ Deployment (3.5 Scalability Architecture)
# Expose multi-AZ subnet configurations for high availability deployments
output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
  description = "The ID of the route table for public subnets"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of IDs of route tables for private subnets"
  value       = aws_route_table.private[*].id
}