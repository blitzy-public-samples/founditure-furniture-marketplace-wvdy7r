# Terraform AWS Provider version ~> 4.0

# Requirement: Content Delivery Network (3.1 High-Level Architecture Overview/External Services)
# Expose CloudFront distribution details for global content delivery configuration
output "distribution_id" {
  description = "ID of the CloudFront distribution for media assets"
  value       = aws_cloudfront_distribution.media_distribution.id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution for media assets"
  value       = aws_cloudfront_distribution.media_distribution.arn
}

output "distribution_domain_name" {
  description = "Domain name of the CloudFront distribution for media assets"
  value       = aws_cloudfront_distribution.media_distribution.domain_name
}

output "distribution_hosted_zone_id" {
  description = "Route 53 hosted zone ID for the CloudFront distribution"
  value       = aws_cloudfront_distribution.media_distribution.hosted_zone_id
}

# Requirement: Media Assets (1.2 Scope/Core System Components/Data Management)
# Provide CDN endpoint information for media asset delivery
output "origin_access_identity_path" {
  description = "Path for the CloudFront Origin Access Identity used to access the S3 bucket"
  value       = aws_cloudfront_origin_access_identity.media_oai.cloudfront_access_identity_path
}

output "origin_access_identity_iam_arn" {
  description = "IAM ARN of the CloudFront Origin Access Identity for S3 bucket policy"
  value       = aws_cloudfront_origin_access_identity.media_oai.iam_arn
}