// @package mongoose ^7.x
import { Types } from 'mongoose';
import { IUserPoints } from '../interfaces/point.interface';
import { ILocation } from '../interfaces/location.interface';

/**
 * Enum defining possible user roles in the system
 * Addresses requirement: User authentication and authorization
 */
export enum UserRole {
  USER = 'USER',
  VERIFIED_USER = 'VERIFIED_USER',
  MODERATOR = 'MODERATOR',
  ADMIN = 'ADMIN'
}

/**
 * Enum defining possible user account statuses
 * Addresses requirement: User registration and authentication
 */
export enum UserStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  SUSPENDED = 'SUSPENDED',
  DELETED = 'DELETED'
}

/**
 * Interface defining user preferences and settings
 * Addresses requirement: Privacy controls
 */
export interface IUserPreferences {
  language: string;
  notifications: {
    email: boolean;
    push: boolean;
    sms: boolean;
  };
  privacySettings: {
    profileVisibility: string;
    locationSharing: boolean;
    activityVisibility: string;
  };
  searchRadius: number;
  theme: string;
}

/**
 * Interface defining user authentication data
 * Addresses requirement: User authentication and authorization
 */
export interface IUserAuth {
  passwordHash: string;
  salt: string;
  mfaEnabled: boolean;
  mfaSecret: string | null;
  refreshTokens: string[];
  lastPasswordChange: Date;
  failedLoginAttempts: number;
  lockoutUntil: Date | null;
}

/**
 * Main interface defining user data structure
 * Addresses requirements:
 * - User authentication and authorization
 * - Privacy controls
 * - User registration and authentication
 */
export interface IUser {
  id: Types.ObjectId;
  email: string;
  username: string;
  fullName: string;
  phoneNumber: string;
  role: UserRole;
  status: UserStatus;
  points: IUserPoints;
  location: ILocation;
  preferences: IUserPreferences;
  auth: IUserAuth;
  createdAt: Date;
  updatedAt: Date;
  lastLoginAt: Date;
}