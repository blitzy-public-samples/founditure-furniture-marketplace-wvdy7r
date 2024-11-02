# Requirement: Primary Database (3.3.3 Data Storage/Primary Database)
# Expose PostgreSQL database connection endpoints and configuration

# Primary database endpoint for application connectivity
output "primary_endpoint" {
  description = "The connection endpoint for the primary RDS instance"
  value       = aws_db_instance.primary.endpoint
}

# Primary database ARN for IAM and resource policies
output "primary_arn" {
  description = "The ARN of the primary RDS instance"
  value       = aws_db_instance.primary.arn
}

# Requirement: Database High Availability (3.5 Scalability Architecture/Database Tier)
# Expose read replica endpoints for high availability access
output "replica_endpoints" {
  description = "List of connection endpoints for read replica instances"
  value       = aws_db_instance.replica[*].endpoint
}

# Database name for application configuration
output "db_name" {
  description = "Name of the created database"
  value       = aws_db_instance.primary.db_name
}

# Master username for database access configuration
output "master_username" {
  description = "Master username for database access"
  value       = aws_db_instance.primary.username
  sensitive   = true
}

# Database port for connection configuration
output "port" {
  description = "Port number for database connections"
  value       = aws_db_instance.primary.port
}

# Requirement: Database Security (7.2 Data Security/7.2.1 Encryption Standards)
# Expose security group information for secure database access
output "security_group_id" {
  description = "ID of the security group controlling database access"
  value       = aws_security_group.rds.id
}

# Parameter group name for database configuration reference
output "parameter_group_name" {
  description = "Name of the DB parameter group used by the instances"
  value       = aws_db_instance.primary.parameter_group_name
}