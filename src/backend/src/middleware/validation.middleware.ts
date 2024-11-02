/**
 * Human Tasks:
 * 1. Review validation rules with security team
 * 2. Confirm error response format with API documentation
 * 3. Verify rate limiting thresholds with infrastructure team
 * 4. Review validation bypass rules for trusted clients
 * 5. Confirm validation logging requirements with monitoring team
 */

import { Request, Response, NextFunction } from 'express';
import {
  validateLoginCredentials,
  validateRegistrationData,
  validatePasswordReset,
  validatePasswordUpdate
} from '../validators/auth.validator';
import {
  validateFurnitureCreate,
  validateFurnitureUpdate,
  validateFurnitureStatus
} from '../validators/furniture.validator';
import { ERROR_CODES } from '../constants/error-codes';
import { ERROR_MESSAGES } from '../constants/messages';

/**
 * Interface for validation error response
 * Requirement: Input validation and sanitization
 */
interface ValidationError {
  code: string;
  message: string;
  details?: object;
}

/**
 * Handles validation errors and sends appropriate response
 * Requirements:
 * - Input validation and sanitization
 * - Data Protection Measures
 */
const handleValidationError = (error: ValidationError, res: Response): void => {
  res.status(400).json({
    success: false,
    error: {
      code: error.code,
      message: error.message,
      details: error.details
    }
  });
};

/**
 * Middleware for validating authentication requests
 * Requirements:
 * - Input validation and sanitization
 * - Security Controls
 * - Data Protection Measures
 */
export const validateAuthRequest = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { path } = req.route;
    const { body } = req;

    let validationResult;

    switch (path) {
      case '/login':
        validationResult = await validateLoginCredentials(
          body.email,
          body.password
        );
        break;

      case '/register':
        validationResult = await validateRegistrationData(body);
        break;

      case '/password/reset':
        validationResult = await validatePasswordReset(body.email);
        break;

      case '/password/update':
        validationResult = await validatePasswordUpdate(
          body.currentPassword,
          body.newPassword
        );
        break;

      default:
        return next();
    }

    if (!validationResult.isValid) {
      return handleValidationError({
        code: validationResult.errorCode || ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        message: validationResult.errorMessage || ERROR_MESSAGES.VALIDATION_REQUIRED_FIELD,
        details: body
      }, res);
    }

    // If validation includes sanitized data, attach it to the request
    if ('sanitizedData' in validationResult) {
      req.body = validationResult.sanitizedData;
    }

    return next();
  } catch (error) {
    return handleValidationError({
      code: ERROR_CODES.SERVER_INTERNAL_ERROR,
      message: 'Validation processing failed',
      details: { error: error.message }
    }, res);
  }
};

/**
 * Middleware for validating furniture-related requests
 * Requirements:
 * - Input validation and sanitization
 * - Data Protection Measures
 * - Security Controls
 */
export const validateFurnitureRequest = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { method, path } = req.route;
    const { body, params } = req;

    let validationResult;

    switch (method) {
      case 'POST':
        validationResult = await validateFurnitureCreate(body);
        break;

      case 'PUT':
      case 'PATCH':
        if (path.includes('/status')) {
          validationResult = await validateFurnitureStatus(
            body.status,
            params.id
          );
        } else {
          validationResult = await validateFurnitureUpdate(
            body,
            params.id
          );
        }
        break;

      default:
        return next();
    }

    if (!validationResult.isValid) {
      return handleValidationError({
        code: validationResult.errorCode || ERROR_CODES.VALIDATION_REQUIRED_FIELD,
        message: validationResult.errorMessage || ERROR_MESSAGES.VALIDATION_REQUIRED_FIELD,
        details: { body, params }
      }, res);
    }

    // If validation includes validated data, attach it to the request
    if (validationResult.validatedData) {
      req.body = validationResult.validatedData;
    }

    return next();
  } catch (error) {
    return handleValidationError({
      code: ERROR_CODES.SERVER_INTERNAL_ERROR,
      message: 'Validation processing failed',
      details: { error: error.message }
    }, res);
  }
};