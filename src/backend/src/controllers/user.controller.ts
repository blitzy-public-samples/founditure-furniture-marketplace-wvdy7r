/*
HUMAN TASKS:
1. Configure environment variables for JWT secrets and expiration times
2. Set up monitoring for failed login attempts and suspicious activities
3. Configure rate limiting for authentication endpoints
4. Set up audit logging for sensitive user operations
5. Review and configure password complexity requirements
6. Set up backup strategy for user data
*/

// Third-party imports with versions
import { Request, Response, NextFunction } from 'express'; // ^4.18.2
import { StatusCodes } from 'http-status-codes'; // ^2.2.0
import bcrypt from 'bcrypt'; // ^5.x

// Internal imports
import UserModel from '../models/user.model';
import { IUser, UserRole, UserStatus, IUserPreferences } from '../interfaces/user.interface';
import { generateAuthTokens, verifyAccessToken, checkUserRole } from '../utils/auth.utils';
import {
  validateUserRegistration,
  validateUserUpdate,
  validateUserPreferences,
  validatePasswordChange
} from '../validators/user.validator';
import { ERROR_MESSAGES, SUCCESS_MESSAGES } from '../constants/messages';
import { ERROR_CODES } from '../constants/error-codes';

/**
 * Handles new user registration
 * Requirements addressed:
 * - User registration and authentication (1.2 Scope/Included Features)
 * - Privacy controls (1.2 Scope/Included Features)
 */
export const registerUser = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Validate registration data
    const validationResult = await validateUserRegistration(req.body);
    if (!validationResult.isValid) {
      res.status(StatusCodes.BAD_REQUEST).json({
        status: 'error',
        errors: validationResult.errors
      });
      return;
    }

    // Check if user already exists
    const existingUser = await UserModel.findOne({ email: req.body.email });
    if (existingUser) {
      res.status(StatusCodes.CONFLICT).json({
        status: 'error',
        message: ERROR_MESSAGES.AUTH_USER_EXISTS
      });
      return;
    }

    // Create new user
    const user = new UserModel({
      email: req.body.email,
      username: req.body.username,
      fullName: req.body.fullName,
      phoneNumber: req.body.phoneNumber,
      role: UserRole.USER,
      status: UserStatus.ACTIVE,
      auth: {
        passwordHash: req.body.password,
        salt: '',
        mfaEnabled: false,
        refreshTokens: []
      },
      preferences: {
        language: 'en',
        notifications: {
          email: true,
          push: true,
          sms: false
        },
        privacySettings: {
          profileVisibility: 'public',
          locationSharing: true,
          activityVisibility: 'friends'
        }
      }
    });

    await user.save();

    // Generate authentication tokens
    const tokens = await generateAuthTokens(user);

    // Return success response with user data and tokens
    res.status(StatusCodes.CREATED).json({
      status: 'success',
      data: {
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          fullName: user.fullName,
          role: user.role,
          preferences: user.preferences
        },
        tokens
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Retrieves user profile data
 * Requirements addressed:
 * - User registration and authentication (1.2 Scope/Included Features)
 * - Privacy controls (1.2 Scope/Included Features)
 */
export const getUserProfile = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user?.id;
    const user = await UserModel.findById(userId)
      .select('-auth')
      .populate('points')
      .populate('location');

    if (!user) {
      res.status(StatusCodes.NOT_FOUND).json({
        status: 'error',
        message: ERROR_MESSAGES.AUTH_USER_NOT_FOUND
      });
      return;
    }

    res.status(StatusCodes.OK).json({
      status: 'success',
      data: { user }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Updates user profile information
 * Requirements addressed:
 * - User registration and authentication (1.2 Scope/Included Features)
 * - Privacy controls (1.2 Scope/Included Features)
 */
export const updateUserProfile = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Validate update data
    const validationResult = await validateUserUpdate(req.body);
    if (!validationResult.isValid) {
      res.status(StatusCodes.BAD_REQUEST).json({
        status: 'error',
        errors: validationResult.errors
      });
      return;
    }

    const userId = req.user?.id;
    const user = await UserModel.findById(userId);

    if (!user) {
      res.status(StatusCodes.NOT_FOUND).json({
        status: 'error',
        message: ERROR_MESSAGES.AUTH_USER_NOT_FOUND
      });
      return;
    }

    // Update allowed fields
    const allowedUpdates = ['fullName', 'phoneNumber', 'username'];
    Object.keys(req.body).forEach((key) => {
      if (allowedUpdates.includes(key)) {
        user[key] = req.body[key];
      }
    });

    await user.save();

    res.status(StatusCodes.OK).json({
      status: 'success',
      message: SUCCESS_MESSAGES.PROFILE_UPDATED,
      data: { user }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Updates user preferences and settings
 * Requirements addressed:
 * - Privacy controls (1.2 Scope/Included Features)
 */
export const updateUserPreferences = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Validate preferences data
    const validationResult = await validateUserPreferences(req.body);
    if (!validationResult.isValid) {
      res.status(StatusCodes.BAD_REQUEST).json({
        status: 'error',
        errors: validationResult.errors
      });
      return;
    }

    const userId = req.user?.id;
    const user = await UserModel.findById(userId);

    if (!user) {
      res.status(StatusCodes.NOT_FOUND).json({
        status: 'error',
        message: ERROR_MESSAGES.AUTH_USER_NOT_FOUND
      });
      return;
    }

    // Update preferences
    user.preferences = {
      ...user.preferences,
      ...req.body
    };

    await user.save();

    res.status(StatusCodes.OK).json({
      status: 'success',
      message: SUCCESS_MESSAGES.PROFILE_UPDATED,
      data: { preferences: user.preferences }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Handles user password change
 * Requirements addressed:
 * - User registration and authentication (1.2 Scope/Included Features)
 */
export const changePassword = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { currentPassword, newPassword } = req.body;

    // Validate password change data
    const validationResult = await validatePasswordChange(currentPassword, newPassword);
    if (!validationResult.isValid) {
      res.status(StatusCodes.BAD_REQUEST).json({
        status: 'error',
        errors: validationResult.errors
      });
      return;
    }

    const userId = req.user?.id;
    const user = await UserModel.findById(userId).select('+auth');

    if (!user) {
      res.status(StatusCodes.NOT_FOUND).json({
        status: 'error',
        message: ERROR_MESSAGES.AUTH_USER_NOT_FOUND
      });
      return;
    }

    // Verify current password
    const isValidPassword = await user.validatePassword(currentPassword);
    if (!isValidPassword) {
      res.status(StatusCodes.UNAUTHORIZED).json({
        status: 'error',
        message: ERROR_MESSAGES.AUTH_INVALID_CREDENTIALS
      });
      return;
    }

    // Update password
    user.auth.passwordHash = newPassword;
    user.auth.refreshTokens = []; // Invalidate existing sessions
    await user.save();

    // Generate new tokens
    const tokens = await generateAuthTokens(user);

    res.status(StatusCodes.OK).json({
      status: 'success',
      message: SUCCESS_MESSAGES.PASSWORD_UPDATED,
      data: { tokens }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Handles user account deactivation
 * Requirements addressed:
 * - User registration and authentication (1.2 Scope/Included Features)
 * - Privacy controls (1.2 Scope/Included Features)
 */
export const deactivateAccount = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user?.id;
    const user = await UserModel.findById(userId).select('+auth');

    if (!user) {
      res.status(StatusCodes.NOT_FOUND).json({
        status: 'error',
        message: ERROR_MESSAGES.AUTH_USER_NOT_FOUND
      });
      return;
    }

    // Update user status and invalidate tokens
    user.status = UserStatus.INACTIVE;
    user.auth.refreshTokens = [];
    await user.save();

    res.status(StatusCodes.OK).json({
      status: 'success',
      message: SUCCESS_MESSAGES.ACCOUNT_DEACTIVATED
    });
  } catch (error) {
    next(error);
  }
};