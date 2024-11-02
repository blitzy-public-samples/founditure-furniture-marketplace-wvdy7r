# Founditure S3 Storage Infrastructure
# AWS Provider version ~> 4.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Define common tags for all resources
# Requirement: Object Storage Configuration - Resource organization
locals {
  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Media Storage Bucket
# Requirement: Object Storage - Implementation of distributed object storage for media assets
resource "aws_s3_bucket" "media_bucket" {
  bucket = var.media_bucket_name
  tags   = merge(local.common_tags, { Name = "${var.project_name}-media-${var.environment}" })
}

# Backup Storage Bucket
# Requirement: High Availability - Cross-region replication setup for disaster recovery
resource "aws_s3_bucket" "backup_bucket" {
  bucket = var.backup_bucket_name
  tags   = merge(local.common_tags, { Name = "${var.project_name}-backup-${var.environment}" })
}

# Logging Storage Bucket
# Requirement: Data Security - Audit trail and logging configuration
resource "aws_s3_bucket" "logging_bucket" {
  bucket = var.logging_bucket_name
  tags   = merge(local.common_tags, { Name = "${var.project_name}-logs-${var.environment}" })
}

# Media Bucket Versioning
# Requirement: Data Security - Version control for media assets
resource "aws_s3_bucket_versioning" "media_bucket_versioning" {
  bucket = aws_s3_bucket.media_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Media Bucket Encryption
# Requirement: Data Security - Configuration of encryption for S3 storage
resource "aws_s3_bucket_server_side_encryption_configuration" "media_bucket_encryption" {
  bucket = aws_s3_bucket.media_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Media Bucket Replication
# Requirement: High Availability - Cross-region replication setup for disaster recovery
resource "aws_s3_bucket_replication_configuration" "media_bucket_replication" {
  depends_on = [aws_s3_bucket_versioning.media_bucket_versioning]

  bucket = aws_s3_bucket.media_bucket.id
  role   = aws_iam_role.replication_role.arn

  rule {
    id     = "media_replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.backup_bucket.arn
      storage_class = "STANDARD_IA"
    }
  }
}

# Media Bucket Lifecycle Rules
# Requirement: Object Storage - Lifecycle management for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "media_bucket_lifecycle" {
  bucket = aws_s3_bucket.media_bucket.id

  rule {
    id     = "media_lifecycle"
    status = "Enabled"

    transition {
      days          = var.lifecycle_rules.media.transition_days
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = var.lifecycle_rules.media.expiration_days
    }
  }
}

# Media Bucket Public Access Block
# Requirement: Data Security - Security controls for S3 storage
resource "aws_s3_bucket_public_access_block" "media_bucket_public_access_block" {
  bucket = aws_s3_bucket.media_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for Replication
# Requirement: High Availability - Cross-region replication permissions
resource "aws_iam_role" "replication_role" {
  name = "${var.project_name}-s3-replication-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for Replication
# Requirement: High Availability - Cross-region replication permissions
resource "aws_iam_role_policy" "replication_policy" {
  name = "${var.project_name}-s3-replication-policy-${var.environment}"
  role = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.media_bucket.arn
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.media_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.backup_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Logging Bucket Lifecycle Rules
# Requirement: Object Storage - Log retention management
resource "aws_s3_bucket_lifecycle_configuration" "logging_bucket_lifecycle" {
  bucket = aws_s3_bucket.logging_bucket.id

  rule {
    id     = "log_lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 90
    }
  }
}

# Logging Bucket Encryption
# Requirement: Data Security - Configuration of encryption for logging
resource "aws_s3_bucket_server_side_encryption_configuration" "logging_bucket_encryption" {
  bucket = aws_s3_bucket.logging_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Logging Bucket Public Access Block
# Requirement: Data Security - Security controls for logging
resource "aws_s3_bucket_public_access_block" "logging_bucket_public_access_block" {
  bucket = aws_s3_bucket.logging_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}