# AWS Provider version ~> 4.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Requirement: Cache Layer Integration (8.2 Cloud Services/Core Services Configuration)
# Expose Redis cluster endpoints for application integration
output "primary_endpoint" {
  description = "Primary endpoint for Redis cluster write operations"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Reader endpoint for Redis cluster read operations"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "port" {
  description = "Port number for Redis cluster connections"
  value       = aws_elasticache_replication_group.redis.port
}

# Requirement: High Availability Configuration (3.5 Scalability Architecture/Cache Layer)
# Export Redis cluster configuration for infrastructure integration
output "security_group_id" {
  description = "ID of the security group attached to Redis cluster"
  value       = aws_security_group.redis.id
}

output "replication_group_id" {
  description = "ID of the Redis replication group"
  value       = aws_elasticache_replication_group.redis.id
}

output "parameter_group_name" {
  description = "Name of the parameter group used by Redis cluster"
  value       = aws_elasticache_replication_group.redis.parameter_group_name
}