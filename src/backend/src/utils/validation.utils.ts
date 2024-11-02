/**
 * Human Tasks:
 * 1. Review validation thresholds with security team
 * 2. Confirm image file size limits with infrastructure team
 * 3. Verify phone number validation patterns with international requirements
 * 4. Review password complexity requirements with security policy
 * 5. Validate coordinate precision requirements with location team
 */

// @ts-ignore validator@13.7.0
import validator from 'validator';
// @ts-ignore xss@1.0.11
import xss from 'xss';
import { ERROR_CODES } from '../constants/error-codes';
import { ERROR_MESSAGES } from '../constants/messages';

/**
 * Interface for validation result object
 * Requirement: Error Handling Matrix - Standardized validation responses
 */
export interface ValidationResult {
  isValid: boolean;
  errorCode?: string;
  errorMessage?: string;
}

/**
 * Interface for image validation options
 * Requirement: Data Protection Measures - File upload validation
 */
export interface ImageValidationOptions {
  maxSize: number;
  allowedTypes: string[];
  dimensions: {
    minWidth: number;
    minHeight: number;
    maxWidth?: number;
    maxHeight?: number;
  };
}

/**
 * Validates email format and checks for common email patterns
 * Requirements:
 * - Input validation and sanitization - Email validation
 * - Security Controls - Email format verification
 * @param email Email string to validate
 * @returns Boolean indicating if email is valid
 */
export const validateEmail = (email: string): boolean => {
  if (!email || typeof email !== 'string') {
    return false;
  }

  // Trim whitespace and convert to lowercase
  const normalizedEmail = email.trim().toLowerCase();

  // Check length constraints
  if (normalizedEmail.length < 5 || normalizedEmail.length > 254) {
    return false;
  }

  // Validate email format using validator library
  return validator.isEmail(normalizedEmail, {
    allow_utf8_local_part: false,
    require_tld: true,
    allow_ip_domain: false
  });
};

/**
 * Validates password strength and security requirements
 * Requirements:
 * - Input validation and sanitization - Password validation
 * - Security Controls - Password complexity verification
 * @param password Password string to validate
 * @returns Boolean indicating if password meets requirements
 */
export const validatePassword = (password: string): boolean => {
  if (!password || typeof password !== 'string') {
    return false;
  }

  // Check minimum length (8 characters)
  if (password.length < 8) {
    return false;
  }

  // Check for required character types
  const hasUppercase = /[A-Z]/.test(password);
  const hasLowercase = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(password);

  return hasUppercase && hasLowercase && hasNumber && hasSpecial;
};

/**
 * Validates phone number format and international standards
 * Requirements:
 * - Input validation and sanitization - Phone number validation
 * - Data Protection Measures - Phone format verification
 * @param phoneNumber Phone number string to validate
 * @returns Boolean indicating if phone number is valid
 */
export const validatePhoneNumber = (phoneNumber: string): boolean => {
  if (!phoneNumber || typeof phoneNumber !== 'string') {
    return false;
  }

  // Remove non-numeric characters
  const normalizedPhone = phoneNumber.replace(/\D/g, '');

  // Check length constraints (minimum 10, maximum 15 digits)
  if (normalizedPhone.length < 10 || normalizedPhone.length > 15) {
    return false;
  }

  // Validate using validator library's mobile phone check
  return validator.isMobilePhone(normalizedPhone, 'any', {
    strictMode: true
  });
};

/**
 * Validates geographic coordinates for furniture locations
 * Requirements:
 * - Input validation and sanitization - Coordinate validation
 * - Data Protection Measures - Location data validation
 * @param latitude Latitude coordinate
 * @param longitude Longitude coordinate
 * @returns Boolean indicating if coordinates are valid
 */
export const validateCoordinates = (latitude: number, longitude: number): boolean => {
  if (typeof latitude !== 'number' || typeof longitude !== 'number') {
    return false;
  }

  // Check latitude range (-90 to 90)
  if (latitude < -90 || latitude > 90) {
    return false;
  }

  // Check longitude range (-180 to 180)
  if (longitude < -180 || longitude > 180) {
    return false;
  }

  // Validate coordinate precision (maximum 6 decimal places)
  const latString = latitude.toString();
  const lonString = longitude.toString();
  const latDecimals = latString.includes('.') ? latString.split('.')[1].length : 0;
  const lonDecimals = lonString.includes('.') ? lonString.split('.')[1].length : 0;

  return latDecimals <= 6 && lonDecimals <= 6;
};

/**
 * Sanitizes user input to prevent XSS and injection attacks
 * Requirements:
 * - Input validation and sanitization - Input sanitization
 * - Security Controls - XSS prevention
 * @param input Input string to sanitize
 * @returns Sanitized input string
 */
export const sanitizeInput = (input: string): string => {
  if (!input || typeof input !== 'string') {
    return '';
  }

  // Trim whitespace
  let sanitized = input.trim();

  // Apply XSS filter
  sanitized = xss(sanitized, {
    whiteList: {}, // Disable all HTML tags
    stripIgnoreTag: true,
    stripIgnoreTagBody: ['script', 'style']
  });

  // Escape special characters
  sanitized = validator.escape(sanitized);

  return sanitized;
};

/**
 * Validates image file type, size, and dimensions
 * Requirements:
 * - Input validation and sanitization - File validation
 * - Data Protection Measures - Image upload validation
 * @param file File object to validate
 * @returns Boolean indicating if image file is valid
 */
export const validateImageFile = (file: any): boolean => {
  if (!file || typeof file !== 'object') {
    return false;
  }

  // Default validation options
  const options: ImageValidationOptions = {
    maxSize: 10 * 1024 * 1024, // 10MB
    allowedTypes: ['image/jpeg', 'image/png', 'image/webp'],
    dimensions: {
      minWidth: 200,
      minHeight: 200,
      maxWidth: 4096,
      maxHeight: 4096
    }
  };

  // Check file size
  if (file.size > options.maxSize) {
    return false;
  }

  // Validate mime type
  if (!options.allowedTypes.includes(file.type)) {
    return false;
  }

  // Check image dimensions (if available)
  if (file.width && file.height) {
    const { dimensions } = options;
    if (
      file.width < dimensions.minWidth ||
      file.height < dimensions.minHeight ||
      (dimensions.maxWidth && file.width > dimensions.maxWidth) ||
      (dimensions.maxHeight && file.height > dimensions.maxHeight)
    ) {
      return false;
    }
  }

  // Verify file integrity
  if (!file.buffer || !Buffer.isBuffer(file.buffer)) {
    return false;
  }

  return true;
};