# Requirement: Primary Database (3.3.3 Data Storage/Primary Database)
# PostgreSQL deployment for primary data storage with ACID compliance

# Required provider versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Requirement: Database High Availability (3.5 Scalability Architecture/Database Tier)
# Create subnet group for multi-AZ deployment
resource "aws_db_subnet_group" "this" {
  name_prefix = "founditure-${var.environment}"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Requirement: Primary Database Configuration
# Configure PostgreSQL parameter group with optimized settings
resource "aws_db_parameter_group" "this" {
  family      = "postgres14"
  name_prefix = "founditure-${var.environment}"

  parameter {
    name  = "max_connections"
    value = "1000"
  }

  parameter {
    name  = "shared_buffers"
    value = "{DBInstanceClassMemory/4096}MB"
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Requirement: Data Security (7.2 Data Security/Encryption Standards)
# Create security group for RDS access
resource "aws_security_group" "rds" {
  name_prefix = "founditure-rds-${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = var.allowed_cidr_blocks
    security_groups = []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Requirement: Primary Database & High Availability
# Deploy primary RDS instance with multi-AZ support
resource "aws_db_instance" "primary" {
  identifier_prefix = "founditure-${var.environment}"
  
  # Engine configuration
  engine         = "postgres"
  engine_version = "14"
  
  # Instance configuration
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  
  # Database configuration
  db_name  = "founditure"
  username = var.db_username
  password = var.db_password
  
  # High availability configuration
  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = aws_db_parameter_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"
  
  # Security configuration
  storage_encrypted   = true
  deletion_protection = true
  
  # Snapshot configuration
  skip_final_snapshot       = false
  final_snapshot_identifier = "founditure-${var.environment}-final"
  
  # Performance Insights
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  
  # Enhanced monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Requirement: Database High Availability
# Deploy read replicas for scalability
resource "aws_db_instance" "replica" {
  count = var.read_replica_count

  identifier_prefix = "founditure-${var.environment}-replica-${count.index + 1}"
  
  # Replica configuration
  instance_class      = var.replica_instance_class
  replicate_source_db = aws_db_instance.primary.id
  
  # High availability configuration
  multi_az               = false
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  # Performance configuration
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  
  # Enhanced monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Create IAM role for RDS enhanced monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name_prefix = "rds-enhanced-monitoring-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"]

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Random string for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}