# Terraform output definitions for the S3 module
# Requirement: Object Storage - Expose S3 bucket configurations for media storage, backups, and logging

# Media bucket outputs
output "media_bucket_id" {
  description = "ID of the media storage bucket"
  value       = aws_s3_bucket.media_bucket.id
}

output "media_bucket_arn" {
  description = "ARN of the media storage bucket"
  value       = aws_s3_bucket.media_bucket.arn
}

output "media_bucket_domain_name" {
  description = "Domain name of the media storage bucket for CDN configuration"
  value       = aws_s3_bucket.media_bucket.bucket_regional_domain_name
}

# Requirement: High Availability - Output cross-region replication configurations for disaster recovery
output "media_bucket_versioning_status" {
  description = "Versioning status of the media storage bucket"
  value       = aws_s3_bucket.media_bucket.versioning[0].status
}

output "media_bucket_replication_status" {
  description = "Replication status of the media storage bucket"
  value       = aws_s3_bucket.media_bucket.replication_configuration[0].status
}

# Backup bucket outputs
output "backup_bucket_id" {
  description = "ID of the backup storage bucket"
  value       = aws_s3_bucket.backup_bucket.id
}

output "backup_bucket_arn" {
  description = "ARN of the backup storage bucket"
  value       = aws_s3_bucket.backup_bucket.arn
}

# Logging bucket outputs
output "logging_bucket_id" {
  description = "ID of the access logging bucket"
  value       = aws_s3_bucket.logging_bucket.id
}

output "logging_bucket_arn" {
  description = "ARN of the access logging bucket"
  value       = aws_s3_bucket.logging_bucket.arn
}