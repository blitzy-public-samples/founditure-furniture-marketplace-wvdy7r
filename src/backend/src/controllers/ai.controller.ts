// Human Tasks:
// 1. Configure TensorFlow model paths in environment variables
// 2. Set up proper IAM roles for accessing AI service resources
// 3. Configure memory limits for image processing
// 4. Set up monitoring alerts for AI processing errors
// 5. Verify error handling and logging configuration

// Third-party imports with versions
import { Request, Response } from 'express'; // ^4.18.x
import { tryCatch } from '../utils/error.utils'; // Internal decorator

// Internal imports
import { analyzeFurnitureImage, classifyFurniture, assessQuality } from '../services/ai.service';
import { uploadMiddleware } from '../middleware/upload.middleware';
import { logger } from '../utils/logger.utils';

/**
 * Controller class handling AI-related HTTP endpoints
 * Implements AI/ML processing endpoints for furniture image analysis
 */
export class AIController {
  private aiService: typeof import('../services/ai.service');

  /**
   * Initializes the AI controller with required services
   * Requirement: AI/ML Infrastructure (1.2 Scope/Core System Components)
   */
  constructor(aiService: typeof import('../services/ai.service')) {
    this.aiService = aiService;
    this.analyzeFurniture = this.analyzeFurniture.bind(this);
    this.classifyFurniture = this.classifyFurniture.bind(this);
    this.assessQuality = this.assessQuality.bind(this);
  }

  /**
   * Handles furniture image analysis requests
   * Requirement: Image Recognition (A.1 AI Model Specifications)
   */
  @tryCatch
  public async analyzeFurniture(req: Request, res: Response): Promise<Response> {
    logger.info('Processing furniture analysis request');

    // Validate request and image data
    if (!req.files || !Array.isArray(req.files) || req.files.length === 0) {
      logger.warn('No image files provided for analysis');
      return res.status(400).json({
        error: 'No image files provided',
        code: 'MISSING_IMAGE'
      });
    }

    // Extract image buffer from request
    const imageFile = (req.files as Express.Multer.File[])[0];
    const imageBuffer = imageFile.buffer;

    try {
      // Call AI service for image analysis
      const analysisResults = await this.aiService.analyzeFurnitureImage(imageBuffer);

      // Process and format analysis results
      logger.info('Furniture analysis completed successfully');
      return res.status(200).json({
        success: true,
        data: {
          metadata: analysisResults,
          timestamp: new Date().toISOString()
        }
      });
    } catch (error) {
      logger.error('Furniture analysis failed:', error);
      return res.status(500).json({
        error: 'Failed to analyze furniture image',
        code: 'ANALYSIS_FAILED'
      });
    }
  }

  /**
   * Handles furniture classification requests
   * Requirement: Image Recognition (A.1 AI Model Specifications)
   */
  @tryCatch
  public async classifyFurniture(req: Request, res: Response): Promise<Response> {
    logger.info('Processing furniture classification request');

    // Validate request and image data
    if (!req.files || !Array.isArray(req.files) || req.files.length === 0) {
      logger.warn('No image files provided for classification');
      return res.status(400).json({
        error: 'No image files provided',
        code: 'MISSING_IMAGE'
      });
    }

    // Extract image buffer from request
    const imageFile = (req.files as Express.Multer.File[])[0];
    const imageBuffer = imageFile.buffer;

    try {
      // Call AI service for classification
      const classificationResults = await this.aiService.classifyFurniture(imageBuffer);

      // Process classification results
      logger.info('Furniture classification completed successfully');
      return res.status(200).json({
        success: true,
        data: {
          classifications: classificationResults,
          timestamp: new Date().toISOString()
        }
      });
    } catch (error) {
      logger.error('Furniture classification failed:', error);
      return res.status(500).json({
        error: 'Failed to classify furniture image',
        code: 'CLASSIFICATION_FAILED'
      });
    }
  }

  /**
   * Handles furniture quality assessment requests
   * Requirement: AI/ML Infrastructure (1.2 Scope/Core System Components)
   */
  @tryCatch
  public async assessQuality(req: Request, res: Response): Promise<Response> {
    logger.info('Processing furniture quality assessment request');

    // Validate request and image data
    if (!req.files || !Array.isArray(req.files) || req.files.length === 0) {
      logger.warn('No image files provided for quality assessment');
      return res.status(400).json({
        error: 'No image files provided',
        code: 'MISSING_IMAGE'
      });
    }

    // Extract image buffer from request
    const imageFile = (req.files as Express.Multer.File[])[0];
    const imageBuffer = imageFile.buffer;

    try {
      // Call AI service for quality assessment
      const qualityResults = await this.aiService.assessQuality(imageBuffer);

      // Process assessment results
      logger.info('Furniture quality assessment completed successfully');
      return res.status(200).json({
        success: true,
        data: {
          quality: qualityResults,
          timestamp: new Date().toISOString()
        }
      });
    } catch (error) {
      logger.error('Furniture quality assessment failed:', error);
      return res.status(500).json({
        error: 'Failed to assess furniture quality',
        code: 'ASSESSMENT_FAILED'
      });
    }
  }
}

// Export controller as default
export default AIController;