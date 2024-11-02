/**
 * HUMAN TASKS:
 * 1. Configure rate limiting for location endpoints
 * 2. Set up monitoring for geospatial query performance
 * 3. Review privacy settings with security team
 * 4. Configure error tracking for location-related errors
 * 5. Set up alerts for high-volume location requests
 */

// express v4.18.2
import { Router } from 'express';
import { LocationController } from '../controllers/location.controller';
import { authenticateRequest } from '../middleware/auth.middleware';

/**
 * Express router configuration for location-related endpoints
 * Addresses requirements:
 * - Location Services - Core location services functionality
 * - Privacy Controls - Location privacy settings
 * - Location-based Search - Geospatial search capabilities
 */
const router = Router();

/**
 * Initializes all location-related routes with their respective controllers and middleware
 * @param locationController Instance of LocationController for handling route logic
 * @returns Configured Express router instance
 */
const initializeRoutes = (locationController: LocationController): Router => {
  // Public routes
  router.get(
    '/nearby',
    locationController.findNearbyLocations.bind(locationController)
  );

  // Authenticated routes
  router.post(
    '/',
    authenticateRequest,
    locationController.createLocation.bind(locationController)
  );

  router.put(
    '/:id',
    authenticateRequest,
    locationController.updateLocation.bind(locationController)
  );

  router.get(
    '/user',
    authenticateRequest,
    locationController.getUserLocations.bind(locationController)
  );

  router.delete(
    '/:id',
    authenticateRequest,
    locationController.deleteLocation.bind(locationController)
  );

  router.put(
    '/:id/privacy',
    authenticateRequest,
    locationController.updatePrivacySettings.bind(locationController)
  );

  return router;
};

// Initialize routes with controller instance
const locationController = new LocationController();
const configuredRouter = initializeRoutes(locationController);

export default configuredRouter;