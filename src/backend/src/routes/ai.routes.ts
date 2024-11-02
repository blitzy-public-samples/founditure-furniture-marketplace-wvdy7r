// Human Tasks:
// 1. Configure rate limit thresholds for AI endpoints in environment variables
// 2. Set up monitoring for AI endpoint usage and errors
// 3. Configure authentication bypass list for internal AI service calls if needed
// 4. Verify AI service health check endpoint configuration
// 5. Set up alerts for AI processing timeouts

// Third-party imports with version
import { Router } from 'express'; // ^4.18.x

// Internal imports
import { AIController } from '../controllers/ai.controller';
import { authenticateRequest } from '../middleware/auth.middleware';
import createRateLimiter from '../middleware/rate-limit.middleware';

/**
 * Configures and returns the Express router with AI-related endpoints
 * Requirement: AI/ML Infrastructure (1.2 Scope/Core System Components/3. AI/ML Infrastructure)
 */
export const configureAIRoutes = (aiController: AIController): Router => {
  const router = Router();

  // Requirement: Security Controls (7.3.3 Security Controls)
  // Configure rate limiting specifically for AI endpoints
  const aiRateLimiter = createRateLimiter({
    windowMs: '1m',
    max: 10, // Stricter limit for AI endpoints due to resource intensity
    keyPrefix: 'rate-limit:ai:',
    handler: (req, res) => {
      res.status(429).json({
        error: 'Too Many Requests',
        message: 'AI processing rate limit exceeded. Please try again later.',
        retryAfter: 60
      });
    }
  });

  // Requirement: AI/ML Infrastructure - Routes for image recognition
  // POST /analyze - Analyzes furniture images using AI models
  router.post(
    '/analyze',
    authenticateRequest,
    aiRateLimiter,
    aiController.analyzeFurniture
  );

  // Requirement: AI/ML Infrastructure - Routes for object detection
  // POST /classify - Classifies furniture type from images
  router.post(
    '/classify',
    authenticateRequest,
    aiRateLimiter,
    aiController.classifyFurniture
  );

  // Requirement: AI/ML Infrastructure - Routes for classification services
  // POST /assess-quality - Assesses furniture quality from images
  router.post(
    '/assess-quality',
    authenticateRequest,
    aiRateLimiter,
    aiController.assessQuality
  );

  return router;
};

// Export the route configuration function as default
export default configureAIRoutes;