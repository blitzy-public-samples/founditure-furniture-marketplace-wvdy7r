/**
 * Human Tasks:
 * 1. Review and validate error codes with security team
 * 2. Ensure message templates comply with i18n standards
 * 3. Verify achievement messages match marketing guidelines
 * 4. Confirm notification templates with UX team
 * 5. Review success messages for consistency across platforms
 */

import { ACHIEVEMENT_THRESHOLDS } from './points';

// Error code mappings for system-wide error handling
// Requirement: Error Handling Strategy - Standardized error codes
export const ERROR_CODES_MAP = {
  AUTH_ERROR: 'E001',
  VALIDATION_ERROR: 'E002',
  RESOURCE_ERROR: 'E003',
  NETWORK_ERROR: 'E004',
  POINTS_ERROR: 'E005'
} as const;

// Error message templates for different scenarios
// Requirement: Error Handling Strategy - User-friendly error messages
export const ERROR_MESSAGES = {
  AUTH_INVALID_CREDENTIALS: '[E001] Invalid email or password',
  AUTH_TOKEN_EXPIRED: '[E001] Your session has expired. Please log in again',
  AUTH_UNAUTHORIZED: '[E001] You are not authorized to perform this action',
  VALIDATION_REQUIRED_FIELD: '[E002] Field {field} is required',
  VALIDATION_INVALID_EMAIL: '[E002] Please enter a valid email address',
  FURNITURE_NOT_FOUND: '[E003] Furniture listing not found',
  FURNITURE_INVALID_LOCATION: '[E003] Invalid location coordinates provided',
  UPLOAD_IMAGE_FAILED: '[E003] Failed to upload image. Please try again',
  MESSAGE_SEND_FAILED: '[E004] Failed to send message. Please try again',
  POINTS_UPDATE_FAILED: '[E005] Failed to update points balance',
  NETWORK_CONNECTION_ERROR: '[E004] Connection error. Please check your internet connection'
} as const;

// Real-time notification message templates
// Requirement: Real-time messaging - User notification templates
export const NOTIFICATION_MESSAGES = {
  NEW_MESSAGE: 'New message from {sender}',
  FURNITURE_CLAIMED: '{user} has claimed your furniture listing',
  POINTS_EARNED: 'You earned {points} points for {action}',
  ACHIEVEMENT_UNLOCKED: 'Achievement unlocked: {achievement}',
  LEVEL_UP: "Congratulations! You've reached level {level}"
} as const;

// Success message templates for user actions
// Requirement: Error Handling Strategy - Success confirmations
export const SUCCESS_MESSAGES = {
  FURNITURE_CREATED: 'Furniture listing created successfully',
  MESSAGE_SENT: 'Message sent successfully',
  PROFILE_UPDATED: 'Profile updated successfully',
  LOCATION_UPDATED: 'Location updated successfully',
  POINTS_AWARDED: 'Points awarded successfully'
} as const;

// Achievement message templates based on points thresholds
// Requirement: Points system - Achievement notifications
export const ACHIEVEMENT_MESSAGES = {
  NOVICE_RECOVERER: "You've become a Novice Recoverer!",
  INTERMEDIATE_RECOVERER: "You've advanced to Intermediate Recoverer!",
  EXPERT_RECOVERER: "You're now an Expert Recoverer!",
  MASTER_RECOVERER: 'Congratulations on becoming a Master Recoverer!',
  LEGENDARY_RECOVERER: "You've achieved Legendary Recoverer status!"
} as const;

// Interface for message template parameters
// Requirement: Real-time messaging - Dynamic message parameters
export interface MessageParams {
  sender?: string;
  user?: string;
  points?: number;
  action?: string;
  achievement?: string;
  level?: number;
  field?: string;
}

/**
 * Formats a message template by replacing placeholders with provided parameters
 * Requirement: Real-time messaging - Dynamic message formatting
 * @param template The message template string containing placeholders
 * @param params Object containing values to replace placeholders
 * @returns Formatted message with parameters replaced
 */
export const formatMessage = (template: string, params: MessageParams): string => {
  if (!template) {
    return '';
  }

  return Object.entries(params).reduce((message, [key, value]) => {
    const placeholder = `{${key}}`;
    return message.replace(placeholder, String(value));
  }, template);
};