/**
 * Human Tasks:
 * 1. Review coordinate precision requirements with location team
 * 2. Validate privacy settings thresholds with security team
 * 3. Confirm address validation rules with international requirements
 * 4. Review location type restrictions with business team
 * 5. Verify blur radius limits with privacy team
 */

// @ts-ignore validator@13.7.0
import validator from 'validator';
import { 
  ILocation, 
  ICoordinates, 
  IPrivacySettings, 
  LocationType 
} from '../interfaces/location.interface';
import { 
  validateCoordinates, 
  sanitizeInput 
} from '../utils/validation.utils';
import { ERROR_CODES } from '../constants/error-codes';

/**
 * Interface for location validation results
 * Requirement: Error Handling Matrix - Standardized validation responses
 */
interface LocationValidationResult {
  isValid: boolean;
  errorCode?: string;
  errorMessage?: string;
}

/**
 * Validates a complete location object including coordinates, address, and privacy settings
 * Requirements:
 * - Location Services - Location services validation
 * - Privacy Controls - Location privacy settings validation
 * - Data Protection Measures - Location data validation
 */
export const validateLocation = (location: ILocation): LocationValidationResult => {
  // Validate coordinates
  if (!location.coordinates || !validateCoordinates(
    location.coordinates.latitude,
    location.coordinates.longitude
  )) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.LOCATION_INVALID_COORDINATES,
      errorMessage: 'Invalid coordinates provided'
    };
  }

  // Validate address components
  const addressValidation = validateAddress(
    location.address,
    location.city,
    location.state,
    location.country,
    location.postalCode
  );
  if (!addressValidation.isValid) {
    return addressValidation;
  }

  // Validate location type
  if (!Object.values(LocationType).includes(location.type)) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      errorMessage: 'Invalid location type'
    };
  }

  // Validate privacy settings
  const privacyValidation = validatePrivacySettings(location.privacySettings);
  if (!privacyValidation.isValid) {
    return privacyValidation;
  }

  return { isValid: true };
};

/**
 * Validates location privacy settings configuration
 * Requirements:
 * - Privacy Controls - Privacy settings validation
 * - Data Protection Measures - Privacy configuration validation
 */
export const validatePrivacySettings = (settings: IPrivacySettings): LocationValidationResult => {
  // Validate visibility level
  const validVisibilityLevels = ['public', 'private', 'friends', 'limited'];
  if (!validVisibilityLevels.includes(settings.visibilityLevel)) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      errorMessage: 'Invalid visibility level'
    };
  }

  // Validate blur radius (in meters)
  if (typeof settings.blurRadius !== 'number' || 
      settings.blurRadius < 0 || 
      settings.blurRadius > 5000) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      errorMessage: 'Invalid blur radius'
    };
  }

  // Validate hide exact location flag
  if (typeof settings.hideExactLocation !== 'boolean') {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      errorMessage: 'Invalid hideExactLocation setting'
    };
  }

  return { isValid: true };
};

/**
 * Validates and sanitizes address components
 * Requirements:
 * - Location Services - Address validation
 * - Data Protection Measures - Address data sanitization
 */
export const validateAddress = (
  address: string,
  city: string,
  state: string,
  country: string,
  postalCode: string
): LocationValidationResult => {
  // Sanitize all address components
  const sanitizedAddress = sanitizeInput(address);
  const sanitizedCity = sanitizeInput(city);
  const sanitizedState = sanitizeInput(state);
  const sanitizedCountry = sanitizeInput(country);
  const sanitizedPostalCode = sanitizeInput(postalCode);

  // Validate required fields
  if (!sanitizedAddress || !sanitizedCity || !sanitizedCountry) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      errorMessage: 'Required address fields missing'
    };
  }

  // Validate address length
  if (sanitizedAddress.length < 5 || sanitizedAddress.length > 200) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      errorMessage: 'Invalid address length'
    };
  }

  // Validate city length and format
  if (sanitizedCity.length < 2 || sanitizedCity.length > 100 || 
      !validator.isAlpha(sanitizedCity.replace(/\s/g, ''))) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      errorMessage: 'Invalid city name'
    };
  }

  // Validate state if provided
  if (sanitizedState && (
    sanitizedState.length < 2 || 
    sanitizedState.length > 100 || 
    !validator.isAlphanumeric(sanitizedState.replace(/\s/g, ''))
  )) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      errorMessage: 'Invalid state name'
    };
  }

  // Validate country
  if (sanitizedCountry.length < 2 || 
      sanitizedCountry.length > 100 || 
      !validator.isAlpha(sanitizedCountry.replace(/\s/g, ''))) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      errorMessage: 'Invalid country name'
    };
  }

  // Validate postal code if provided
  if (sanitizedPostalCode && !validator.isPostalCode(sanitizedPostalCode, 'any')) {
    return {
      isValid: false,
      errorCode: ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      errorMessage: 'Invalid postal code'
    };
  }

  return { isValid: true };
};