# Human Tasks:
# 1. Ensure AWS credentials are properly configured for CloudFront access
# 2. Verify that the S3 buckets referenced in media_bucket_id and logging_bucket_id exist and have proper permissions
# 3. Review price_class selection based on target market regions and budget constraints

# AWS Provider configuration
# Version: ~> 4.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Requirement: Content Delivery Network (3.1 High-Level Architecture Overview/External Services)
# Reference to the media storage S3 bucket
data "aws_s3_bucket" "media_bucket" {
  bucket = var.media_bucket_id
}

# Requirement: Media Assets (1.2 Scope/Core System Components/Data Management)
# Origin Access Identity for secure S3 bucket access
resource "aws_cloudfront_origin_access_identity" "media_oai" {
  comment = "OAI for Founditure media assets"
}

# Requirement: Content Delivery Network, Media Assets, High Availability
# CloudFront distribution for media content delivery
resource "aws_cloudfront_distribution" "media_distribution" {
  enabled             = true
  is_ipv6_enabled    = true
  price_class        = var.price_class
  comment            = "Founditure media distribution - ${var.environment}"
  default_root_object = "index.html"

  # Requirement: High Availability - Configure access logging
  logging_config {
    include_cookies = false
    bucket          = var.logging_bucket_id
    prefix          = "cloudfront/media/"
  }

  # Requirement: Media Assets - Configure S3 origin
  origin {
    domain_name = data.aws_s3_bucket.media_bucket.bucket_regional_domain_name
    origin_id   = "S3-${var.media_bucket_id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.media_oai.cloudfront_access_identity_path
    }
  }

  # Requirement: Content Delivery Network - Configure default cache behavior
  default_cache_behavior {
    allowed_methods  = var.allowed_methods
    cached_methods   = var.cached_methods
    target_origin_id = "S3-${var.media_bucket_id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    compress               = var.enable_compression
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
  }

  # Requirement: High Availability - Configure geo-restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Requirement: Content Delivery Network - Configure SSL/TLS
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Apply environment and resource tags
  tags = merge(
    var.tags,
    {
      Name        = "founditure-media-cdn-${var.environment}"
      Environment = var.environment
      Managed_by  = "terraform"
    }
  )
}

# Requirement: Media Assets - Configure S3 bucket policy for CloudFront access
resource "aws_s3_bucket_policy" "media_bucket_policy" {
  bucket = var.media_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAIAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.media_oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${data.aws_s3_bucket.media_bucket.arn}/*"
      }
    ]
  })
}

# Requirement: High Availability - Configure custom error responses
resource "aws_cloudfront_distribution" "media_distribution" {
  # ... (previous configuration) ...

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }
}

# Requirement: Content Delivery Network - Configure cache behaviors for different file types
resource "aws_cloudfront_distribution" "media_distribution" {
  # ... (previous configuration) ...

  ordered_cache_behavior {
    path_pattern     = "*.jpg"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.media_bucket_id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400    # 24 hours
    max_ttl                = 31536000 # 1 year
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern     = "*.png"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.media_bucket_id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400    # 24 hours
    max_ttl                = 31536000 # 1 year
    compress               = true
  }
}