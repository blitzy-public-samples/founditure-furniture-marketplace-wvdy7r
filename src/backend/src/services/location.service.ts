/**
 * HUMAN TASKS:
 * 1. Ensure MongoDB indexes are created for geospatial queries
 * 2. Configure environment variables for privacy settings thresholds
 * 3. Review and adjust privacy radius constants based on regional requirements
 * 4. Verify coordinate precision requirements with location team
 * 5. Set up monitoring for location service performance metrics
 */

// mongoose v7.x
import { Types } from 'mongoose';
import Location from '../models/location.model';
import { 
  ILocation, 
  ICoordinates, 
  IPrivacySettings, 
  LocationType 
} from '../interfaces/location.interface';
import { 
  validateCoordinates, 
  calculateDistance, 
  fuzzLocation, 
  generateBoundingBox 
} from '../utils/geo.utils';
import { 
  validateLocation, 
  validatePrivacySettings 
} from '../validators/location.validator';

/**
 * Service class for handling location-related operations
 * Addresses requirements:
 * - Location Services - Core location services functionality
 * - Privacy Controls - Location privacy settings
 * - Location-based Search - Geospatial search capabilities
 */
export class LocationService {
  private Location: typeof Location;

  constructor() {
    this.Location = Location;
  }

  /**
   * Creates a new location entry with privacy settings
   * Addresses requirements:
   * - Location Services - Core location services functionality
   * - Privacy Controls - Location privacy settings
   */
  async createLocation(locationData: ILocation): Promise<ILocation> {
    // Validate location data
    const validationResult = validateLocation(locationData);
    if (!validationResult.isValid) {
      throw new Error(validationResult.errorMessage);
    }

    // Apply privacy settings to coordinates if needed
    const processedCoordinates = fuzzLocation(
      locationData.coordinates,
      locationData.privacySettings
    );

    // Create location document with processed coordinates
    const location = new this.Location({
      ...locationData,
      coordinates: processedCoordinates
    });

    return await location.save();
  }

  /**
   * Updates an existing location entry
   * Addresses requirements:
   * - Location Services - Core location services functionality
   * - Privacy Controls - Location privacy settings
   */
  async updateLocation(
    locationId: string,
    updateData: Partial<ILocation>
  ): Promise<ILocation> {
    // Validate update data if coordinates or privacy settings are included
    if (updateData.coordinates || updateData.privacySettings) {
      const currentLocation = await this.Location.findById(locationId);
      if (!currentLocation) {
        throw new Error('Location not found');
      }

      const validationData = {
        ...currentLocation.toObject(),
        ...updateData
      };

      const validationResult = validateLocation(validationData as ILocation);
      if (!validationResult.isValid) {
        throw new Error(validationResult.errorMessage);
      }

      // Process coordinates if they're being updated
      if (updateData.coordinates) {
        updateData.coordinates = fuzzLocation(
          updateData.coordinates,
          updateData.privacySettings || currentLocation.privacySettings
        );
      }
    }

    const updatedLocation = await this.Location.findByIdAndUpdate(
      locationId,
      { $set: updateData },
      { new: true, runValidators: true }
    );

    if (!updatedLocation) {
      throw new Error('Location not found');
    }

    return updatedLocation;
  }

  /**
   * Finds locations within specified radius considering privacy settings
   * Addresses requirements:
   * - Location-based Search - Geospatial search capabilities
   * - Privacy Controls - Location privacy settings
   */
  async findNearbyLocations(
    center: ICoordinates,
    radiusInKm: number,
    filters: {
      type?: LocationType;
      userId?: string;
      privacyLevel?: string;
      limit?: number;
    } = {}
  ): Promise<ILocation[]> {
    // Validate center coordinates
    if (!validateCoordinates(center)) {
      throw new Error('Invalid center coordinates');
    }

    // Generate bounding box for query optimization
    const boundingBox = generateBoundingBox(center, radiusInKm);

    // Build query with privacy and type filters
    const query: any = {
      'coordinates.latitude': { 
        $gte: boundingBox.minLat, 
        $lte: boundingBox.maxLat 
      },
      'coordinates.longitude': { 
        $gte: boundingBox.minLng, 
        $lte: boundingBox.maxLng 
      }
    };

    if (filters.type) {
      query.type = filters.type;
    }

    if (filters.userId) {
      query.userId = new Types.ObjectId(filters.userId);
    }

    if (filters.privacyLevel) {
      query['privacySettings.visibilityLevel'] = filters.privacyLevel;
    }

    // Execute geospatial query
    const locations = await this.Location.find(query)
      .limit(filters.limit || 100)
      .exec();

    // Post-process results to apply distance filtering
    return locations.filter(location => 
      calculateDistance(center, location.coordinates) <= radiusInKm
    );
  }

  /**
   * Retrieves all locations associated with a user
   * Addresses requirements:
   * - Location Services - Core location services functionality
   * - Privacy Controls - Location privacy settings
   */
  async getUserLocations(userId: string): Promise<ILocation[]> {
    if (!Types.ObjectId.isValid(userId)) {
      throw new Error('Invalid user ID');
    }

    return await this.Location.find({ 
      userId: new Types.ObjectId(userId) 
    }).exec();
  }

  /**
   * Deletes a location entry
   * Addresses requirement: Location Services - Core location services functionality
   */
  async deleteLocation(locationId: string): Promise<boolean> {
    if (!Types.ObjectId.isValid(locationId)) {
      throw new Error('Invalid location ID');
    }

    const result = await this.Location.findByIdAndDelete(locationId);
    return result !== null;
  }

  /**
   * Updates privacy settings for a location
   * Addresses requirement: Privacy Controls - Location privacy settings
   */
  async updatePrivacySettings(
    locationId: string,
    settings: IPrivacySettings
  ): Promise<ILocation> {
    // Validate privacy settings
    const validationResult = validatePrivacySettings(settings);
    if (!validationResult.isValid) {
      throw new Error(validationResult.errorMessage);
    }

    // Retrieve current location
    const location = await this.Location.findById(locationId);
    if (!location) {
      throw new Error('Location not found');
    }

    // Apply new privacy settings and fuzz coordinates if needed
    const updatedCoordinates = fuzzLocation(location.coordinates, settings);

    // Update location with new settings and coordinates
    const updatedLocation = await this.Location.findByIdAndUpdate(
      locationId,
      {
        $set: {
          privacySettings: settings,
          coordinates: updatedCoordinates
        }
      },
      { new: true, runValidators: true }
    );

    if (!updatedLocation) {
      throw new Error('Failed to update privacy settings');
    }

    return updatedLocation;
  }
}

export default LocationService;