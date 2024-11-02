/**
 * Human Tasks:
 * 1. Review password complexity requirements with security team
 * 2. Verify email validation patterns with compliance team
 * 3. Confirm phone number validation rules for international support
 * 4. Review user data sanitization rules with security team
 * 5. Validate registration field requirements with product team
 */

import { validateEmail, validatePassword, validatePhoneNumber, sanitizeInput } from '../utils/validation.utils';
import { ERROR_CODES } from '../constants/error-codes';
import { ERROR_MESSAGES } from '../constants/messages';
import { IUser, IUserAuth } from '../interfaces/user.interface';
import { Request } from 'express';

/**
 * Interface for login validation result
 * Requirement: Input validation for user authentication flows
 */
export interface LoginValidationResult {
  isValid: boolean;
  errorCode?: string;
  errorMessage?: string;
}

/**
 * Interface for registration validation result
 * Requirement: Input validation for user registration
 */
export interface RegistrationValidationResult {
  isValid: boolean;
  errorCode?: string;
  errorMessage?: string;
  sanitizedData?: Partial<IUser>;
}

/**
 * Validates user login credentials
 * Requirements:
 * - Input validation for user authentication flows
 * - Security Controls - Input validation and sanitization
 * @param email User email
 * @param password User password
 */
export const validateLoginCredentials = async (
  email: string,
  password: string
): Promise<LoginValidationResult> => {
  // Sanitize email input
  const sanitizedEmail = sanitizeInput(email);

  // Validate email format
  if (!validateEmail(sanitizedEmail)) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_INVALID_EMAIL,
      errorMessage: ERROR_MESSAGES.VALIDATION_INVALID_EMAIL
    };
  }

  // Validate password format
  if (!validatePassword(password)) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_INVALID_PASSWORD,
      errorMessage: ERROR_MESSAGES.VALIDATION_INVALID_PASSWORD
    };
  }

  return {
    isValid: true
  };
};

/**
 * Validates user registration data
 * Requirements:
 * - Input validation for user registration
 * - Data Protection Measures - Validation layer for user credentials
 * @param registrationData User registration data
 */
export const validateRegistrationData = async (
  registrationData: Partial<IUser>
): Promise<RegistrationValidationResult> => {
  const sanitizedData: Partial<IUser> = {};
  const errors: string[] = [];

  // Validate and sanitize email
  if (!registrationData.email) {
    errors.push('Email is required');
  } else {
    sanitizedData.email = sanitizeInput(registrationData.email);
    if (!validateEmail(sanitizedData.email)) {
      return {
        isValid: false,
        errorCode: ERROR_CODES.VALIDATION_INVALID_EMAIL,
        errorMessage: ERROR_MESSAGES.VALIDATION_INVALID_EMAIL
      };
    }
  }

  // Validate and sanitize full name
  if (!registrationData.fullName) {
    errors.push('Full name is required');
  } else {
    sanitizedData.fullName = sanitizeInput(registrationData.fullName);
    if (sanitizedData.fullName.length < 2) {
      return {
        isValid: false,
        errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        errorMessage: ERROR_MESSAGES.VALIDATION_REQUIRED_FIELD.replace('{field}', 'full name')
      };
    }
  }

  // Validate phone number if provided
  if (registrationData.phoneNumber) {
    sanitizedData.phoneNumber = sanitizeInput(registrationData.phoneNumber);
    if (!validatePhoneNumber(sanitizedData.phoneNumber)) {
      return {
        isValid: false,
        errorCode: ERROR_CODES.VALIDATION_INVALID_PHONE,
        errorMessage: ERROR_MESSAGES.VALIDATION_INVALID_PHONE
      };
    }
  }

  // Validate password if provided in auth object
  if (registrationData.auth && 'passwordHash' in registrationData.auth) {
    const password = (registrationData.auth as IUserAuth).passwordHash;
    if (!validatePassword(password)) {
      return {
        isValid: false,
        errorCode: ERROR_CODES.VALIDATION_INVALID_PASSWORD,
        errorMessage: ERROR_MESSAGES.VALIDATION_INVALID_PASSWORD
      };
    }
  }

  if (errors.length > 0) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      errorMessage: errors.join(', ')
    };
  }

  return {
    isValid: true,
    sanitizedData
  };
};

/**
 * Validates password reset request data
 * Requirements:
 * - Security Controls - Input validation for password reset
 * - Data Protection Measures - Validation layer for sensitive data
 * @param email User email for password reset
 */
export const validatePasswordReset = async (
  email: string
): Promise<LoginValidationResult> => {
  // Sanitize email input
  const sanitizedEmail = sanitizeInput(email);

  // Validate email format
  if (!validateEmail(sanitizedEmail)) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_INVALID_EMAIL,
      errorMessage: ERROR_MESSAGES.VALIDATION_INVALID_EMAIL
    };
  }

  return {
    isValid: true
  };
};

/**
 * Validates password update data
 * Requirements:
 * - Security Controls - Input validation for password updates
 * - Data Protection Measures - Validation layer for sensitive data
 * @param currentPassword Current user password
 * @param newPassword New password to set
 */
export const validatePasswordUpdate = async (
  currentPassword: string,
  newPassword: string
): Promise<LoginValidationResult> => {
  // Validate current password format
  if (!validatePassword(currentPassword)) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_INVALID_PASSWORD,
      errorMessage: ERROR_MESSAGES.VALIDATION_INVALID_PASSWORD
    };
  }

  // Validate new password format
  if (!validatePassword(newPassword)) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_INVALID_PASSWORD,
      errorMessage: ERROR_MESSAGES.VALIDATION_INVALID_PASSWORD
    };
  }

  // Ensure new password is different from current
  if (currentPassword === newPassword) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_INVALID_PASSWORD,
      errorMessage: 'New password must be different from current password'
    };
  }

  return {
    isValid: true
  };
};