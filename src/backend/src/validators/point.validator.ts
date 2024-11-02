// @ts-ignore joi@17.6.0
import Joi from 'joi';
import { Types } from 'mongoose';
import { 
  IPointTransaction, 
  LeaderboardPeriod, 
  AchievementStatus 
} from '../interfaces/point.interface';
import { 
  BASE_POINTS, 
  MULTIPLIERS, 
  TIME_CONSTRAINTS 
} from '../constants/points';
import { sanitizeInput } from '../utils/validation.utils';

/**
 * Human Tasks:
 * 1. Review and adjust validation thresholds with product team
 * 2. Configure rate limiting for point transactions
 * 3. Verify achievement claim validation rules with game design team
 * 4. Set up monitoring for suspicious point accumulation patterns
 * 5. Review leaderboard query performance with DB team
 */

/**
 * Schema for validating point transaction requests
 * Requirement: Points-based gamification engine - Input validation
 */
const pointTransactionSchema = Joi.object({
  userId: Joi.string()
    .required()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .messages({
      'string.pattern.base': 'Invalid user ID format',
      'any.required': 'User ID is required'
    }),
  actionType: Joi.string()
    .required()
    .valid(...Object.keys(BASE_POINTS))
    .messages({
      'any.only': 'Invalid action type',
      'any.required': 'Action type is required'
    }),
  points: Joi.number()
    .required()
    .min(0)
    .max(1000)
    .messages({
      'number.base': 'Points must be a number',
      'number.min': 'Points cannot be negative',
      'number.max': 'Points exceed maximum allowed value'
    }),
  multiplier: Joi.number()
    .optional()
    .min(1)
    .max(MULTIPLIERS.SPECIAL_EVENT)
    .default(1)
    .messages({
      'number.min': 'Multiplier cannot be less than 1',
      'number.max': 'Multiplier exceeds maximum allowed value'
    }),
  metadata: Joi.object()
    .optional()
    .default({})
});

/**
 * Schema for validating achievement claim requests
 * Requirement: Points system and leaderboards - Achievement validation
 */
const achievementClaimSchema = Joi.object({
  userId: Joi.string()
    .required()
    .pattern(/^[0-9a-fA-F]{24}$/),
  achievementId: Joi.string()
    .required()
    .min(3)
    .max(50),
  status: Joi.string()
    .required()
    .valid(...Object.values(AchievementStatus)),
  claimTimestamp: Joi.date()
    .required()
    .max('now')
    .messages({
      'date.max': 'Claim timestamp cannot be in the future'
    })
});

/**
 * Schema for validating leaderboard query parameters
 * Requirement: Points system and leaderboards - Leaderboard validation
 */
const leaderboardQuerySchema = Joi.object({
  period: Joi.string()
    .required()
    .valid(...Object.values(LeaderboardPeriod))
    .messages({
      'any.only': 'Invalid leaderboard period'
    }),
  limit: Joi.number()
    .optional()
    .min(1)
    .max(100)
    .default(20)
    .messages({
      'number.min': 'Limit must be at least 1',
      'number.max': 'Limit cannot exceed 100'
    }),
  offset: Joi.number()
    .optional()
    .min(0)
    .default(0),
  filters: Joi.object({
    level: Joi.number().optional().min(1),
    region: Joi.string().optional().min(2).max(50)
  }).optional()
});

/**
 * Validates a point transaction request
 * Requirement: Points-based gamification engine - Transaction validation
 */
export const validatePointTransaction = async (transaction: Partial<IPointTransaction>): Promise<ValidationResult> => {
  try {
    // Validate against schema
    const { error, value } = pointTransactionSchema.validate(transaction, { abortEarly: false });
    if (error) {
      return {
        isValid: false,
        errorCode: 'INVALID_POINT_TRANSACTION',
        errorMessage: error.details[0].message
      };
    }

    // Verify action type exists in BASE_POINTS
    if (!BASE_POINTS[value.actionType]) {
      return {
        isValid: false,
        errorCode: 'INVALID_ACTION_TYPE',
        errorMessage: 'Action type not recognized'
      };
    }

    // Validate point value against BASE_POINTS range
    const basePointValue = BASE_POINTS[value.actionType];
    if (value.points > basePointValue * MULTIPLIERS.SPECIAL_EVENT) {
      return {
        isValid: false,
        errorCode: 'INVALID_POINT_VALUE',
        errorMessage: 'Point value exceeds maximum allowed for action type'
      };
    }

    // Verify multiplier value
    if (value.multiplier > MULTIPLIERS.SPECIAL_EVENT) {
      return {
        isValid: false,
        errorCode: 'INVALID_MULTIPLIER',
        errorMessage: 'Multiplier exceeds maximum allowed value'
      };
    }

    // Sanitize metadata fields
    if (value.metadata) {
      Object.keys(value.metadata).forEach(key => {
        if (typeof value.metadata[key] === 'string') {
          value.metadata[key] = sanitizeInput(value.metadata[key]);
        }
      });
    }

    return { isValid: true };
  } catch (error) {
    return {
      isValid: false,
      errorCode: 'VALIDATION_ERROR',
      errorMessage: 'Error validating point transaction'
    };
  }
};

/**
 * Validates an achievement claim request
 * Requirement: Points system and leaderboards - Achievement validation
 */
export const validateAchievementClaim = async (claimRequest: any): Promise<ValidationResult> => {
  try {
    // Validate against schema
    const { error, value } = achievementClaimSchema.validate(claimRequest, { abortEarly: false });
    if (error) {
      return {
        isValid: false,
        errorCode: 'INVALID_ACHIEVEMENT_CLAIM',
        errorMessage: error.details[0].message
      };
    }

    // Verify achievement ID exists
    if (!Types.ObjectId.isValid(value.achievementId)) {
      return {
        isValid: false,
        errorCode: 'INVALID_ACHIEVEMENT_ID',
        errorMessage: 'Invalid achievement ID format'
      };
    }

    // Check if achievement status transition is valid
    if (value.status === AchievementStatus.CLAIMED && !value.claimTimestamp) {
      return {
        isValid: false,
        errorCode: 'INVALID_CLAIM_TIMESTAMP',
        errorMessage: 'Claim timestamp required for claimed achievements'
      };
    }

    // Validate claim timestamp is within allowed window
    const claimWindow = new Date();
    claimWindow.setMinutes(claimWindow.getMinutes() - TIME_CONSTRAINTS.QUICK_RESPONSE_MINUTES);
    if (value.claimTimestamp < claimWindow) {
      return {
        isValid: false,
        errorCode: 'EXPIRED_CLAIM_WINDOW',
        errorMessage: 'Achievement claim window has expired'
      };
    }

    return { isValid: true };
  } catch (error) {
    return {
      isValid: false,
      errorCode: 'VALIDATION_ERROR',
      errorMessage: 'Error validating achievement claim'
    };
  }
};

/**
 * Validates leaderboard query parameters
 * Requirement: Points system and leaderboards - Leaderboard validation
 */
export const validateLeaderboardQuery = (queryParams: any): ValidationResult => {
  try {
    // Validate against schema
    const { error, value } = leaderboardQuerySchema.validate(queryParams, { abortEarly: false });
    if (error) {
      return {
        isValid: false,
        errorCode: 'INVALID_LEADERBOARD_QUERY',
        errorMessage: error.details[0].message
      };
    }

    // Validate time period
    if (!Object.values(LeaderboardPeriod).includes(value.period)) {
      return {
        isValid: false,
        errorCode: 'INVALID_TIME_PERIOD',
        errorMessage: 'Invalid leaderboard time period'
      };
    }

    // Validate pagination parameters
    if (value.limit * value.offset > 1000) {
      return {
        isValid: false,
        errorCode: 'PAGINATION_LIMIT_EXCEEDED',
        errorMessage: 'Pagination range exceeds maximum allowed'
      };
    }

    // Sanitize filter values
    if (value.filters) {
      if (value.filters.region) {
        value.filters.region = sanitizeInput(value.filters.region);
      }
    }

    return { isValid: true };
  } catch (error) {
    return {
      isValid: false,
      errorCode: 'VALIDATION_ERROR',
      errorMessage: 'Error validating leaderboard query'
    };
  }
};

/**
 * Interface for validation result object
 */
interface ValidationResult {
  isValid: boolean;
  errorCode?: string;
  errorMessage?: string;
}