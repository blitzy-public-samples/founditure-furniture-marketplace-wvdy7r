// Human Tasks:
// 1. Configure AWS S3 bucket name and region in environment variables
// 2. Set up CloudFront distribution and configure environment variables
// 3. Configure allowed file types and size limits in environment if different from defaults
// 4. Set up proper CORS configuration for S3 bucket
// 5. Configure CloudFront cache behaviors and invalidation settings
// 6. Verify proper IAM roles and permissions for S3 and CloudFront operations

// Third-party imports with versions
import { s3Client, cloudFrontClient } from '../config/aws';
import { error, warn, info, debug } from './logger.utils';
import sharp from 'sharp'; // ^0.32.x
import mime from 'mime-types'; // ^2.1.x
import { v4 as uuidv4 } from 'uuid'; // ^9.0.x
import {
  PutObjectCommand,
  DeleteObjectCommand,
  CreateMultipartUploadCommand,
  GetObjectCommand
} from '@aws-sdk/client-s3';
import {
  CreateInvalidationCommand,
  GetDistributionCommand
} from '@aws-sdk/client-cloudfront';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

// Global constants
const ALLOWED_FILE_TYPES = ['.jpg', '.jpeg', '.png', '.webp'];
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
const IMAGE_QUALITY = 80;

// Environment variables
const S3_BUCKET = process.env.S3_BUCKET_NAME || 'founditure-media';
const CLOUDFRONT_DOMAIN = process.env.CLOUDFRONT_DOMAIN;
const CLOUDFRONT_DISTRIBUTION_ID = process.env.CLOUDFRONT_DISTRIBUTION_ID;

/**
 * Requirement: Object Storage (3.3.3 Data Storage)
 * Uploads a file to S3 and returns the CDN URL
 */
export const uploadFile = async (
  fileBuffer: Buffer,
  fileName: string,
  contentType: string
): Promise<string> => {
  try {
    // Validate file before upload
    const isValid = await validateFile(fileBuffer, fileName);
    if (!isValid) {
      throw new Error('Invalid file');
    }

    // Generate unique file name
    const uniqueFileName = `${uuidv4()}-${fileName}`;
    let processedBuffer = fileBuffer;

    // Optimize image if it's an image file
    if (contentType.startsWith('image/')) {
      processedBuffer = await optimizeImage(fileBuffer, {
        quality: IMAGE_QUALITY,
        format: 'webp'
      });
    }

    // Upload to S3
    const uploadCommand = new PutObjectCommand({
      Bucket: S3_BUCKET,
      Key: uniqueFileName,
      Body: processedBuffer,
      ContentType: contentType,
      CacheControl: 'public, max-age=31536000'
    });

    await s3Client.send(uploadCommand);
    info(`File uploaded successfully: ${uniqueFileName}`);

    // Generate and return CDN URL
    return `https://${CLOUDFRONT_DOMAIN}/${uniqueFileName}`;
  } catch (err) {
    error('Error uploading file:', err);
    throw new Error('File upload failed');
  }
};

/**
 * Requirement: Media Processing (1.2 Scope/Core System Components)
 * Validates file type, size, and content
 */
export const validateFile = async (
  fileBuffer: Buffer,
  fileName: string
): Promise<boolean> => {
  try {
    // Check file size
    if (fileBuffer.length > MAX_FILE_SIZE) {
      warn(`File size exceeds maximum limit: ${fileName}`);
      return false;
    }

    // Check file extension
    const extension = `.${fileName.split('.').pop()?.toLowerCase()}`;
    if (!ALLOWED_FILE_TYPES.includes(extension)) {
      warn(`Invalid file type: ${extension}`);
      return false;
    }

    // Verify file content type
    const mimeType = mime.lookup(fileName);
    if (!mimeType || !mimeType.startsWith('image/')) {
      warn(`Invalid MIME type: ${mimeType}`);
      return false;
    }

    // Verify image can be processed
    await sharp(fileBuffer).metadata();

    debug(`File validation successful: ${fileName}`);
    return true;
  } catch (err) {
    error('Error validating file:', err);
    return false;
  }
};

/**
 * Requirement: Media Processing (1.2 Scope/Core System Components)
 * Optimizes image for storage and delivery
 */
export const optimizeImage = async (
  imageBuffer: Buffer,
  options: {
    quality?: number;
    format?: keyof sharp.FormatEnum;
    width?: number;
    height?: number;
  }
): Promise<Buffer> => {
  try {
    const {
      quality = IMAGE_QUALITY,
      format = 'webp',
      width,
      height
    } = options;

    let processor = sharp(imageBuffer);

    // Resize if dimensions provided
    if (width || height) {
      processor = processor.resize(width, height, {
        fit: 'inside',
        withoutEnlargement: true
      });
    }

    // Convert format and apply compression
    const processedBuffer = await processor
      .toFormat(format, { quality })
      .toBuffer();

    debug('Image optimization successful');
    return processedBuffer;
  } catch (err) {
    error('Error optimizing image:', err);
    throw new Error('Image optimization failed');
  }
};

/**
 * Requirement: Object Storage (3.3.3 Data Storage)
 * Deletes a file from S3 storage
 */
export const deleteFile = async (fileUrl: string): Promise<void> => {
  try {
    // Extract file key from URL
    const fileKey = fileUrl.split('/').pop();
    if (!fileKey) {
      throw new Error('Invalid file URL');
    }

    // Delete from S3
    const deleteCommand = new DeleteObjectCommand({
      Bucket: S3_BUCKET,
      Key: fileKey
    });

    await s3Client.send(deleteCommand);

    // Invalidate CDN cache
    const invalidationCommand = new CreateInvalidationCommand({
      DistributionId: CLOUDFRONT_DISTRIBUTION_ID,
      InvalidationBatch: {
        CallerReference: String(Date.now()),
        Paths: {
          Quantity: 1,
          Items: [`/${fileKey}`]
        }
      }
    });

    await cloudFrontClient.send(invalidationCommand);
    info(`File deleted successfully: ${fileKey}`);
  } catch (err) {
    error('Error deleting file:', err);
    throw new Error('File deletion failed');
  }
};

/**
 * Requirement: Content Delivery (1.1 System Overview)
 * Generates a temporary URL for file upload
 */
export const generatePresignedUrl = async (
  fileName: string,
  contentType: string
): Promise<string> => {
  try {
    // Validate input parameters
    if (!fileName || !contentType) {
      throw new Error('Invalid file parameters');
    }

    // Generate unique key
    const fileKey = `${uuidv4()}-${fileName}`;

    // Create presigned URL command
    const command = new PutObjectCommand({
      Bucket: S3_BUCKET,
      Key: fileKey,
      ContentType: contentType
    });

    // Generate presigned URL with 15-minute expiration
    const presignedUrl = await getSignedUrl(s3Client, command, {
      expiresIn: 900
    });

    debug(`Presigned URL generated for: ${fileKey}`);
    return presignedUrl;
  } catch (err) {
    error('Error generating presigned URL:', err);
    throw new Error('Presigned URL generation failed');
  }
};