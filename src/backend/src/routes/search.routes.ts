/**
 * Human Tasks:
 * 1. Configure rate limiting thresholds in environment variables
 * 2. Set up monitoring for search endpoint performance
 * 3. Configure Elasticsearch connection settings
 * 4. Set up alerts for search service degradation
 * 5. Review and adjust cache TTL settings
 */

// Third-party imports with version
import { Router } from 'express'; // ^4.18.2

// Internal imports
import { searchFurniture, searchByLocation } from '../controllers/search.controller';
import { authenticateRequest } from '../middleware/auth.middleware';
import createRateLimiter from '../middleware/rate-limit.middleware';

/**
 * Initializes and configures all search-related routes
 * Requirements:
 * - Location-based search (1.2 Scope/Included Features)
 * - Search Infrastructure (Technical Specification/5.3 Databases/Elasticsearch)
 */
const searchRouter = Router();

// Configure rate limiter for search endpoints
const searchRateLimiter = createRateLimiter({
  windowMs: 60000, // 1 minute
  maxRequests: 100,
  keyPrefix: 'search-rate-limit:',
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      error: 'TOO_MANY_REQUESTS',
      message: 'Search rate limit exceeded. Please try again later.'
    });
  }
});

/**
 * @route   GET /furniture
 * @desc    Full-text search endpoint for furniture items
 * @access  Private
 * Requirements:
 * - Search Infrastructure - Full-text search capabilities
 */
searchRouter.get(
  '/furniture',
  authenticateRequest,
  searchRateLimiter,
  searchFurniture
);

/**
 * @route   GET /furniture/nearby
 * @desc    Location-based search endpoint for nearby furniture
 * @access  Private
 * Requirements:
 * - Location-based search - API routes for searching furniture based on location
 * - Search Infrastructure - Geospatial search capabilities
 */
searchRouter.get(
  '/furniture/nearby',
  authenticateRequest,
  searchRateLimiter,
  searchByLocation
);

export default searchRouter;