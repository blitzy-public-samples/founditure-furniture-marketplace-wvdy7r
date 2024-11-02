// Human Tasks:
// 1. Configure JWT secrets and expiration times in environment variables
// 2. Set up Firebase project and obtain credentials
// 3. Configure rate limiting for token generation/verification
// 4. Set up monitoring for authentication failures
// 5. Configure user role permissions in production environment
// 6. Implement token revocation list if needed

// Third-party imports with versions
import jwt from 'jsonwebtoken'; // ^9.0.0
import { Request } from 'express'; // ^4.18.2

// Internal imports
import { auth as firebaseAdmin } from '../config/firebase';
import { IUser, UserRole } from '../interfaces/user.interface';
import { verifyPassword, hashPassword, generateSecureToken } from './encryption.utils';

// Types for authentication
interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

interface TokenPayload {
  userId: string;
  email: string;
  role: UserRole;
}

// Requirement: 7.3.1 Network Security - JWT token generation
export async function generateAuthTokens(user: IUser): Promise<AuthTokens> {
  try {
    // Create token payload with essential user data
    const payload: TokenPayload = {
      userId: user.id.toString(),
      email: user.email,
      role: user.role
    };

    // Generate access token with shorter expiration
    const accessToken = jwt.sign(payload, process.env.JWT_SECRET!, {
      expiresIn: process.env.JWT_EXPIRES_IN || '1h',
      algorithm: 'HS256'
    });

    // Generate refresh token with longer expiration
    const refreshToken = jwt.sign(payload, process.env.JWT_REFRESH_SECRET!, {
      expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
      algorithm: 'HS256'
    });

    return { accessToken, refreshToken };
  } catch (error) {
    throw new Error('Failed to generate authentication tokens');
  }
}

// Requirement: 7.3.1 Network Security - JWT token verification
export async function verifyAccessToken(token: string): Promise<TokenPayload> {
  try {
    // Verify token signature and expiration
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as TokenPayload;

    // Additional validation can be added here
    if (!decoded.userId || !decoded.email || !decoded.role) {
      throw new Error('Invalid token payload');
    }

    return decoded;
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      throw new Error('Token has expired');
    }
    if (error instanceof jwt.JsonWebTokenError) {
      throw new Error('Invalid token');
    }
    throw error;
  }
}

// Requirement: 7.3.1 Network Security - Refresh token verification and access token renewal
export async function verifyRefreshToken(refreshToken: string): Promise<string> {
  try {
    // Verify refresh token
    const decoded = jwt.verify(
      refreshToken,
      process.env.JWT_REFRESH_SECRET!
    ) as TokenPayload;

    // Generate new access token
    const newAccessToken = jwt.sign(
      {
        userId: decoded.userId,
        email: decoded.email,
        role: decoded.role
      },
      process.env.JWT_SECRET!,
      {
        expiresIn: process.env.JWT_EXPIRES_IN || '1h',
        algorithm: 'HS256'
      }
    );

    return newAccessToken;
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      throw new Error('Refresh token has expired');
    }
    throw new Error('Invalid refresh token');
  }
}

// Requirement: 7.1.2 Authorization Matrix - Role-based access control
export function checkUserRole(user: IUser, allowedRoles: UserRole[]): boolean {
  try {
    // Check if user's role is in the allowed roles array
    return allowedRoles.includes(user.role);
  } catch (error) {
    throw new Error('Role verification failed');
  }
}

// Requirement: 7.1.1 Authentication Flow - Firebase token validation
export async function validateFirebaseToken(idToken: string): Promise<any> {
  try {
    // Verify the Firebase ID token
    const decodedToken = await firebaseAdmin.verifyIdToken(idToken, true);

    // Extract user data from the verified token
    const firebaseUser = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
      displayName: decodedToken.name,
      photoURL: decodedToken.picture,
      phoneNumber: decodedToken.phone_number,
      // Add any additional claims or custom data
      customClaims: decodedToken.claims
    };

    return firebaseUser;
  } catch (error) {
    throw new Error('Firebase token validation failed');
  }
}

// Helper function to extract token from request header
export function extractTokenFromHeader(req: Request): string | null {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    return authHeader.split(' ')[1];
  } catch (error) {
    return null;
  }
}

// Helper function to validate token expiration
function isTokenExpired(exp: number): boolean {
  if (!exp) return true;
  // Add 5 seconds buffer for clock skew
  return Date.now() >= (exp * 1000) - 5000;
}

// Helper function to validate token issuer and audience
function validateTokenMetadata(decoded: any): boolean {
  // Add additional token metadata validation if needed
  return true;
}