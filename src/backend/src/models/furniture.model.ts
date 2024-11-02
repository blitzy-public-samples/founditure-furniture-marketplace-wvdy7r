/**
 * Human Tasks:
 * 1. Review and adjust expiration time configuration with product team
 * 2. Configure geospatial index settings with DevOps team
 * 3. Verify AI metadata schema with ML team
 * 4. Set up monitoring for database indexes
 * 5. Review data retention policies with legal team
 */

// External dependencies
import mongoose, { Schema, Model } from 'mongoose'; // ^7.0.0
import { Point } from 'geojson'; // ^7946.0.10

// Internal dependencies
import { IFurniture, FurnitureCategory, FurnitureCondition, FurnitureStatus } from '../interfaces/furniture.interface';
import { mongoConnection } from '../config/database';
import { validateCoordinates, validateImageFile } from '../utils/validation.utils';

/**
 * Mongoose schema for furniture dimensions
 * Addresses requirement: Furniture listing management - Core data model
 */
const DimensionsSchema = new Schema({
  length: { type: Number, required: true },
  width: { type: Number, required: true },
  height: { type: Number, required: true },
  weight: { type: Number, required: true },
  unit: { type: String, required: true, enum: ['cm', 'in', 'ft'] }
}, { _id: false });

/**
 * Mongoose schema for AI-generated metadata
 * Addresses requirement: AI/ML Infrastructure - Integration with AI-generated metadata
 */
const AIMetadataSchema = new Schema({
  style: { type: String },
  confidenceScore: { type: Number, min: 0, max: 1 },
  detectedMaterials: [{ type: String }],
  suggestedCategories: [{ type: String }],
  similarItems: [{ type: String }],
  qualityAssessment: {
    overallScore: { type: Number, min: 0, max: 10 },
    detectedIssues: [{ type: String }],
    recommendations: [{ type: String }]
  }
}, { _id: false });

/**
 * Mongoose schema for pickup details
 * Addresses requirement: Furniture listing management - Core data model
 */
const PickupDetailsSchema = new Schema({
  type: {
    type: String,
    required: true,
    enum: ['PICKUP_WINDOW', 'BY_APPOINTMENT', 'FLEXIBLE', 'IMMEDIATE']
  },
  availableDays: [{ type: String }],
  timeWindow: { type: String },
  specialInstructions: { type: String },
  assistanceRequired: { type: Boolean, default: false },
  requiredEquipment: [{ type: String }]
}, { _id: false });

/**
 * Mongoose schema for furniture items
 * Addresses requirements:
 * - Furniture listing management - Core data model
 * - Location-based search - Geospatial indexing
 * - AI/ML Infrastructure - Integration with AI-generated metadata
 */
const FurnitureSchema = new Schema<IFurniture>({
  userId: {
    type: Schema.Types.ObjectId,
    required: true,
    ref: 'User',
    index: true
  },
  title: {
    type: String,
    required: true,
    trim: true,
    minlength: 3,
    maxlength: 100,
    index: true
  },
  description: {
    type: String,
    required: true,
    trim: true,
    minlength: 10,
    maxlength: 1000
  },
  category: {
    type: String,
    required: true,
    enum: Object.values(FurnitureCategory),
    index: true
  },
  condition: {
    type: String,
    required: true,
    enum: Object.values(FurnitureCondition)
  },
  dimensions: {
    type: DimensionsSchema,
    required: true
  },
  materials: [{
    type: String,
    trim: true
  }],
  imageUrls: {
    type: [{
      type: String,
      required: true,
      validate: {
        validator: validateImageFile,
        message: 'Invalid image file'
      }
    }],
    required: true,
    validate: {
      validator: (v: string[]) => v.length > 0 && v.length <= 10,
      message: 'At least one image is required, maximum 10 images allowed'
    }
  },
  aiMetadata: {
    type: AIMetadataSchema,
    required: true
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      required: true
    },
    coordinates: {
      type: [Number],
      required: true,
      validate: {
        validator: (coords: number[]) => validateCoordinates(coords[1], coords[0]),
        message: 'Invalid coordinates'
      }
    }
  },
  status: {
    type: String,
    required: true,
    enum: Object.values(FurnitureStatus),
    default: FurnitureStatus.AVAILABLE,
    index: true
  },
  pickupDetails: {
    type: PickupDetailsSchema,
    required: true
  },
  createdAt: {
    type: Date,
    required: true,
    default: Date.now,
    immutable: true
  },
  updatedAt: {
    type: Date,
    required: true,
    default: Date.now
  },
  expiresAt: {
    type: Date,
    required: true,
    index: true
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

/**
 * Geospatial index for location-based queries
 * Addresses requirement: Location-based search - Geospatial indexing
 */
FurnitureSchema.index({ location: '2dsphere' });

/**
 * Compound index for efficient listing queries
 * Addresses requirement: Furniture listing management - Core data model
 */
FurnitureSchema.index({ status: 1, category: 1, createdAt: -1 });

/**
 * Pre-save middleware to validate location coordinates
 * Addresses requirement: Location-based search - Data validation
 */
FurnitureSchema.pre('save', function(next) {
  if (this.isModified('location')) {
    const coordinates = this.location.coordinates;
    if (!validateCoordinates(coordinates[1], coordinates[0])) {
      next(new Error('Invalid coordinates'));
      return;
    }
  }
  next();
});

/**
 * Pre-save middleware to update timestamps and set expiration
 * Addresses requirement: Furniture listing management - Data lifecycle
 */
FurnitureSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  
  if (this.isNew) {
    this.createdAt = this.updatedAt;
    // Set expiration date to 30 days from creation
    this.expiresAt = new Date(this.createdAt.getTime() + (30 * 24 * 60 * 60 * 1000));
  }
  
  next();
});

/**
 * Virtual for calculating distance from a point
 * Addresses requirement: Location-based search - Distance calculation
 */
FurnitureSchema.virtual('distance').get(function() {
  return this._distance;
});

/**
 * Method to check if furniture item is available
 * Addresses requirement: Furniture listing management - Status checks
 */
FurnitureSchema.methods.isAvailable = function(): boolean {
  return this.status === FurnitureStatus.AVAILABLE && 
         new Date() < this.expiresAt;
};

/**
 * Method to update furniture status
 * Addresses requirement: Furniture listing management - Status updates
 */
FurnitureSchema.methods.updateStatus = function(newStatus: FurnitureStatus): void {
  this.status = newStatus;
  this.updatedAt = new Date();
};

/**
 * Static method to find furniture within radius
 * Addresses requirement: Location-based search - Geospatial queries
 */
FurnitureSchema.statics.findNearby = function(
  coordinates: [number, number],
  radiusInKm: number,
  options: any = {}
): Promise<IFurniture[]> {
  return this.find({
    location: {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates: coordinates
        },
        $maxDistance: radiusInKm * 1000
      }
    },
    status: FurnitureStatus.AVAILABLE,
    expiresAt: { $gt: new Date() },
    ...options.filters
  })
  .limit(options.limit || 50)
  .select(options.select || '')
  .sort(options.sort || { createdAt: -1 });
};

// Create and export the Furniture model
const FurnitureModel: Model<IFurniture> = mongoConnection.model<IFurniture>('Furniture', FurnitureSchema);

export default FurnitureModel;