// Human Tasks:
// 1. Set up AWS credentials in environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
// 2. Configure S3 bucket name in environment (S3_BUCKET_NAME)
// 3. Set up CloudFront distribution and add ID to environment (CLOUDFRONT_DISTRIBUTION_ID)
// 4. Configure AWS KMS keys for encryption
// 5. Verify IAM roles have necessary permissions for all AWS services
// 6. Set up proper CORS configuration for S3 bucket
// 7. Configure CloudFront cache behaviors and security settings

// Third-party imports with versions
import { S3Client, S3ClientConfig } from '@aws-sdk/client-s3'; // ^3.x
import { CloudFrontClient, CloudFrontClientConfig } from '@aws-sdk/client-cloudfront'; // ^3.x
import { KMSClient, KMSClientConfig } from '@aws-sdk/client-kms'; // ^3.x
import { CloudWatchClient } from '@aws-sdk/client-cloudwatch'; // ^3.x

// Internal imports
import { logger } from '../utils/logger.utils';

// Global AWS configuration from environment variables
const AWS_REGION = process.env.AWS_REGION || 'us-east-1';
const S3_BUCKET_NAME = process.env.S3_BUCKET_NAME;
const CLOUDFRONT_DISTRIBUTION_ID = process.env.CLOUDFRONT_DISTRIBUTION_ID;

// Requirement: 3.3.3 Data Storage/Object Storage
// Base configuration for AWS clients
const baseConfig = {
  region: AWS_REGION,
  maxAttempts: 3,
  retryMode: 'adaptive',
  requestTimeout: 5000
};

// Requirement: 3.3.3 Data Storage/Object Storage
// Creates and configures an S3 client instance
export const createS3Client = (): S3Client => {
  logger.info('Initializing S3 client');
  
  const config: S3ClientConfig = {
    ...baseConfig,
    forcePathStyle: false, // Use virtual hosted-style URLs
    useAccelerateEndpoint: true // Enable S3 Transfer Acceleration
  };

  try {
    return new S3Client(config);
  } catch (error) {
    logger.error('Failed to create S3 client', { error });
    throw error;
  }
};

// Requirement: 1.1 System Overview/Content Delivery
// Creates and configures a CloudFront client instance
export const createCloudFrontClient = (): CloudFrontClient => {
  logger.info('Initializing CloudFront client');
  
  const config: CloudFrontClientConfig = {
    ...baseConfig,
    apiVersion: '2020-05-31'
  };

  try {
    return new CloudFrontClient(config);
  } catch (error) {
    logger.error('Failed to create CloudFront client', { error });
    throw error;
  }
};

// Requirement: 7.2.1 Encryption Standards
// Creates and configures a KMS client instance
export const createKMSClient = (): KMSClient => {
  logger.info('Initializing KMS client');
  
  const config: KMSClientConfig = {
    ...baseConfig,
    apiVersion: '2014-11-01'
  };

  try {
    return new KMSClient(config);
  } catch (error) {
    logger.error('Failed to create KMS client', { error });
    throw error;
  }
};

// Requirement: 8.1 Deployment Environment/Cloud Infrastructure
// Validates required AWS configuration settings
export const validateAWSConfig = async (): Promise<boolean> => {
  logger.info('Validating AWS configuration');

  try {
    // Check required environment variables
    if (!process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY) {
      throw new Error('AWS credentials not configured');
    }

    if (!S3_BUCKET_NAME) {
      throw new Error('S3_BUCKET_NAME not configured');
    }

    if (!CLOUDFRONT_DISTRIBUTION_ID) {
      throw new Error('CLOUDFRONT_DISTRIBUTION_ID not configured');
    }

    // Initialize clients to verify connectivity
    const s3Client = createS3Client();
    const cloudFrontClient = createCloudFrontClient();
    const kmsClient = createKMSClient();

    // Verify S3 bucket exists and is accessible
    await s3Client.send({
      Bucket: S3_BUCKET_NAME,
      command: 'headBucket'
    });

    // Verify CloudFront distribution
    await cloudFrontClient.send({
      Id: CLOUDFRONT_DISTRIBUTION_ID,
      command: 'getDistribution'
    });

    logger.info('AWS configuration validation successful');
    return true;
  } catch (error) {
    logger.error('AWS configuration validation failed', { error });
    return false;
  }
};

// Initialize and export AWS service clients
export const s3Client = createS3Client();
export const cloudFrontClient = createCloudFrontClient();
export const kmsClient = createKMSClient();