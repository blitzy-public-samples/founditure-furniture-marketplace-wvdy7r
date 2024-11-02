# Human Tasks:
# 1. Ensure AWS provider is configured with appropriate permissions for ElastiCache management
# 2. Verify VPC and subnet configurations are properly set up for ElastiCache deployment
# 3. Review security group rules to allow required Redis port access
# 4. Confirm parameter group family compatibility with desired Redis version

# AWS Provider version ~> 4.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Requirement: Generate unique identifiers for resources
resource "random_id" "suffix" {
  byte_length = 4
}

# Requirement: Cache Layer (8.2 Cloud Services/Core Services Configuration)
# ElastiCache Redis cluster with 3 shards for distributed caching
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = format("%s-redis-%s", var.environment, random_id.suffix.hex)
  replication_group_description = "Redis cluster for Founditure application"
  node_type                    = var.node_type
  port                         = var.port
  parameter_group_family       = var.parameter_group_family
  automatic_failover_enabled   = var.automatic_failover
  multi_az_enabled            = var.multi_az_enabled
  num_cache_clusters          = var.num_cache_nodes
  subnet_group_name           = aws_elasticache_subnet_group.redis.name
  security_group_ids          = [aws_security_group.redis.id]
  at_rest_encryption_enabled  = var.at_rest_encryption
  transit_encryption_enabled  = var.transit_encryption

  tags = {
    Environment = var.environment
    Name        = format("%s-redis-%s", var.environment, random_id.suffix.hex)
    Terraform   = "true"
  }
}

# Requirement: High Availability (3.5 Scalability Architecture/Cache Layer)
# Multi-AZ Redis deployment with automatic failover
resource "aws_elasticache_subnet_group" "redis" {
  name        = format("%s-redis-subnet-group-%s", var.environment, random_id.suffix.hex)
  subnet_ids  = var.subnet_ids
  description = "Subnet group for Redis cluster in ${var.environment}"

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Requirement: Network Security
# Security group for Redis cluster access control
resource "aws_security_group" "redis" {
  name        = format("%s-redis-sg-%s", var.environment, random_id.suffix.hex)
  description = "Security group for Redis cluster"
  vpc_id      = var.vpc_id

  # Redis port ingress rule
  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Allow Redis traffic from internal network"
  }

  # Allow all egress traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = format("%s-redis-sg-%s", var.environment, random_id.suffix.hex)
    Environment = var.environment
    Terraform   = "true"
  }
}

# Requirement: Export Redis cluster endpoints for application configuration
output "primary_endpoint_address" {
  description = "Primary endpoint address for Redis cluster"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address for Redis cluster"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

# Requirement: Export security group ID for network configuration
output "security_group_id" {
  description = "ID of the Redis security group"
  value       = aws_security_group.redis.id
}