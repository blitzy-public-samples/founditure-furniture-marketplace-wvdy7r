/**
 * Human Tasks:
 * 1. Review password complexity requirements with security team
 * 2. Verify phone number validation patterns for international support
 * 3. Confirm user preference validation rules with product team
 * 4. Review privacy settings validation thresholds with security team
 * 5. Validate user role transition rules with business team
 */

// @ts-ignore express-validator@7.0.0
import { body, validationResult } from 'express-validator';
import {
  IUser,
  IUserPreferences,
  UserRole,
  UserStatus
} from '../interfaces/user.interface';
import {
  validateEmail,
  validatePassword,
  validatePhoneNumber,
  sanitizeInput
} from '../utils/validation.utils';
import { ERROR_CODES } from '../constants/error-codes';

/**
 * Interface for user validation results
 * Requirement: Data Protection Measures - Input validation results
 */
export interface UserValidationResult {
  isValid: boolean;
  errors: ValidationError[];
}

/**
 * Interface for validation error details
 * Requirement: Data Protection Measures - Validation error reporting
 */
export interface ValidationError {
  field: string;
  code: ERROR_CODES;
  message: string;
}

/**
 * Validates user registration data
 * Requirements:
 * - User authentication and authorization - Input validation
 * - Data Protection Measures - Input validation and sanitization
 * @param registrationData User registration data object
 */
export const validateUserRegistration = async (
  registrationData: Partial<IUser>
): Promise<UserValidationResult> => {
  const errors: ValidationError[] = [];

  // Required fields validation
  if (!registrationData.email) {
    errors.push({
      field: 'email',
      code: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      message: 'Email is required'
    });
  } else if (!validateEmail(registrationData.email)) {
    errors.push({
      field: 'email',
      code: ERROR_CODES.VALIDATION_INVALID_EMAIL,
      message: 'Invalid email format'
    });
  }

  // Password validation
  if (!registrationData.auth?.passwordHash) {
    errors.push({
      field: 'password',
      code: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      message: 'Password is required'
    });
  } else if (!validatePassword(registrationData.auth.passwordHash)) {
    errors.push({
      field: 'password',
      code: ERROR_CODES.VALIDATION_INVALID_PASSWORD,
      message: 'Password does not meet security requirements'
    });
  }

  // Phone number validation (if provided)
  if (registrationData.phoneNumber && !validatePhoneNumber(registrationData.phoneNumber)) {
    errors.push({
      field: 'phoneNumber',
      code: ERROR_CODES.VALIDATION_INVALID_PHONE,
      message: 'Invalid phone number format'
    });
  }

  // Sanitize user input fields
  if (registrationData.fullName) {
    registrationData.fullName = sanitizeInput(registrationData.fullName);
  }
  if (registrationData.username) {
    registrationData.username = sanitizeInput(registrationData.username);
  }

  return {
    isValid: errors.length === 0,
    errors
  };
};

/**
 * Validates user profile update data
 * Requirements:
 * - Privacy controls - User data validation
 * - Data Protection Measures - Input sanitization
 * @param updateData User profile update data
 */
export const validateUserUpdate = async (
  updateData: Partial<IUser>
): Promise<UserValidationResult> => {
  const errors: ValidationError[] = [];

  // Email validation if being updated
  if (updateData.email && !validateEmail(updateData.email)) {
    errors.push({
      field: 'email',
      code: ERROR_CODES.VALIDATION_INVALID_EMAIL,
      message: 'Invalid email format'
    });
  }

  // Phone number validation if being updated
  if (updateData.phoneNumber && !validatePhoneNumber(updateData.phoneNumber)) {
    errors.push({
      field: 'phoneNumber',
      code: ERROR_CODES.VALIDATION_INVALID_PHONE,
      message: 'Invalid phone number format'
    });
  }

  // Validate user role if being updated
  if (updateData.role && !Object.values(UserRole).includes(updateData.role)) {
    errors.push({
      field: 'role',
      code: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      message: 'Invalid user role'
    });
  }

  // Validate user status if being updated
  if (updateData.status && !Object.values(UserStatus).includes(updateData.status)) {
    errors.push({
      field: 'status',
      code: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      message: 'Invalid user status'
    });
  }

  // Sanitize updateable fields
  if (updateData.fullName) {
    updateData.fullName = sanitizeInput(updateData.fullName);
  }
  if (updateData.username) {
    updateData.username = sanitizeInput(updateData.username);
  }

  return {
    isValid: errors.length === 0,
    errors
  };
};

/**
 * Validates user preference settings
 * Requirements:
 * - Privacy controls - Preference validation
 * - Data Protection Measures - Input validation
 * @param preferences User preference data
 */
export const validateUserPreferences = async (
  preferences: Partial<IUserPreferences>
): Promise<UserValidationResult> => {
  const errors: ValidationError[] = [];

  // Validate notification settings
  if (preferences.notifications) {
    const { notifications } = preferences;
    if (typeof notifications.email !== 'boolean' ||
        typeof notifications.push !== 'boolean' ||
        typeof notifications.sms !== 'boolean') {
      errors.push({
        field: 'notifications',
        code: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        message: 'Invalid notification settings format'
      });
    }
  }

  // Validate privacy settings
  if (preferences.privacySettings) {
    const { privacySettings } = preferences;
    const validVisibilityLevels = ['public', 'private', 'friends'];
    
    if (!validVisibilityLevels.includes(privacySettings.profileVisibility)) {
      errors.push({
        field: 'privacySettings.profileVisibility',
        code: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        message: 'Invalid profile visibility setting'
      });
    }

    if (typeof privacySettings.locationSharing !== 'boolean') {
      errors.push({
        field: 'privacySettings.locationSharing',
        code: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        message: 'Invalid location sharing setting'
      });
    }

    if (!validVisibilityLevels.includes(privacySettings.activityVisibility)) {
      errors.push({
        field: 'privacySettings.activityVisibility',
        code: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        message: 'Invalid activity visibility setting'
      });
    }
  }

  // Validate search radius
  if (preferences.searchRadius !== undefined) {
    if (typeof preferences.searchRadius !== 'number' ||
        preferences.searchRadius < 1 ||
        preferences.searchRadius > 100) {
      errors.push({
        field: 'searchRadius',
        code: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        message: 'Search radius must be between 1 and 100 kilometers'
      });
    }
  }

  // Validate theme selection
  if (preferences.theme && !['light', 'dark', 'system'].includes(preferences.theme)) {
    errors.push({
      field: 'theme',
      code: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      message: 'Invalid theme selection'
    });
  }

  return {
    isValid: errors.length === 0,
    errors
  };
};

/**
 * Validates password change request data
 * Requirements:
 * - User authentication and authorization - Password validation
 * - Data Protection Measures - Password security
 * @param currentPassword Current password string
 * @param newPassword New password string
 */
export const validatePasswordChange = async (
  currentPassword: string,
  newPassword: string
): Promise<UserValidationResult> => {
  const errors: ValidationError[] = [];

  // Validate current password presence
  if (!currentPassword) {
    errors.push({
      field: 'currentPassword',
      code: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      message: 'Current password is required'
    });
  }

  // Validate new password strength
  if (!validatePassword(newPassword)) {
    errors.push({
      field: 'newPassword',
      code: ERROR_CODES.VALIDATION_INVALID_PASSWORD,
      message: 'New password does not meet security requirements'
    });
  }

  // Ensure new password differs from current
  if (currentPassword === newPassword) {
    errors.push({
      field: 'newPassword',
      code: ERROR_CODES.VALIDATION_INVALID_PASSWORD,
      message: 'New password must be different from current password'
    });
  }

  return {
    isValid: errors.length === 0,
    errors
  };
};