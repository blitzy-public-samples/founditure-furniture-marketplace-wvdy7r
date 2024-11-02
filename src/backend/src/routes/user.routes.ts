// Human Tasks:
// 1. Configure rate limiting thresholds in environment variables
// 2. Set up monitoring for authentication failures
// 3. Configure user role permissions
// 4. Set up audit logging for sensitive operations
// 5. Review and configure password complexity requirements

// Third-party imports with version
import express, { Router } from 'express'; // ^4.18.2

// Internal imports
import {
  registerUser,
  getUserProfile,
  updateUserProfile,
  updateUserPreferences,
  changePassword,
  deactivateAccount
} from '../controllers/user.controller';
import {
  authenticateRequest,
  authorizeRoles
} from '../middleware/auth.middleware';
import { validateAuthRequest } from '../middleware/validation.middleware';
import { createRateLimiter } from '../middleware/rate-limit.middleware';

// Create Express router instance
const router: Router = express.Router();

// Configure rate limiter for sensitive operations
const userRateLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 100,
  keyPrefix: 'user-routes:'
});

/**
 * User Routes Configuration
 * Requirements addressed:
 * - User registration and authentication (1.2 Scope/Included Features)
 * - Privacy controls (1.2 Scope/Included Features)
 * - Points system and leaderboards (1.2 Scope/Included Features)
 */

// Public routes
router.post(
  '/register',
  validateAuthRequest,
  userRateLimiter,
  registerUser
);

// Protected routes requiring authentication
router.get(
  '/profile',
  authenticateRequest,
  getUserProfile
);

router.put(
  '/profile',
  authenticateRequest,
  validateAuthRequest,
  userRateLimiter,
  updateUserProfile
);

router.put(
  '/preferences',
  authenticateRequest,
  validateAuthRequest,
  updateUserPreferences
);

router.put(
  '/password',
  authenticateRequest,
  validateAuthRequest,
  userRateLimiter,
  changePassword
);

router.post(
  '/deactivate',
  authenticateRequest,
  userRateLimiter,
  deactivateAccount
);

export default router;