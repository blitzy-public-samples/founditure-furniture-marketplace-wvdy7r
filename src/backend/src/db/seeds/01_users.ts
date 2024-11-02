// @package mongoose ^6.0.0

import { Types } from 'mongoose';
import { IUser, UserRole, UserStatus, VisibilityLevel } from '../../interfaces/user.interface';
import UserModel from '../../models/user.model';
import { hashPassword } from '../../utils/encryption.utils';

/*
HUMAN TASKS:
1. Set up secure password storage for seed users in environment variables
2. Configure initial points allocation strategy
3. Review and adjust default privacy settings
4. Set up monitoring for seed operation success/failure
5. Ensure proper database backup before running seeds
*/

// Default privacy settings addressing Privacy Controls requirement
const DEFAULT_PRIVACY_SETTINGS = {
  profileVisibility: VisibilityLevel.PUBLIC,
  locationSharing: true,
  activityVisibility: VisibilityLevel.FRIENDS,
  messagePrivacy: VisibilityLevel.PRIVATE
};

// Default user preferences
const DEFAULT_PREFERENCES = {
  language: 'en',
  notifications: {
    email: true,
    push: true,
    sms: false
  },
  privacySettings: DEFAULT_PRIVACY_SETTINGS,
  searchRadius: 10,
  theme: 'light'
};

// Default users with predefined roles addressing User Authentication requirement
const DEFAULT_USERS: Array<Partial<IUser>> = [
  {
    email: 'admin@founditure.com',
    username: 'admin',
    fullName: 'System Administrator',
    phoneNumber: '+1234567890',
    role: UserRole.ADMIN,
    status: UserStatus.ACTIVE,
    preferences: {
      ...DEFAULT_PREFERENCES,
      privacySettings: {
        ...DEFAULT_PRIVACY_SETTINGS,
        profileVisibility: VisibilityLevel.PRIVATE
      }
    }
  },
  {
    email: 'moderator@founditure.com',
    username: 'moderator',
    fullName: 'Content Moderator',
    phoneNumber: '+1234567891',
    role: UserRole.MODERATOR,
    status: UserStatus.ACTIVE,
    preferences: DEFAULT_PREFERENCES
  },
  {
    email: 'test.user@founditure.com',
    username: 'testuser',
    fullName: 'Test User',
    phoneNumber: '+1234567892',
    role: UserRole.USER,
    status: UserStatus.ACTIVE,
    preferences: DEFAULT_PREFERENCES
  },
  {
    email: 'verified@founditure.com',
    username: 'verified',
    fullName: 'Verified User',
    phoneNumber: '+1234567893',
    role: UserRole.VERIFIED_USER,
    status: UserStatus.ACTIVE,
    preferences: DEFAULT_PREFERENCES
  }
];

// Seed function for initializing user accounts
export default async function seedUsers(): Promise<void> {
  try {
    // Clear existing user collection
    await UserModel.deleteMany({});

    // Hash passwords for all seed users
    const seedUsers = await Promise.all(
      DEFAULT_USERS.map(async (user) => {
        // Get password from environment variables based on role
        const password = process.env[`SEED_${user.role}_PASSWORD`] || 'defaultPassword123!';
        const { hash, salt } = await hashPassword(password);

        // Initialize points for Points System requirement
        const initialPoints = user.role === UserRole.ADMIN ? 1000 :
                            user.role === UserRole.MODERATOR ? 500 :
                            user.role === UserRole.VERIFIED_USER ? 100 : 0;

        return {
          ...user,
          auth: {
            passwordHash: hash,
            salt: salt,
            mfaEnabled: user.role === UserRole.ADMIN, // Enable MFA for admin by default
            mfaSecret: null,
            refreshTokens: [],
            lastPasswordChange: new Date(),
            failedLoginAttempts: 0,
            lockoutUntil: null
          },
          points: {
            balance: initialPoints,
            lifetime: initialPoints,
            level: Math.floor(initialPoints / 100),
            lastUpdated: new Date()
          },
          location: {
            coordinates: {
              latitude: 0,
              longitude: 0
            },
            address: '',
            lastUpdated: new Date()
          },
          createdAt: new Date(),
          updatedAt: new Date(),
          lastLoginAt: new Date()
        };
      })
    );

    // Create users in database
    await UserModel.insertMany(seedUsers);

    console.log(`Successfully seeded ${seedUsers.length} user accounts`);
  } catch (error) {
    console.error('Error seeding users:', error);
    throw new Error('Failed to seed user accounts');
  }
}