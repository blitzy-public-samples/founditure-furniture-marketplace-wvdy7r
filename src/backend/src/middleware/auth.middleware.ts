// Human Tasks:
// 1. Configure JWT secrets and expiration times in environment variables
// 2. Set up Firebase project and obtain credentials
// 3. Configure rate limiting for token generation/verification
// 4. Set up monitoring for authentication failures
// 5. Configure user role permissions in production environment
// 6. Implement token revocation list if needed

// Third-party imports with version
import { Request, Response, NextFunction } from 'express'; // ^4.18.2

// Internal imports
import { verifyAccessToken, checkUserRole, validateFirebaseToken } from '../utils/auth.utils';
import { ERROR_CODES } from '../constants/error-codes';
import { UserRole } from '../interfaces/user.interface';

/**
 * Express middleware to authenticate incoming requests using JWT token
 * Requirement: Security Protocols - JWT token validation
 */
export const authenticateRequest = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Extract token from Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        error: ERROR_CODES.AUTH_UNAUTHORIZED,
        message: 'No token provided'
      });
      return;
    }

    const token = authHeader.split(' ')[1];

    // Verify the JWT token
    const decodedToken = await verifyAccessToken(token);

    // Attach user data to request object for downstream middleware
    req.user = {
      id: decodedToken.userId,
      email: decodedToken.email,
      role: decodedToken.role
    };

    next();
  } catch (error) {
    if (error.message === 'Token has expired') {
      res.status(401).json({
        error: ERROR_CODES.AUTH_TOKEN_EXPIRED,
        message: 'Token has expired'
      });
      return;
    }

    res.status(401).json({
      error: ERROR_CODES.AUTH_TOKEN_INVALID,
      message: 'Invalid token'
    });
  }
};

/**
 * Express middleware factory for role-based access control
 * Requirement: User authentication and authorization - Role-based authorization
 */
export const authorizeRoles = (allowedRoles: UserRole[]) => {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      // Ensure request is authenticated and user data is available
      if (!req.user) {
        res.status(401).json({
          error: ERROR_CODES.AUTH_UNAUTHORIZED,
          message: 'Authentication required'
        });
        return;
      }

      // Check if user has required role
      const hasRequiredRole = checkUserRole(req.user, allowedRoles);

      if (!hasRequiredRole) {
        res.status(403).json({
          error: ERROR_CODES.AUTH_UNAUTHORIZED,
          message: 'Insufficient permissions'
        });
        return;
      }

      next();
    } catch (error) {
      res.status(500).json({
        error: ERROR_CODES.SERVER_INTERNAL_ERROR,
        message: 'Role verification failed'
      });
    }
  };
};

/**
 * Express middleware to validate Firebase authentication tokens
 * Requirement: Security Protocols - Firebase token validation
 */
export const validateFirebaseAuth = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Extract Firebase token from request header
    const firebaseToken = req.headers['x-firebase-token'];

    if (!firebaseToken || typeof firebaseToken !== 'string') {
      res.status(401).json({
        error: ERROR_CODES.AUTH_UNAUTHORIZED,
        message: 'Firebase token required'
      });
      return;
    }

    // Validate the Firebase token
    const firebaseUser = await validateFirebaseToken(firebaseToken);

    // Attach Firebase user data to request
    req.firebaseUser = firebaseUser;

    next();
  } catch (error) {
    res.status(401).json({
      error: ERROR_CODES.AUTH_TOKEN_INVALID,
      message: 'Invalid Firebase token'
    });
  }
};

// Type declaration for Express Request
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        email: string;
        role: UserRole;
      };
      firebaseUser?: {
        uid: string;
        email: string;
        emailVerified: boolean;
        displayName?: string;
        photoURL?: string;
        phoneNumber?: string;
        customClaims?: Record<string, any>;
      };
    }
  }
}