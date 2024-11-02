/**
 * HUMAN TASKS:
 * 1. Configure rate limiting for location endpoints
 * 2. Set up monitoring for geospatial query performance
 * 3. Review privacy settings with security team
 * 4. Configure error tracking for location-related errors
 * 5. Set up alerts for high-volume location requests
 */

// express v4.18.2
import { Request, Response } from 'express';
import LocationService from '../services/location.service';
import { 
  ILocation, 
  ICoordinates, 
  IPrivacySettings, 
  LocationType 
} from '../interfaces/location.interface';
import { 
  validateLocation, 
  validatePrivacySettings 
} from '../validators/location.validator';

/**
 * Controller handling location-related HTTP endpoints
 * Addresses requirements:
 * - Location Services - Core location services functionality
 * - Privacy Controls - Location privacy settings
 * - Location-based Search - Geospatial search capabilities
 */
export class LocationController {
  private locationService: LocationService;

  constructor(locationService: LocationService) {
    this.locationService = locationService;
  }

  /**
   * Creates a new location entry with privacy settings
   * Addresses requirements:
   * - Location Services - Core location services functionality
   * - Privacy Controls - Location privacy settings
   */
  @asyncHandler
  async createLocation(req: Request, res: Response): Promise<void> {
    const locationData: ILocation = req.body;

    // Validate location data
    const validationResult = validateLocation(locationData);
    if (!validationResult.isValid) {
      res.status(400).json({
        success: false,
        error: validationResult.errorMessage
      });
      return;
    }

    // Create location using service
    const createdLocation = await this.locationService.createLocation(locationData);

    res.status(201).json({
      success: true,
      data: createdLocation
    });
  }

  /**
   * Updates an existing location entry
   * Addresses requirements:
   * - Location Services - Core location services functionality
   * - Privacy Controls - Location privacy settings
   */
  @asyncHandler
  async updateLocation(req: Request, res: Response): Promise<void> {
    const { id } = req.params;
    const updateData: Partial<ILocation> = req.body;

    // Validate update data if provided
    if (Object.keys(updateData).length > 0) {
      const validationResult = validateLocation({
        ...updateData,
        id: id
      } as ILocation);
      
      if (!validationResult.isValid) {
        res.status(400).json({
          success: false,
          error: validationResult.errorMessage
        });
        return;
      }
    }

    // Update location using service
    const updatedLocation = await this.locationService.updateLocation(id, updateData);

    res.status(200).json({
      success: true,
      data: updatedLocation
    });
  }

  /**
   * Finds locations within specified radius
   * Addresses requirement: Location-based Search - Geospatial search capabilities
   */
  @asyncHandler
  async findNearbyLocations(req: Request, res: Response): Promise<void> {
    const { 
      latitude, 
      longitude, 
      radius, 
      type, 
      userId, 
      privacyLevel, 
      limit 
    } = req.query;

    const coordinates: ICoordinates = {
      latitude: parseFloat(latitude as string),
      longitude: parseFloat(longitude as string)
    };

    const radiusInKm = parseFloat(radius as string);

    // Build filters object
    const filters: any = {};
    if (type) filters.type = type as LocationType;
    if (userId) filters.userId = userId as string;
    if (privacyLevel) filters.privacyLevel = privacyLevel as string;
    if (limit) filters.limit = parseInt(limit as string);

    // Find nearby locations using service
    const locations = await this.locationService.findNearbyLocations(
      coordinates,
      radiusInKm,
      filters
    );

    res.status(200).json({
      success: true,
      data: locations
    });
  }

  /**
   * Retrieves all locations for a user
   * Addresses requirements:
   * - Location Services - Core location services functionality
   * - Privacy Controls - Location privacy settings
   */
  @asyncHandler
  @authenticate
  async getUserLocations(req: Request, res: Response): Promise<void> {
    const userId = req.user.id;

    // Get user locations using service
    const locations = await this.locationService.getUserLocations(userId);

    res.status(200).json({
      success: true,
      data: locations
    });
  }

  /**
   * Deletes a location entry
   * Addresses requirement: Location Services - Core location services functionality
   */
  @asyncHandler
  @authenticate
  async deleteLocation(req: Request, res: Response): Promise<void> {
    const { id } = req.params;

    // Delete location using service
    const deleted = await this.locationService.deleteLocation(id);

    if (!deleted) {
      res.status(404).json({
        success: false,
        error: 'Location not found'
      });
      return;
    }

    res.status(204).send();
  }

  /**
   * Updates privacy settings for a location
   * Addresses requirement: Privacy Controls - Location privacy settings
   */
  @asyncHandler
  @authenticate
  async updatePrivacySettings(req: Request, res: Response): Promise<void> {
    const { id } = req.params;
    const privacySettings: IPrivacySettings = req.body;

    // Validate privacy settings
    const validationResult = validatePrivacySettings(privacySettings);
    if (!validationResult.isValid) {
      res.status(400).json({
        success: false,
        error: validationResult.errorMessage
      });
      return;
    }

    // Update privacy settings using service
    const updatedLocation = await this.locationService.updatePrivacySettings(
      id,
      privacySettings
    );

    res.status(200).json({
      success: true,
      data: updatedLocation
    });
  }
}

export default LocationController;