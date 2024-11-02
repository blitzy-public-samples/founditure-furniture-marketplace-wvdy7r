/**
 * Human Tasks:
 * 1. Configure rate limiting thresholds for search endpoints
 * 2. Set up monitoring for search performance metrics
 * 3. Review and adjust cache TTL settings based on usage patterns
 * 4. Configure geospatial search radius limits
 * 5. Set up alerts for search service degradation
 */

// External dependencies
import { Request, Response } from 'express'; // ^4.18.2
import asyncHandler from 'express-async-handler'; // ^1.2.0

// Internal dependencies
import SearchService from '../services/search.service';
import { validateCoordinates } from '../utils/validation.utils';
import { ERROR_CODES } from '../constants/error-codes';

/**
 * Controller class handling search-related HTTP endpoints
 * Implements search functionality with caching and geospatial features
 */
class SearchController {
  private searchService: SearchService;

  /**
   * Initializes search controller with required services
   */
  constructor(searchService: SearchService) {
    this.searchService = searchService;
  }

  /**
   * Handles full-text search requests for furniture items
   * Requirement: Search Infrastructure - Full-text search capabilities
   */
  @asyncHandler
  public searchFurniture = async (req: Request, res: Response): Promise<void> => {
    const {
      query,
      category,
      condition,
      sortBy,
      page = 0,
      limit = 50,
      ...filters
    } = req.query;

    // Validate required parameters
    if (!query || typeof query !== 'string') {
      res.status(400).json({
        success: false,
        error: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        message: 'Search query is required'
      });
      return;
    }

    try {
      // Build search options
      const searchOptions = {
        category: category as string,
        condition: condition as string,
        sortBy: sortBy as string,
        page: Number(page),
        limit: Number(limit),
        filters
      };

      // Execute search
      const results = await this.searchService.searchFurniture(
        query,
        searchOptions
      );

      res.status(200).json({
        success: true,
        data: results,
        pagination: {
          page: Number(page),
          limit: Number(limit),
          total: results.length
        }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: ERROR_CODES.SERVER_INTERNAL_ERROR,
        message: 'Error performing furniture search'
      });
    }
  };

  /**
   * Handles location-based search requests
   * Requirements:
   * - Location-based search - Geospatial search capabilities
   * - Search Infrastructure - Geospatial search implementation
   */
  @asyncHandler
  public searchByLocation = async (req: Request, res: Response): Promise<void> => {
    const {
      latitude,
      longitude,
      radius,
      category,
      condition,
      privacyLevel,
      includeUnavailable,
      page = 0,
      limit = 50
    } = req.query;

    // Validate coordinates
    const coordinates = {
      latitude: Number(latitude),
      longitude: Number(longitude)
    };

    if (!validateCoordinates(coordinates.latitude, coordinates.longitude)) {
      res.status(400).json({
        success: false,
        error: ERROR_CODES.LOCATION_INVALID_COORDINATES,
        message: 'Invalid coordinates provided'
      });
      return;
    }

    // Validate radius
    const searchRadius = Number(radius);
    if (isNaN(searchRadius) || searchRadius <= 0 || searchRadius > 100) {
      res.status(400).json({
        success: false,
        error: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        message: 'Invalid search radius. Must be between 0 and 100 km'
      });
      return;
    }

    try {
      // Build location search options
      const searchOptions = {
        category: category as string,
        condition: condition as string,
        privacyLevel: privacyLevel as string,
        includeUnavailable: includeUnavailable === 'true',
        page: Number(page),
        limit: Number(limit)
      };

      // Execute location-based search
      const results = await this.searchService.searchByLocation(
        coordinates,
        searchRadius,
        searchOptions
      );

      res.status(200).json({
        success: true,
        data: results,
        metadata: {
          center: coordinates,
          radius: searchRadius,
          unit: 'km'
        },
        pagination: {
          page: Number(page),
          limit: Number(limit),
          total: results.length
        }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: ERROR_CODES.SERVER_INTERNAL_ERROR,
        message: 'Error performing location-based search'
      });
    }
  };
}

export default SearchController;