// Human Tasks:
// 1. Set up AWS S3 bucket name in environment variables (S3_BUCKET_NAME)
// 2. Configure CloudFront distribution domain in environment (CLOUDFRONT_DOMAIN)
// 3. Set up CloudFront distribution ID in environment (CLOUDFRONT_DISTRIBUTION_ID)
// 4. Configure allowed file types and size limits if different from defaults
// 5. Verify proper IAM roles and permissions for S3 and CloudFront operations
// 6. Set up proper CORS configuration for S3 bucket
// 7. Configure CloudFront cache behaviors and invalidation settings

// Third-party imports with versions
import { 
  PutObjectCommand, 
  DeleteObjectCommand,
  GetObjectCommand 
} from '@aws-sdk/client-s3'; // ^3.x
import { 
  CreateInvalidationCommand 
} from '@aws-sdk/client-cloudfront'; // ^3.x
import { v4 as uuidv4 } from 'uuid'; // ^9.0.x

// Internal imports
import { s3Client, cloudFrontClient } from '../config/aws';
import { validateFile, optimizeImage } from '../utils/file.utils';
import { error, warn, info, debug } from '../utils/logger.utils';

/**
 * Requirement: 3.3.3 Data Storage/Object Storage
 * Service class for managing file storage operations in the Founditure platform
 */
class StorageService {
  private readonly s3Client;
  private readonly cloudFrontClient;
  private readonly bucketName: string;
  private readonly cdnDomain: string;

  constructor() {
    // Initialize AWS clients and configuration
    this.s3Client = s3Client;
    this.cloudFrontClient = cloudFrontClient;
    this.bucketName = process.env.S3_BUCKET_NAME || '';
    this.cdnDomain = process.env.CLOUDFRONT_DOMAIN || '';

    // Validate storage configuration
    if (!this.bucketName || !this.cdnDomain) {
      error('Storage configuration missing required values');
      throw new Error('Invalid storage configuration');
    }

    info('StorageService initialized successfully');
  }

  /**
   * Requirement: Media Processing (1.2 Scope/Core System Components)
   * Uploads a furniture image to S3 and returns the CDN URL
   */
  async uploadFurnitureImage(
    imageBuffer: Buffer,
    fileName: string,
    contentType: string
  ): Promise<string> {
    try {
      // Validate file
      const isValid = await validateFile(imageBuffer, fileName);
      if (!isValid) {
        throw new Error('Invalid file format or content');
      }

      // Optimize image
      const optimizedBuffer = await optimizeImage(imageBuffer, {
        quality: 80,
        format: 'webp'
      });

      // Generate unique file path
      const uniqueFileName = `furniture/${uuidv4()}-${fileName.replace(/\s+/g, '-')}`;

      // Upload to S3
      const uploadCommand = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: uniqueFileName,
        Body: optimizedBuffer,
        ContentType: 'image/webp',
        CacheControl: 'public, max-age=31536000'
      });

      await this.s3Client.send(uploadCommand);
      info(`Furniture image uploaded successfully: ${uniqueFileName}`);

      // Return CDN URL
      return `https://${this.cdnDomain}/${uniqueFileName}`;
    } catch (err) {
      error('Error uploading furniture image:', err);
      throw new Error('Failed to upload furniture image');
    }
  }

  /**
   * Requirement: Object Storage (3.3.3 Data Storage)
   * Deletes a furniture image from storage
   */
  async deleteFurnitureImage(imageUrl: string): Promise<void> {
    try {
      // Extract S3 key from CDN URL
      const key = imageUrl.replace(`https://${this.cdnDomain}/`, '');
      if (!key) {
        throw new Error('Invalid image URL');
      }

      // Delete from S3
      const deleteCommand = new DeleteObjectCommand({
        Bucket: this.bucketName,
        Key: key
      });

      await this.s3Client.send(deleteCommand);

      // Create CloudFront invalidation
      const invalidationCommand = new CreateInvalidationCommand({
        DistributionId: process.env.CLOUDFRONT_DISTRIBUTION_ID!,
        InvalidationBatch: {
          CallerReference: String(Date.now()),
          Paths: {
            Quantity: 1,
            Items: [`/${key}`]
          }
        }
      });

      await this.cloudFrontClient.send(invalidationCommand);
      info(`Furniture image deleted successfully: ${key}`);
    } catch (err) {
      error('Error deleting furniture image:', err);
      throw new Error('Failed to delete furniture image');
    }
  }

  /**
   * Requirement: Content Delivery (1.1 System Overview)
   * Generates a pre-signed URL for direct browser upload
   */
  async generatePresignedUploadUrl(
    fileName: string,
    contentType: string
  ): Promise<string> {
    try {
      // Validate input parameters
      if (!fileName || !contentType) {
        throw new Error('Invalid file parameters');
      }

      // Generate unique file path
      const key = `uploads/${uuidv4()}-${fileName.replace(/\s+/g, '-')}`;

      // Create pre-signed URL command
      const command = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: key,
        ContentType: contentType,
        CacheControl: 'public, max-age=31536000'
      });

      // Generate URL with 15-minute expiration
      const presignedUrl = await getSignedUrl(this.s3Client, command, {
        expiresIn: 900
      });

      debug(`Generated pre-signed upload URL for: ${key}`);
      return presignedUrl;
    } catch (err) {
      error('Error generating pre-signed upload URL:', err);
      throw new Error('Failed to generate upload URL');
    }
  }

  /**
   * Requirement: Content Delivery (1.1 System Overview)
   * Generates a CDN URL for an image
   */
  getImageUrl(imageKey: string): string {
    try {
      // Validate image key
      if (!imageKey) {
        throw new Error('Invalid image key');
      }

      // Construct CDN URL
      const cdnUrl = `https://${this.cdnDomain}/${imageKey}`;
      debug(`Generated CDN URL: ${cdnUrl}`);
      return cdnUrl;
    } catch (err) {
      error('Error generating image URL:', err);
      throw new Error('Failed to generate image URL');
    }
  }
}

// Export singleton instance
export default new StorageService();