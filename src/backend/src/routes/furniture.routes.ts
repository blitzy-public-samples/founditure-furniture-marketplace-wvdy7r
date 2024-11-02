/**
 * Human Tasks:
 * 1. Configure rate limiting for furniture endpoints
 * 2. Set up monitoring for route performance
 * 3. Review and adjust file upload limits
 * 4. Configure caching rules for search endpoints
 * 5. Set up alerts for high error rates
 */

// Third-party imports with versions
import express, { Router } from 'express'; // ^4.18.2

// Internal imports
import FurnitureController from '../controllers/furniture.controller';
import { authenticateRequest, authorizeRoles } from '../middleware/auth.middleware';
import uploadMiddleware from '../middleware/upload.middleware';

/**
 * Initializes and configures furniture routes with middleware and controllers
 * Addresses requirements:
 * - Furniture listing management (1.2 Scope/Core System Components)
 * - Location-based search (1.2 Scope/Included Features)
 * - Content moderation (1.2 Scope/Included Features)
 */
const initializeFurnitureRoutes = (furnitureController: FurnitureController): Router => {
  const router = express.Router();

  // Create new furniture listing with images
  // Requirement: Furniture listing management
  router.post(
    '/',
    authenticateRequest,
    uploadMiddleware,
    furnitureController.createFurniture
  );

  // Search furniture listings with filters and location
  // Requirements: Furniture listing management, Location-based search
  router.get(
    '/search',
    authenticateRequest,
    furnitureController.searchFurniture
  );

  // Get furniture listing by ID
  // Requirement: Furniture listing management
  router.get(
    '/:id',
    authenticateRequest,
    furnitureController.getFurniture
  );

  // Update furniture listing with optional new images
  // Requirements: Furniture listing management, Content moderation
  router.put(
    '/:id',
    authenticateRequest,
    uploadMiddleware,
    furnitureController.updateFurniture
  );

  // Delete furniture listing
  // Requirement: Furniture listing management
  router.delete(
    '/:id',
    authenticateRequest,
    furnitureController.deleteFurniture
  );

  // Update furniture listing status
  // Requirements: Furniture listing management, Content moderation
  router.patch(
    '/:id/status',
    authenticateRequest,
    authorizeRoles(['USER', 'MODERATOR', 'ADMIN']),
    furnitureController.updateFurnitureStatus
  );

  return router;
};

// Create and configure the router
const furnitureRouter = initializeFurnitureRoutes(new FurnitureController());

// Export the configured router
export default furnitureRouter;