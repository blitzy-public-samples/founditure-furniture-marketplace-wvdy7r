// Third-party imports with versions
import express, { Router } from 'express'; // ^4.18.2

// Internal imports
import AuthController from '../controllers/auth.controller';
import { authenticateRequest, validateFirebaseAuth } from '../middleware/auth.middleware';
import createRateLimiter from '../middleware/rate-limit.middleware';

/*
HUMAN TASKS:
1. Configure rate limiting thresholds in environment variables
2. Set up monitoring for authentication endpoints
3. Configure audit logging for authentication events
4. Set up 2FA secret encryption key
5. Review and update CORS settings for authentication endpoints
6. Configure session management settings
7. Set up authentication failure alerts
*/

// Rate limiting configuration based on global constants
const authRateLimiter = createRateLimiter({
  windowMs: AUTH_RATE_LIMIT_WINDOW, // 15 minutes
  max: AUTH_MAX_REQUESTS, // 5 requests per window
  keyPrefix: 'auth-rate-limit:',
  handler: (req, res) => {
    res.status(429).json({
      error: 'TOO_MANY_REQUESTS',
      message: 'Too many authentication attempts. Please try again later.',
      retryAfter: Math.ceil(AUTH_RATE_LIMIT_WINDOW / 1000)
    });
  }
});

/**
 * Configures and returns the Express router with authentication routes
 * Requirements addressed:
 * - User authentication and authorization (1.2 Scope/Core System Components/2)
 * - Security Protocols (7.3 Security Protocols/7.3.1)
 * - Authentication Methods (7.1.3 Authentication Methods)
 */
const configureAuthRoutes = (): Router => {
  const router = express.Router();
  const authController = new AuthController();

  // User registration endpoint with rate limiting
  // Requirement: Security Protocols - Rate limiting for auth endpoints
  router.post(
    '/register',
    authRateLimiter,
    authController.register
  );

  // User login endpoint with rate limiting
  // Requirement: Security Protocols - Rate limiting for auth endpoints
  router.post(
    '/login',
    authRateLimiter,
    authController.login
  );

  // Token refresh endpoint
  // Requirement: Authentication Methods - JWT-based authentication
  router.post(
    '/refresh',
    authController.refreshToken
  );

  // 2FA setup endpoint with authentication
  // Requirement: Authentication Methods - MFA
  router.post(
    '/2fa/setup',
    authenticateRequest,
    authController.setup2FA
  );

  // 2FA verification endpoint with authentication
  // Requirement: Authentication Methods - MFA
  router.post(
    '/2fa/verify',
    authenticateRequest,
    authController.verify2FA
  );

  // Logout endpoint with authentication
  // Requirement: Security Protocols - Secure logout
  router.post(
    '/logout',
    authenticateRequest,
    authController.logout
  );

  return router;
};

// Export configured router
export default configureAuthRoutes();