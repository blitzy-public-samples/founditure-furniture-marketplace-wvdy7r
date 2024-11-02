// @package mongoose ^7.x
// @package bcrypt ^5.x

import mongoose, { Schema, model } from 'mongoose';
import bcrypt from 'bcrypt';
import { IUser, UserRole, UserStatus, IUserPreferences, IUserAuth } from '../interfaces/user.interface';
import { IUserPoints } from '../interfaces/point.interface';
import { ILocation } from '../interfaces/location.interface';

/*
HUMAN TASKS:
1. Ensure MongoDB is configured with proper indexes for email and username
2. Configure proper security settings for password hashing (SALT_ROUNDS)
3. Set up monitoring for failed login attempts
4. Configure proper backup strategy for user data
5. Set up audit logging for sensitive operations
*/

// Addresses requirement: Privacy controls - User preferences and privacy settings
const userPreferencesSchema = new Schema<IUserPreferences>({
  language: { type: String, default: 'en' },
  notifications: {
    email: { type: Boolean, default: true },
    push: { type: Boolean, default: true },
    sms: { type: Boolean, default: false }
  },
  privacySettings: {
    profileVisibility: { type: String, default: 'public' },
    locationSharing: { type: Boolean, default: true },
    activityVisibility: { type: String, default: 'friends' }
  },
  searchRadius: { type: Number, default: 10 },
  theme: { type: String, default: 'light' }
});

// Addresses requirement: User authentication and authorization - Secure authentication data storage
const userAuthSchema = new Schema<IUserAuth>({
  passwordHash: { type: String, required: true },
  salt: { type: String, required: true },
  mfaEnabled: { type: Boolean, default: false },
  mfaSecret: { type: String, default: null },
  refreshTokens: [{ type: String }],
  lastPasswordChange: { type: Date, default: Date.now },
  failedLoginAttempts: { type: Number, default: 0 },
  lockoutUntil: { type: Date, default: null }
}, { _id: false });

// Addresses requirements: User authentication and authorization, Points system, Privacy controls
const userSchema = new Schema<IUser>({
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true
  },
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  fullName: {
    type: String,
    required: true,
    trim: true
  },
  phoneNumber: {
    type: String,
    required: false,
    trim: true
  },
  role: {
    type: String,
    enum: Object.values(UserRole),
    default: UserRole.USER
  },
  status: {
    type: String,
    enum: Object.values(UserStatus),
    default: UserStatus.ACTIVE
  },
  points: {
    type: Schema.Types.ObjectId,
    ref: 'UserPoints'
  },
  location: {
    type: Schema.Types.ObjectId,
    ref: 'Location'
  },
  preferences: {
    type: userPreferencesSchema,
    default: () => ({})
  },
  auth: {
    type: userAuthSchema,
    required: true,
    select: false
  },
  lastLoginAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  toJSON: {
    transform: (_, ret) => {
      delete ret.auth;
      return ret;
    }
  }
});

// Addresses requirement: User authentication and authorization - Password security
userSchema.methods.validatePassword = async function(password: string): Promise<boolean> {
  try {
    const user = await this.model('User').findById(this._id).select('+auth.passwordHash');
    if (!user) return false;
    return bcrypt.compare(password, user.auth.passwordHash);
  } catch (error) {
    return false;
  }
};

// Addresses requirement: User authentication and authorization - Password hashing
userSchema.pre('save', async function(next) {
  if (!this.isModified('auth.passwordHash')) {
    return next();
  }

  try {
    const SALT_ROUNDS = 12;
    const salt = await bcrypt.genSalt(SALT_ROUNDS);
    this.auth.passwordHash = await bcrypt.hash(this.auth.passwordHash, salt);
    this.auth.salt = salt;
    this.auth.lastPasswordChange = new Date();
    next();
  } catch (error) {
    next(error as Error);
  }
});

// Indexes for optimized queries
userSchema.index({ email: 1 });
userSchema.index({ username: 1 });
userSchema.index({ status: 1 });
userSchema.index({ 'auth.lastPasswordChange': 1 });
userSchema.index({ lastLoginAt: 1 });

// Addresses requirement: User authentication and authorization - User model export
const UserModel = model<IUser>('User', userSchema);

export default UserModel;