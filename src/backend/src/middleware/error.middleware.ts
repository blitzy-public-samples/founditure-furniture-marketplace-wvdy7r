/**
 * Human Tasks:
 * 1. Configure error monitoring thresholds in CloudWatch
 * 2. Set up error alerting in monitoring system
 * 3. Review error response sanitization rules with security team
 * 4. Configure rate limiting thresholds for error endpoints
 * 5. Set up error tracking integration (e.g., Sentry)
 */

// Third-party imports with versions
import { Request, Response, NextFunction } from 'express'; // ^4.18.0
import { StatusCodes } from 'http-status-codes'; // ^2.2.0

// Internal imports
import { ERROR_CODES, getErrorMessage } from '../constants/error-codes';
import { error as logError } from '../utils/logger.utils';

/**
 * Interface for standardized error response
 * Requirement: Error Handling Strategy - Standardized error responses
 */
interface ErrorResponse {
  code: string;
  message: string;
  data?: Record<string, any>;
}

/**
 * Custom error class for application-specific errors
 * Requirement: Error Handling Strategy - Custom error handling
 */
export class AppError extends Error {
  public readonly code: string;
  public readonly statusCode: number;
  public readonly data?: Record<string, any>;

  constructor(
    code: string,
    statusCode: number,
    message: string,
    data?: Record<string, any>
  ) {
    super(message);
    this.code = code;
    this.statusCode = statusCode;
    this.data = data;
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Transforms various error types into standardized AppError format
 * Requirements:
 * - Error Handling Strategy - Error transformation
 * - Security Controls - Error sanitization
 */
const transformError = (error: Error): AppError => {
  // Handle known AppError instances
  if (error instanceof AppError) {
    return error;
  }

  // Handle validation errors (e.g., from express-validator)
  if ('errors' in error && Array.isArray((error as any).errors)) {
    return new AppError(
      ERROR_CODES.VALIDATION_REQUIRED_FIELD,
      StatusCodes.BAD_REQUEST,
      getErrorMessage(ERROR_CODES.VALIDATION_REQUIRED_FIELD),
      { validationErrors: (error as any).errors }
    );
  }

  // Handle JWT authentication errors
  if (error.name === 'JsonWebTokenError') {
    return new AppError(
      ERROR_CODES.AUTH_TOKEN_INVALID,
      StatusCodes.UNAUTHORIZED,
      getErrorMessage(ERROR_CODES.AUTH_TOKEN_INVALID)
    );
  }

  // Handle JWT expiration errors
  if (error.name === 'TokenExpiredError') {
    return new AppError(
      ERROR_CODES.AUTH_TOKEN_EXPIRED,
      StatusCodes.UNAUTHORIZED,
      getErrorMessage(ERROR_CODES.AUTH_TOKEN_EXPIRED)
    );
  }

  // Handle network timeouts
  if (error.name === 'TimeoutError') {
    return new AppError(
      ERROR_CODES.NETWORK_TIMEOUT,
      StatusCodes.GATEWAY_TIMEOUT,
      getErrorMessage(ERROR_CODES.NETWORK_TIMEOUT)
    );
  }

  // Handle database connection errors
  if (error.name === 'SequelizeConnectionError') {
    return new AppError(
      ERROR_CODES.DATABASE_CONNECTION_ERROR,
      StatusCodes.SERVICE_UNAVAILABLE,
      getErrorMessage(ERROR_CODES.DATABASE_CONNECTION_ERROR)
    );
  }

  // Default to internal server error for unknown errors
  return new AppError(
    ERROR_CODES.SERVER_INTERNAL_ERROR,
    StatusCodes.INTERNAL_SERVER_ERROR,
    getErrorMessage(ERROR_CODES.SERVER_INTERNAL_ERROR)
  );
};

/**
 * Formats error response while ensuring sensitive information is not leaked
 * Requirements:
 * - Security Controls - Prevent sensitive information leakage
 * - Error Handling Strategy - Standardized error responses
 */
const formatErrorResponse = (error: AppError): ErrorResponse => {
  const response: ErrorResponse = {
    code: error.code,
    message: error.message
  };

  // Only include additional data in development environment
  if (process.env.NODE_ENV === 'development' && error.data) {
    response.data = error.data;
  }

  return response;
};

/**
 * Express middleware for handling all application errors
 * Requirements:
 * - Error Handling Strategy - Centralized error handling
 * - System Health Metrics - Error tracking
 * - Security Controls - Error handling security
 */
const errorHandler = (
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Transform error to standard format
  const transformedError = transformError(err);

  // Log error details
  logError('Request error', {
    error: {
      code: transformedError.code,
      message: transformedError.message,
      stack: transformedError.stack
    },
    request: {
      method: req.method,
      url: req.url,
      params: req.params,
      query: req.query,
      body: req.body,
      headers: {
        'user-agent': req.get('user-agent'),
        'x-request-id': req.get('x-request-id')
      }
    }
  });

  // Format error response
  const errorResponse = formatErrorResponse(transformedError);

  // Send error response
  res.status(transformedError.statusCode).json(errorResponse);
};

// Export error handler middleware as default
export default errorHandler;