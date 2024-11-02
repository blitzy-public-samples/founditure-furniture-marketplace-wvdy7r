/**
 * Human Tasks:
 * 1. Review error code categories with security team for completeness
 * 2. Validate HTTP status code mappings with API documentation
 * 3. Ensure error codes are documented in API specifications
 * 4. Verify error message templates with localization team
 * 5. Confirm system error thresholds with DevOps team
 */

// @ts-ignore http-status-codes@2.2.0
import { StatusCodes } from 'http-status-codes';
import { ERROR_MESSAGES } from './messages';

// Global error prefix for all system error codes
export const ERROR_PREFIX = 'ERR';

/**
 * Type definition for error code categories
 * Requirement: Error Handling Strategy - Standardized error categories
 */
export type ErrorCodeCategory = 
  | 'AUTH'
  | 'VALIDATION'
  | 'FURNITURE'
  | 'UPLOAD'
  | 'MESSAGE'
  | 'POINTS'
  | 'LOCATION'
  | 'NETWORK'
  | 'SERVER'
  | 'DATABASE'
  | 'CACHE'
  | 'QUEUE'
  | 'SECURITY';

/**
 * Interface for error message template parameters
 * Requirement: Error Handling Strategy - Dynamic error messages
 */
export interface ErrorMessageParams {
  field?: string;
  value?: string;
  limit?: number;
  type?: string;
}

/**
 * Enumeration of all possible error codes in the system
 * Requirements:
 * - Error Handling Strategy - Standardized error codes
 * - Security Controls - Security-related error codes
 * - System Health Metrics - System monitoring error codes
 */
export enum ERROR_CODES {
  // Authentication errors
  AUTH_INVALID_CREDENTIALS = 'AUTH_INVALID_CREDENTIALS',
  AUTH_TOKEN_EXPIRED = 'AUTH_TOKEN_EXPIRED',
  AUTH_TOKEN_INVALID = 'AUTH_TOKEN_INVALID',
  AUTH_USER_NOT_FOUND = 'AUTH_USER_NOT_FOUND',
  AUTH_UNAUTHORIZED = 'AUTH_UNAUTHORIZED',

  // Validation errors
  VALIDATION_REQUIRED_FIELD = 'VALIDATION_REQUIRED_FIELD',
  VALIDATION_INVALID_EMAIL = 'VALIDATION_INVALID_EMAIL',
  VALIDATION_INVALID_PASSWORD = 'VALIDATION_INVALID_PASSWORD',
  VALIDATION_INVALID_PHONE = 'VALIDATION_INVALID_PHONE',

  // Furniture-related errors
  FURNITURE_CREATION_FAILED = 'FURNITURE_CREATION_FAILED',
  FURNITURE_UPDATE_FAILED = 'FURNITURE_UPDATE_FAILED',
  FURNITURE_DELETE_FAILED = 'FURNITURE_DELETE_FAILED',
  FURNITURE_NOT_FOUND = 'FURNITURE_NOT_FOUND',
  FURNITURE_INVALID_LOCATION = 'FURNITURE_INVALID_LOCATION',

  // Upload errors
  UPLOAD_IMAGE_FAILED = 'UPLOAD_IMAGE_FAILED',
  UPLOAD_SIZE_EXCEEDED = 'UPLOAD_SIZE_EXCEEDED',
  UPLOAD_FORMAT_INVALID = 'UPLOAD_FORMAT_INVALID',

  // Messaging errors
  MESSAGE_SEND_FAILED = 'MESSAGE_SEND_FAILED',
  MESSAGE_RECIPIENT_OFFLINE = 'MESSAGE_RECIPIENT_OFFLINE',
  MESSAGE_INVALID_CONTENT = 'MESSAGE_INVALID_CONTENT',

  // Points system errors
  POINTS_UPDATE_FAILED = 'POINTS_UPDATE_FAILED',
  POINTS_INVALID_AMOUNT = 'POINTS_INVALID_AMOUNT',

  // Location errors
  LOCATION_UPDATE_FAILED = 'LOCATION_UPDATE_FAILED',
  LOCATION_INVALID_COORDINATES = 'LOCATION_INVALID_COORDINATES',
  LOCATION_PERMISSION_DENIED = 'LOCATION_PERMISSION_DENIED',

  // Network errors
  NETWORK_CONNECTION_ERROR = 'NETWORK_CONNECTION_ERROR',
  NETWORK_TIMEOUT = 'NETWORK_TIMEOUT',

  // Server errors
  SERVER_INTERNAL_ERROR = 'SERVER_INTERNAL_ERROR',
  SERVER_MAINTENANCE = 'SERVER_MAINTENANCE',

  // Infrastructure errors
  DATABASE_CONNECTION_ERROR = 'DATABASE_CONNECTION_ERROR',
  CACHE_CONNECTION_ERROR = 'CACHE_CONNECTION_ERROR',
  QUEUE_CONNECTION_ERROR = 'QUEUE_CONNECTION_ERROR',

  // Security errors
  RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
  SECURITY_INVALID_REQUEST = 'SECURITY_INVALID_REQUEST',
  SECURITY_BLOCKED_IP = 'SECURITY_BLOCKED_IP'
}

/**
 * Returns a formatted error message for a given error code with optional parameters
 * Requirement: Error Handling Strategy - Dynamic error message generation
 * @param errorCode The error code from ERROR_CODES enum
 * @param params Optional parameters for message template
 * @returns Formatted error message string
 */
export const getErrorMessage = (errorCode: ERROR_CODES, params?: ErrorMessageParams): string => {
  if (!(errorCode in ERROR_MESSAGES)) {
    return `${ERROR_PREFIX}_UNKNOWN_ERROR`;
  }

  const messageTemplate = ERROR_MESSAGES[errorCode as keyof typeof ERROR_MESSAGES];
  if (!params) {
    return messageTemplate;
  }

  return Object.entries(params).reduce((message, [key, value]) => {
    const placeholder = `{${key}}`;
    return message.replace(placeholder, String(value));
  }, messageTemplate);
};

/**
 * Checks if an error code represents a system-level error
 * Requirement: System Health Metrics - System error detection
 * @param errorCode The error code to check
 * @returns boolean indicating if the error is system-level
 */
export const isSystemError = (errorCode: ERROR_CODES): boolean => {
  const systemPrefixes = ['SERVER_', 'DATABASE_', 'CACHE_', 'QUEUE_'];
  return systemPrefixes.some(prefix => errorCode.startsWith(prefix));
};

/**
 * Maps error codes to appropriate HTTP status codes
 * Requirement: Error Handling Strategy - HTTP status code mapping
 */
export const ERROR_HTTP_STATUS_MAP: Record<ErrorCodeCategory, number> = {
  AUTH: StatusCodes.UNAUTHORIZED,
  VALIDATION: StatusCodes.BAD_REQUEST,
  FURNITURE: StatusCodes.BAD_REQUEST,
  UPLOAD: StatusCodes.BAD_REQUEST,
  MESSAGE: StatusCodes.BAD_REQUEST,
  POINTS: StatusCodes.BAD_REQUEST,
  LOCATION: StatusCodes.BAD_REQUEST,
  NETWORK: StatusCodes.SERVICE_UNAVAILABLE,
  SERVER: StatusCodes.INTERNAL_SERVER_ERROR,
  DATABASE: StatusCodes.INTERNAL_SERVER_ERROR,
  CACHE: StatusCodes.INTERNAL_SERVER_ERROR,
  QUEUE: StatusCodes.INTERNAL_SERVER_ERROR,
  SECURITY: StatusCodes.FORBIDDEN
};