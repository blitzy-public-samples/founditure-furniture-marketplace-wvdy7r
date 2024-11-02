// Third-party imports with versions
import speakeasy from 'speakeasy'; // ^2.0.0
import qrcode from 'qrcode'; // ^1.5.3
import { Types } from 'mongoose'; // ^7.x

// Internal imports
import UserModel from '../models/user.model';
import { IUser, UserRole, UserStatus } from '../interfaces/user.interface';
import { generateAuthTokens, verifyAccessToken, verifyRefreshToken, validateFirebaseToken } from '../utils/auth.utils';
import { hashPassword, verifyPassword } from '../utils/encryption.utils';

/*
HUMAN TASKS:
1. Configure environment variables for JWT secrets and expiration times
2. Set up Firebase project and credentials
3. Configure 2FA secret encryption key
4. Set up rate limiting for authentication endpoints
5. Configure monitoring for authentication failures
6. Set up audit logging for authentication events
7. Configure password policy settings
*/

// Types for authentication
interface RegisterDTO {
  email: string;
  password: string;
  fullName: string;
  username: string;
  phoneNumber?: string;
}

interface LoginDTO {
  email: string;
  password: string;
  twoFactorToken?: string;
}

interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

// Requirement: Core authentication service implementing user authentication
export class AuthService {
  private UserModel: typeof UserModel;

  constructor() {
    this.UserModel = UserModel;
  }

  // Requirement: User authentication and authorization - User registration
  public async register(userData: RegisterDTO): Promise<{ user: IUser; tokens: AuthTokens }> {
    try {
      // Check if email already exists
      const existingUser = await this.UserModel.findOne({ email: userData.email });
      if (existingUser) {
        throw new Error('Email already registered');
      }

      // Hash password using encryption utils
      const { hash: passwordHash, salt } = await hashPassword(userData.password);

      // Create new user document
      const user = await this.UserModel.create({
        email: userData.email,
        username: userData.username,
        fullName: userData.fullName,
        phoneNumber: userData.phoneNumber,
        role: UserRole.USER,
        status: UserStatus.ACTIVE,
        auth: {
          passwordHash,
          salt,
          mfaEnabled: false,
          mfaSecret: null,
          refreshTokens: [],
          failedLoginAttempts: 0,
          lockoutUntil: null
        }
      });

      // Generate authentication tokens
      const tokens = await generateAuthTokens(user);

      // Store refresh token
      await this.UserModel.findByIdAndUpdate(user.id, {
        $push: { 'auth.refreshTokens': tokens.refreshToken }
      });

      return { user, tokens };
    } catch (error) {
      throw new Error(`Registration failed: ${(error as Error).message}`);
    }
  }

  // Requirement: Security Protocols - Implementation of secure authentication protocols
  public async login(credentials: LoginDTO): Promise<{ user: IUser; tokens: AuthTokens }> {
    try {
      // Find user by email
      const user = await this.UserModel.findOne({ email: credentials.email })
        .select('+auth.passwordHash +auth.salt +auth.mfaEnabled +auth.mfaSecret +auth.lockoutUntil +auth.failedLoginAttempts');

      if (!user) {
        throw new Error('Invalid credentials');
      }

      // Check account status
      if (user.status !== UserStatus.ACTIVE) {
        throw new Error('Account is not active');
      }

      // Check account lockout
      if (user.auth.lockoutUntil && user.auth.lockoutUntil > new Date()) {
        throw new Error('Account is temporarily locked');
      }

      // Verify password
      const isPasswordValid = await verifyPassword(
        credentials.password,
        user.auth.passwordHash,
        user.auth.salt
      );

      if (!isPasswordValid) {
        // Increment failed login attempts
        await this.handleFailedLogin(user);
        throw new Error('Invalid credentials');
      }

      // Verify 2FA if enabled
      if (user.auth.mfaEnabled) {
        if (!credentials.twoFactorToken) {
          throw new Error('2FA token required');
        }

        const isTokenValid = await this.verify2FA(user.id.toString(), credentials.twoFactorToken);
        if (!isTokenValid) {
          throw new Error('Invalid 2FA token');
        }
      }

      // Generate authentication tokens
      const tokens = await generateAuthTokens(user);

      // Update last login and reset failed attempts
      await this.UserModel.findByIdAndUpdate(user.id, {
        lastLoginAt: new Date(),
        'auth.failedLoginAttempts': 0,
        'auth.lockoutUntil': null,
        $push: { 'auth.refreshTokens': tokens.refreshToken }
      });

      return { user, tokens };
    } catch (error) {
      throw new Error(`Login failed: ${(error as Error).message}`);
    }
  }

  // Requirement: Security Protocols - JWT token refresh
  public async refreshToken(refreshToken: string): Promise<{ accessToken: string }> {
    try {
      // Verify refresh token
      const newAccessToken = await verifyRefreshToken(refreshToken);

      // Verify token exists in user's refresh tokens
      const user = await this.UserModel.findOne({
        'auth.refreshTokens': refreshToken
      });

      if (!user) {
        throw new Error('Invalid refresh token');
      }

      return { accessToken: newAccessToken };
    } catch (error) {
      throw new Error(`Token refresh failed: ${(error as Error).message}`);
    }
  }

  // Requirement: Privacy Controls - Two-factor authentication setup
  public async setup2FA(userId: string): Promise<{ secret: string; qrCode: string }> {
    try {
      // Generate 2FA secret
      const secret = speakeasy.generateSecret({
        name: process.env.APP_NAME || 'Founditure'
      });

      // Create QR code
      const qrCode = await qrcode.toDataURL(secret.otpauth_url || '');

      // Store secret temporarily (should be confirmed before enabling)
      await this.UserModel.findByIdAndUpdate(userId, {
        'auth.mfaSecret': secret.base32
      });

      return {
        secret: secret.base32,
        qrCode
      };
    } catch (error) {
      throw new Error(`2FA setup failed: ${(error as Error).message}`);
    }
  }

  // Requirement: Privacy Controls - Two-factor authentication verification
  public async verify2FA(userId: string, token: string): Promise<boolean> {
    try {
      // Retrieve user's 2FA secret
      const user = await this.UserModel.findById(userId).select('+auth.mfaSecret');
      if (!user?.auth.mfaSecret) {
        throw new Error('2FA not set up');
      }

      // Verify token
      return speakeasy.totp.verify({
        secret: user.auth.mfaSecret,
        encoding: 'base32',
        token,
        window: 1 // Allow 30 seconds window
      });
    } catch (error) {
      throw new Error(`2FA verification failed: ${(error as Error).message}`);
    }
  }

  // Requirement: Security Protocols - User logout
  public async logout(userId: string, refreshToken: string): Promise<void> {
    try {
      // Remove refresh token from user's token list
      await this.UserModel.findByIdAndUpdate(userId, {
        $pull: { 'auth.refreshTokens': refreshToken }
      });
    } catch (error) {
      throw new Error(`Logout failed: ${(error as Error).message}`);
    }
  }

  // Helper method to handle failed login attempts
  private async handleFailedLogin(user: IUser): Promise<void> {
    const MAX_ATTEMPTS = 5;
    const LOCKOUT_DURATION = 15 * 60 * 1000; // 15 minutes

    const failedAttempts = (user.auth.failedLoginAttempts || 0) + 1;
    const updates: any = { 'auth.failedLoginAttempts': failedAttempts };

    if (failedAttempts >= MAX_ATTEMPTS) {
      updates['auth.lockoutUntil'] = new Date(Date.now() + LOCKOUT_DURATION);
    }

    await this.UserModel.findByIdAndUpdate(user.id, updates);
  }
}

export default AuthService;