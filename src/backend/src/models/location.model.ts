// mongoose v7.x
import { Schema, model, Document, Model } from 'mongoose';
// mongoose-geojson-schema v2.2.4
import 'mongoose-geojson-schema';
import { ILocation, LocationType } from '../interfaces/location.interface';
import { validateCoordinates } from '../utils/geo.utils';

/**
 * HUMAN TASKS:
 * 1. Ensure mongoose and mongoose-geojson-schema packages are installed with correct versions
 * 2. Configure MongoDB indexes for geospatial queries
 * 3. Set up environment variables for default privacy settings
 * 4. Review and adjust privacy radius constants based on regional requirements
 */

// Constants for location validation and privacy
const DEFAULT_PRIVACY_SETTINGS = {
  visibilityLevel: 'public',
  blurRadius: 0.5, // km
  hideExactLocation: false
};

const MAX_SEARCH_RADIUS_KM = 50;
const MIN_SEARCH_RADIUS_KM = 0.1;

/**
 * Mongoose schema for location data
 * Addresses requirements:
 * - Location Services - Core location services functionality
 * - Privacy Controls - Location privacy settings
 * - Location-based Search - Geospatial search capabilities
 */
const LocationSchema = new Schema<ILocation>({
  userId: {
    type: Schema.Types.ObjectId,
    required: true,
    ref: 'User',
    index: true
  },
  coordinates: {
    type: {
      latitude: {
        type: Number,
        required: true,
        min: -90,
        max: 90
      },
      longitude: {
        type: Number,
        required: true,
        min: -180,
        max: 180
      },
      accuracy: {
        type: Number,
        min: 0
      },
      altitude: Number
    },
    required: true,
    index: '2dsphere'
  },
  address: {
    type: String,
    required: true,
    trim: true
  },
  city: {
    type: String,
    required: true,
    trim: true
  },
  state: {
    type: String,
    required: true,
    trim: true
  },
  country: {
    type: String,
    required: true,
    trim: true
  },
  postalCode: {
    type: String,
    required: true,
    trim: true
  },
  type: {
    type: String,
    enum: Object.values(LocationType),
    required: true,
    index: true
  },
  privacySettings: {
    visibilityLevel: {
      type: String,
      enum: ['public', 'semi-private', 'private'],
      default: DEFAULT_PRIVACY_SETTINGS.visibilityLevel
    },
    blurRadius: {
      type: Number,
      min: 0,
      default: DEFAULT_PRIVACY_SETTINGS.blurRadius
    },
    hideExactLocation: {
      type: Boolean,
      default: DEFAULT_PRIVACY_SETTINGS.hideExactLocation
    }
  }
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc, ret) {
      ret.id = ret._id;
      delete ret._id;
      delete ret.__v;
      // Apply privacy settings when converting to JSON
      if (ret.privacySettings.hideExactLocation) {
        ret.coordinates.latitude = Number(ret.coordinates.latitude.toFixed(3));
        ret.coordinates.longitude = Number(ret.coordinates.longitude.toFixed(3));
      }
    }
  }
});

/**
 * Pre-save middleware to validate coordinates
 * Addresses requirement: Location Services - Core location services functionality
 */
LocationSchema.pre('save', async function(next) {
  if (!validateCoordinates(this.coordinates)) {
    throw new Error('Invalid coordinates provided');
  }
  next();
});

/**
 * Interface for Location model with static methods
 */
interface ILocationModel extends Model<ILocation> {
  findNearby(center: ILocation['coordinates'], radiusInKm: number, options?: {
    type?: LocationType;
    limit?: number;
    privacyLevel?: string;
  }): Promise<ILocation[]>;
}

/**
 * Static method to find locations within a radius
 * Addresses requirement: Location-based Search - Geospatial search capabilities
 */
LocationSchema.static('findNearby', async function(
  center: ILocation['coordinates'],
  radiusInKm: number,
  options: {
    type?: LocationType;
    limit?: number;
    privacyLevel?: string;
  } = {}
): Promise<ILocation[]> {
  // Validate input parameters
  if (!validateCoordinates(center)) {
    throw new Error('Invalid center coordinates provided');
  }

  if (radiusInKm < MIN_SEARCH_RADIUS_KM || radiusInKm > MAX_SEARCH_RADIUS_KM) {
    throw new Error(`Radius must be between ${MIN_SEARCH_RADIUS_KM} and ${MAX_SEARCH_RADIUS_KM} kilometers`);
  }

  // Build geospatial query
  const query: any = {
    coordinates: {
      $nearSphere: {
        $geometry: {
          type: 'Point',
          coordinates: [center.longitude, center.latitude]
        },
        $maxDistance: radiusInKm * 1000 // Convert to meters
      }
    }
  };

  // Apply type filter if specified
  if (options.type) {
    query.type = options.type;
  }

  // Apply privacy filter
  if (options.privacyLevel) {
    query['privacySettings.visibilityLevel'] = options.privacyLevel;
  }

  // Execute query with optional limit
  return this.find(query)
    .limit(options.limit || 100)
    .exec();
});

// Create indexes for efficient querying
LocationSchema.index({ coordinates: '2dsphere' });
LocationSchema.index({ userId: 1 });
LocationSchema.index({ type: 1 });
LocationSchema.index({ 'privacySettings.visibilityLevel': 1 });
LocationSchema.index({ createdAt: 1 });

// Export the Location model
const Location = model<ILocation, ILocationModel>('Location', LocationSchema);
export default Location;