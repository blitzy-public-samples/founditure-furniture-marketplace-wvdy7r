// @ts-ignore joi@17.9.0
import Joi from 'joi';
import { IMessage, MessageType, MessageStatus, AttachmentType } from '../interfaces/message.interface';
import { ERROR_MESSAGES } from '../constants/messages';
import { sanitizeInput } from '../utils/validation.utils';

/**
 * Interface for message validation results
 * Addresses requirement: Real-time messaging system - Validation response structure
 */
export interface MessageValidationResult {
  isValid: boolean;
  errorMessage: string;
  errorCode: string;
}

/**
 * Joi validation schemas for message-related data
 * Addresses requirements:
 * - Real-time messaging system - Data validation schemas
 * - Content moderation - Message content validation rules
 */
export const messageValidationSchemas = {
  content: Joi.string()
    .min(1)
    .max(1000)
    .required()
    .messages({
      'string.empty': ERROR_MESSAGES.VALIDATION_REQUIRED_FIELD.replace('{field}', 'content'),
      'string.min': 'Message content must be at least 1 character long',
      'string.max': 'Message content cannot exceed 1000 characters'
    }),

  thread: Joi.object({
    senderId: Joi.string().uuid().required(),
    receiverId: Joi.string().uuid().required(),
    furnitureId: Joi.string().uuid().required()
  }).messages({
    'string.uuid': 'Invalid ID format',
    'any.required': 'Required field missing'
  }),

  attachment: Joi.object({
    type: Joi.string().valid(...Object.values(AttachmentType)).required(),
    size: Joi.number().max(10 * 1024 * 1024).required(), // 10MB limit
    mimeType: Joi.string().pattern(/^(image|application)\/(jpeg|png|pdf|doc|docx)$/).required(),
    filename: Joi.string().max(255).required()
  }).messages({
    'number.max': 'File size exceeds maximum limit of 10MB',
    'string.pattern.base': 'Invalid file type'
  })
};

/**
 * Validates and sanitizes message content
 * Addresses requirements:
 * - Real-time messaging system - Content validation
 * - Content moderation - Content filtering and sanitization
 * @param content Message content to validate
 */
export const validateMessageContent = (content: string): MessageValidationResult => {
  // Initial validation result
  const result: MessageValidationResult = {
    isValid: false,
    errorMessage: '',
    errorCode: ''
  };

  try {
    // Sanitize input first
    const sanitizedContent = sanitizeInput(content);

    // Validate using Joi schema
    const validation = messageValidationSchemas.content.validate(sanitizedContent);

    if (validation.error) {
      result.errorMessage = validation.error.message;
      result.errorCode = 'MESSAGE_CONTENT_INVALID';
      return result;
    }

    // Check for prohibited content (profanity, spam patterns, etc.)
    const prohibitedPatterns = [
      /\b(spam|scam|hack)\b/i,
      /(https?:\/\/[^\s]+)/g, // Basic URL pattern
      /\b([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})\b/ // Email pattern
    ];

    for (const pattern of prohibitedPatterns) {
      if (pattern.test(sanitizedContent)) {
        result.errorMessage = 'Message contains prohibited content';
        result.errorCode = 'MESSAGE_CONTENT_PROHIBITED';
        return result;
      }
    }

    result.isValid = true;
  } catch (error) {
    result.errorMessage = 'Message validation failed';
    result.errorCode = 'MESSAGE_VALIDATION_ERROR';
  }

  return result;
};

/**
 * Validates message thread creation parameters
 * Addresses requirements:
 * - Real-time messaging system - Thread validation
 * - Privacy controls - User interaction validation
 */
export const validateMessageThread = (
  senderId: string,
  receiverId: string,
  furnitureId: string
): MessageValidationResult => {
  const result: MessageValidationResult = {
    isValid: false,
    errorMessage: '',
    errorCode: ''
  };

  try {
    // Validate using Joi schema
    const validation = messageValidationSchemas.thread.validate({
      senderId,
      receiverId,
      furnitureId
    });

    if (validation.error) {
      result.errorMessage = validation.error.message;
      result.errorCode = 'MESSAGE_THREAD_INVALID';
      return result;
    }

    // Ensure sender and receiver are different
    if (senderId === receiverId) {
      result.errorMessage = 'Cannot create message thread with yourself';
      result.errorCode = 'MESSAGE_THREAD_SELF';
      return result;
    }

    result.isValid = true;
  } catch (error) {
    result.errorMessage = 'Thread validation failed';
    result.errorCode = 'THREAD_VALIDATION_ERROR';
  }

  return result;
};

/**
 * Validates message attachments
 * Addresses requirements:
 * - Real-time messaging system - Attachment validation
 * - Content moderation - File type and size validation
 */
export const validateMessageAttachment = (attachment: {
  type: AttachmentType;
  size: number;
  mimeType: string;
  filename: string;
}): MessageValidationResult => {
  const result: MessageValidationResult = {
    isValid: false,
    errorMessage: '',
    errorCode: ''
  };

  try {
    // Validate using Joi schema
    const validation = messageValidationSchemas.attachment.validate(attachment);

    if (validation.error) {
      result.errorMessage = validation.error.message;
      result.errorCode = 'MESSAGE_ATTACHMENT_INVALID';
      return result;
    }

    // Additional MIME type validation for specific attachment types
    const allowedMimeTypes = {
      [AttachmentType.IMAGE]: ['image/jpeg', 'image/png'],
      [AttachmentType.DOCUMENT]: ['application/pdf', 'application/doc', 'application/docx']
    };

    if (
      allowedMimeTypes[attachment.type] &&
      !allowedMimeTypes[attachment.type].includes(attachment.mimeType)
    ) {
      result.errorMessage = 'Invalid file type for attachment';
      result.errorCode = 'MESSAGE_ATTACHMENT_TYPE_INVALID';
      return result;
    }

    // Validate filename length and characters
    const filenameRegex = /^[a-zA-Z0-9-_. ]+$/;
    if (!filenameRegex.test(attachment.filename)) {
      result.errorMessage = 'Invalid filename format';
      result.errorCode = 'MESSAGE_ATTACHMENT_FILENAME_INVALID';
      return result;
    }

    result.isValid = true;
  } catch (error) {
    result.errorMessage = 'Attachment validation failed';
    result.errorCode = 'ATTACHMENT_VALIDATION_ERROR';
  }

  return result;
};