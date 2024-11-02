/**
 * Human Tasks:
 * 1. Review furniture validation thresholds with product team
 * 2. Confirm image size and dimension limits with infrastructure team
 * 3. Verify material list with content moderation team
 * 4. Review location privacy settings with security team
 * 5. Validate furniture status transition rules with business team
 */

// @ts-ignore validator@13.7.0
import validator from 'validator';
// @ts-ignore joi@17.9.0
import Joi from 'joi';
import { 
  IFurniture, 
  FurnitureCategory, 
  FurnitureCondition, 
  FurnitureStatus 
} from '../interfaces/furniture.interface';
import { 
  validateCoordinates, 
  validateImageFile, 
  sanitizeInput 
} from '../utils/validation.utils';
import { ERROR_CODES } from '../constants/error-codes';

/**
 * Interface for furniture validation results
 * Requirement: Input validation and sanitization - Standardized validation responses
 */
export interface FurnitureValidationResult {
  isValid: boolean;
  errorCode?: string;
  errorMessage?: string;
  validatedData?: Partial<IFurniture>;
}

/**
 * Validation schema for furniture creation
 * Requirements:
 * - Input validation and sanitization
 * - Data Protection Measures
 */
const furnitureCreateSchema = Joi.object({
  title: Joi.string().min(3).max(100).required(),
  description: Joi.string().min(10).max(1000).required(),
  category: Joi.string().valid(...Object.values(FurnitureCategory)).required(),
  condition: Joi.string().valid(...Object.values(FurnitureCondition)).required(),
  dimensions: Joi.object({
    length: Joi.number().min(0).max(1000).required(),
    width: Joi.number().min(0).max(1000).required(),
    height: Joi.number().min(0).max(1000).required(),
    weight: Joi.number().min(0).max(5000).optional(),
    unit: Joi.string().valid('cm', 'in', 'm').required()
  }).required(),
  materials: Joi.array().items(Joi.string().min(2).max(50)).min(1).max(10),
  imageUrls: Joi.array().items(Joi.string().uri()).min(1).max(10),
  location: Joi.object({
    latitude: Joi.number().min(-90).max(90).required(),
    longitude: Joi.number().min(-180).max(180).required(),
    address: Joi.string().max(200).optional(),
    privacyLevel: Joi.string().valid('EXACT', 'APPROXIMATE', 'AREA').required()
  }).required(),
  pickupDetails: Joi.object({
    type: Joi.string().valid('PICKUP_WINDOW', 'BY_APPOINTMENT', 'FLEXIBLE', 'IMMEDIATE').required(),
    availableDays: Joi.array().items(Joi.string().valid('MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN')),
    timeWindow: Joi.string().pattern(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]-([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/),
    specialInstructions: Joi.string().max(500).optional(),
    assistanceRequired: Joi.boolean().required(),
    requiredEquipment: Joi.array().items(Joi.string()).max(5)
  }).required()
});

/**
 * Validates furniture creation data
 * Requirements:
 * - Input validation and sanitization
 * - Data Protection Measures
 * - Furniture listing management
 */
export const validateFurnitureCreate = async (
  furnitureData: Partial<IFurniture>
): Promise<FurnitureValidationResult> => {
  try {
    // Sanitize text inputs
    const sanitizedData = {
      ...furnitureData,
      title: sanitizeInput(furnitureData.title || ''),
      description: sanitizeInput(furnitureData.description || ''),
      materials: furnitureData.materials?.map(m => sanitizeInput(m)),
      pickupDetails: {
        ...furnitureData.pickupDetails,
        specialInstructions: sanitizeInput(furnitureData.pickupDetails?.specialInstructions || '')
      }
    };

    // Validate against schema
    const { error, value } = furnitureCreateSchema.validate(sanitizedData, { 
      abortEarly: false,
      stripUnknown: true 
    });

    if (error) {
      return {
        isValid: false,
        errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        errorMessage: error.details[0].message
      };
    }

    // Validate location coordinates
    if (!validateCoordinates(value.location.latitude, value.location.longitude)) {
      return {
        isValid: false,
        errorCode: ERROR_CODES.FURNITURE_INVALID_LOCATION,
        errorMessage: 'Invalid location coordinates'
      };
    }

    // Set initial status
    value.status = FurnitureStatus.AVAILABLE;

    // Set expiration date (30 days from creation)
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);
    value.expiresAt = expiresAt;

    return {
      isValid: true,
      validatedData: value
    };
  } catch (error) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.FURNITURE_CREATION_FAILED,
      errorMessage: 'Failed to validate furniture data'
    };
  }
};

/**
 * Validates furniture update data
 * Requirements:
 * - Input validation and sanitization
 * - Data Protection Measures
 * - Furniture listing management
 */
export const validateFurnitureUpdate = async (
  furnitureData: Partial<IFurniture>,
  furnitureId: string
): Promise<FurnitureValidationResult> => {
  try {
    // Validate furniture ID format
    if (!validator.isUUID(furnitureId)) {
      return {
        isValid: false,
        errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        errorMessage: 'Invalid furniture ID format'
      };
    }

    // Create update schema by making all fields optional
    const updateSchema = furnitureCreateSchema.fork(
      Object.keys(furnitureCreateSchema.describe().keys),
      (schema) => schema.optional()
    );

    // Sanitize text inputs if provided
    const sanitizedData = {
      ...furnitureData,
      title: furnitureData.title ? sanitizeInput(furnitureData.title) : undefined,
      description: furnitureData.description ? sanitizeInput(furnitureData.description) : undefined,
      materials: furnitureData.materials?.map(m => sanitizeInput(m)),
      pickupDetails: furnitureData.pickupDetails ? {
        ...furnitureData.pickupDetails,
        specialInstructions: sanitizeInput(furnitureData.pickupDetails.specialInstructions || '')
      } : undefined
    };

    // Validate against schema
    const { error, value } = updateSchema.validate(sanitizedData, {
      abortEarly: false,
      stripUnknown: true
    });

    if (error) {
      return {
        isValid: false,
        errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        errorMessage: error.details[0].message
      };
    }

    // Validate location coordinates if provided
    if (value.location) {
      if (!validateCoordinates(value.location.latitude, value.location.longitude)) {
        return {
          isValid: false,
          errorCode: ERROR_CODES.FURNITURE_INVALID_LOCATION,
          errorMessage: 'Invalid location coordinates'
        };
      }
    }

    return {
      isValid: true,
      validatedData: value
    };
  } catch (error) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.FURNITURE_UPDATE_FAILED,
      errorMessage: 'Failed to validate furniture update data'
    };
  }
};

/**
 * Validates furniture status updates
 * Requirements:
 * - Input validation and sanitization
 * - Data Protection Measures
 * - Furniture listing management
 */
export const validateFurnitureStatus = async (
  status: FurnitureStatus,
  furnitureId: string
): Promise<FurnitureValidationResult> => {
  try {
    // Validate furniture ID format
    if (!validator.isUUID(furnitureId)) {
      return {
        isValid: false,
        errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        errorMessage: 'Invalid furniture ID format'
      };
    }

    // Validate status enum value
    if (!Object.values(FurnitureStatus).includes(status)) {
      return {
        isValid: false,
        errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        errorMessage: 'Invalid furniture status'
      };
    }

    // Define valid status transitions
    const validTransitions: Record<FurnitureStatus, FurnitureStatus[]> = {
      [FurnitureStatus.AVAILABLE]: [FurnitureStatus.PENDING, FurnitureStatus.EXPIRED, FurnitureStatus.REMOVED],
      [FurnitureStatus.PENDING]: [FurnitureStatus.CLAIMED, FurnitureStatus.AVAILABLE, FurnitureStatus.REMOVED],
      [FurnitureStatus.CLAIMED]: [FurnitureStatus.REMOVED],
      [FurnitureStatus.EXPIRED]: [FurnitureStatus.AVAILABLE, FurnitureStatus.REMOVED],
      [FurnitureStatus.REMOVED]: []
    };

    // Check if transition is valid (will be checked against current status in service layer)
    if (!Object.values(validTransitions).some(transitions => transitions.includes(status))) {
      return {
        isValid: false,
        errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        errorMessage: 'Invalid status transition'
      };
    }

    return {
      isValid: true,
      validatedData: { status }
    };
  } catch (error) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.FURNITURE_UPDATE_FAILED,
      errorMessage: 'Failed to validate furniture status update'
    };
  }
};