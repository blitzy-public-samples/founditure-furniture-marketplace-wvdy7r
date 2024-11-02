// Human Tasks:
// 1. Configure AWS S3 bucket and CloudFront distribution in environment variables
// 2. Set up proper CORS configuration for S3 bucket
// 3. Verify IAM roles and permissions for S3 and CloudFront operations
// 4. Review and adjust file size limits if needed
// 5. Configure CloudFront cache behaviors for uploaded media

// Third-party imports with versions
import { Request, Response, NextFunction } from 'express'; // ^4.18.x
import multer from 'multer'; // ^1.4.5-lts.1
import { MemoryStorage } from 'multer'; // ^1.4.5-lts.1

// Internal imports
import { uploadFile, validateFile, optimizeImage } from '../utils/file.utils';
import { validateImageFile } from '../utils/validation.utils';

// Global constants from specification
const UPLOAD_LIMITS = {
  fileSize: 10 * 1024 * 1024, // 10MB
  files: 5
};

const ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"];

/**
 * Interface for processed upload file information
 * Requirement: File upload handling and validation
 */
interface UploadedFile {
  originalName: string;
  cdnUrl: string;
  mimeType: string;
  size: number;
}

/**
 * Configure multer with memory storage
 * Requirement: Media Processing (1.2 Scope/Core System Components)
 */
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: {
    fileSize: UPLOAD_LIMITS.fileSize,
    files: UPLOAD_LIMITS.files
  },
  fileFilter: (_req, file, cb) => {
    if (ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'));
    }
  }
});

/**
 * Validates uploaded files before processing
 * Requirement: Media Processing (1.2 Scope/Core System Components)
 */
const validateUpload = async (file: Express.Multer.File): Promise<boolean> => {
  try {
    // Basic file validation
    if (!file.buffer || !file.originalname || !file.mimetype) {
      return false;
    }

    // Validate file size
    if (file.size > UPLOAD_LIMITS.fileSize) {
      return false;
    }

    // Verify mime type
    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      return false;
    }

    // Validate image file using validation utils
    const isValidImage = validateImageFile(file);
    if (!isValidImage) {
      return false;
    }

    // Additional validation from file utils
    return await validateFile(file.buffer, file.originalname);
  } catch (error) {
    return false;
  }
};

/**
 * Express middleware for handling furniture image uploads
 * Requirements:
 * - Object Storage (3.3.3 Data Storage)
 * - Content Delivery (1.1 System Overview)
 * - Media Processing (1.2 Scope/Core System Components)
 */
const uploadMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Handle file upload with multer
    const uploadHandler = upload.array('images', UPLOAD_LIMITS.files);
    
    await new Promise<void>((resolve, reject) => {
      uploadHandler(req, res, (error) => {
        if (error) {
          reject(error);
        } else {
          resolve();
        }
      });
    });

    const files = req.files as Express.Multer.File[];
    if (!files || files.length === 0) {
      res.status(400).json({ error: 'No files uploaded' });
      return;
    }

    // Process and validate each file
    const processedFiles: UploadedFile[] = [];
    
    for (const file of files) {
      // Validate the file
      const isValid = await validateUpload(file);
      if (!isValid) {
        res.status(400).json({ error: `Invalid file: ${file.originalname}` });
        return;
      }

      // Optimize the image
      const optimizedBuffer = await optimizeImage(file.buffer, {
        quality: 80,
        format: 'webp'
      });

      // Upload to S3 and get CDN URL
      const cdnUrl = await uploadFile(
        optimizedBuffer,
        file.originalname,
        'image/webp'
      );

      // Add processed file info
      processedFiles.push({
        originalName: file.originalname,
        cdnUrl,
        mimeType: 'image/webp',
        size: optimizedBuffer.length
      });
    }

    // Attach processed files to request object for next middleware
    req.processedFiles = processedFiles;
    
    next();
  } catch (error) {
    // Handle specific error types
    if (error instanceof multer.MulterError) {
      if (error.code === 'LIMIT_FILE_SIZE') {
        res.status(400).json({ error: 'File size exceeds limit' });
      } else if (error.code === 'LIMIT_FILE_COUNT') {
        res.status(400).json({ error: 'Too many files' });
      } else {
        res.status(400).json({ error: 'File upload error' });
      }
      return;
    }

    // Handle general errors
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Export the middleware as default
export default uploadMiddleware;