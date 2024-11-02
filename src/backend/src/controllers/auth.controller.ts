// Third-party imports with versions
import { Request, Response, NextFunction } from 'express'; // ^4.18.2
import { StatusCodes } from 'http-status-codes'; // ^2.2.0

// Internal imports
import AuthService from '../services/auth.service';
import { 
  validateLoginCredentials, 
  validateRegistrationData, 
  validatePasswordReset, 
  validatePasswordUpdate 
} from '../validators/auth.validator';
import { AppError } from '../middleware/error.middleware';

/*
HUMAN TASKS:
1. Configure rate limiting for authentication endpoints
2. Set up monitoring for authentication failures
3. Configure audit logging for authentication events
4. Set up 2FA secret encryption key
5. Configure session management settings
6. Review and update CORS settings for authentication endpoints
7. Set up authentication event notifications
*/

/**
 * Controller handling authentication-related HTTP requests
 * Requirements:
 * - User authentication and authorization
 * - Security Protocols
 * - Authentication Methods
 */
class AuthController {
  private authService: AuthService;

  constructor() {
    this.authService = new AuthService();
  }

  /**
   * Handles user registration requests
   * Requirements:
   * - User authentication and authorization - User registration
   * - Security Protocols - Input validation
   */
  public register = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      // Validate registration data
      const validationResult = await validateRegistrationData(req.body);
      if (!validationResult.isValid) {
        throw new AppError(
          validationResult.errorCode || 'VALIDATION_ERROR',
          StatusCodes.BAD_REQUEST,
          validationResult.errorMessage || 'Invalid registration data'
        );
      }

      // Register user
      const { user, tokens } = await this.authService.register({
        email: req.body.email,
        password: req.body.password,
        fullName: req.body.fullName,
        username: req.body.username,
        phoneNumber: req.body.phoneNumber
      });

      // Set secure HTTP-only cookies for tokens
      res.cookie('refreshToken', tokens.refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
      });

      res.status(StatusCodes.CREATED).json({
        code: 'REGISTRATION_SUCCESS',
        message: 'User registered successfully',
        data: {
          user: {
            id: user.id,
            email: user.email,
            fullName: user.fullName,
            username: user.username
          },
          accessToken: tokens.accessToken
        }
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * Handles user login requests
   * Requirements:
   * - Security Protocols - Secure authentication
   * - Authentication Methods - JWT and 2FA
   */
  public login = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      // Validate login credentials
      const validationResult = await validateLoginCredentials(
        req.body.email,
        req.body.password
      );
      if (!validationResult.isValid) {
        throw new AppError(
          validationResult.errorCode || 'VALIDATION_ERROR',
          StatusCodes.BAD_REQUEST,
          validationResult.errorMessage || 'Invalid login credentials'
        );
      }

      // Attempt login
      const { user, tokens } = await this.authService.login({
        email: req.body.email,
        password: req.body.password,
        twoFactorToken: req.body.twoFactorToken
      });

      // Set secure HTTP-only cookies for tokens
      res.cookie('refreshToken', tokens.refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
      });

      res.status(StatusCodes.OK).json({
        code: 'LOGIN_SUCCESS',
        message: 'Login successful',
        data: {
          user: {
            id: user.id,
            email: user.email,
            fullName: user.fullName,
            username: user.username,
            mfaEnabled: user.auth.mfaEnabled
          },
          accessToken: tokens.accessToken
        }
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * Handles token refresh requests
   * Requirements:
   * - Security Protocols - JWT token refresh
   * - Authentication Methods - Secure token handling
   */
  public refreshToken = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const refreshToken = req.cookies.refreshToken;
      if (!refreshToken) {
        throw new AppError(
          'REFRESH_TOKEN_MISSING',
          StatusCodes.UNAUTHORIZED,
          'Refresh token is required'
        );
      }

      const { accessToken } = await this.authService.refreshToken(refreshToken);

      res.status(StatusCodes.OK).json({
        code: 'TOKEN_REFRESH_SUCCESS',
        message: 'Token refreshed successfully',
        data: { accessToken }
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * Handles 2FA setup requests
   * Requirements:
   * - Authentication Methods - Multi-factor authentication
   * - Security Protocols - 2FA implementation
   */
  public setup2FA = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        throw new AppError(
          'UNAUTHORIZED',
          StatusCodes.UNAUTHORIZED,
          'User not authenticated'
        );
      }

      const { secret, qrCode } = await this.authService.setup2FA(userId);

      res.status(StatusCodes.OK).json({
        code: '2FA_SETUP_SUCCESS',
        message: '2FA setup successful',
        data: { secret, qrCode }
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * Handles 2FA verification requests
   * Requirements:
   * - Authentication Methods - 2FA verification
   * - Security Protocols - Secure verification
   */
  public verify2FA = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user?.id;
      const { token } = req.body;

      if (!userId) {
        throw new AppError(
          'UNAUTHORIZED',
          StatusCodes.UNAUTHORIZED,
          'User not authenticated'
        );
      }

      if (!token) {
        throw new AppError(
          'VALIDATION_ERROR',
          StatusCodes.BAD_REQUEST,
          '2FA token is required'
        );
      }

      const isValid = await this.authService.verify2FA(userId, token);

      res.status(StatusCodes.OK).json({
        code: '2FA_VERIFICATION_SUCCESS',
        message: '2FA verification successful',
        data: { verified: isValid }
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * Handles user logout requests
   * Requirements:
   * - Security Protocols - Secure logout
   * - Authentication Methods - Session management
   */
  public logout = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user?.id;
      const refreshToken = req.cookies.refreshToken;

      if (!userId || !refreshToken) {
        throw new AppError(
          'UNAUTHORIZED',
          StatusCodes.UNAUTHORIZED,
          'User not authenticated'
        );
      }

      await this.authService.logout(userId, refreshToken);

      // Clear authentication cookies
      res.clearCookie('refreshToken', {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict'
      });

      res.status(StatusCodes.OK).json({
        code: 'LOGOUT_SUCCESS',
        message: 'Logged out successfully'
      });
    } catch (error) {
      next(error);
    }
  };
}

export default AuthController;