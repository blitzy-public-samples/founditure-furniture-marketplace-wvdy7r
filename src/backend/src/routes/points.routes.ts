// Third-party imports
import express, { Router } from 'express'; // ^4.18.2

// Internal imports
import PointsController from '../controllers/points.controller';
import { authenticateRequest } from '../middleware/auth.middleware';

/**
 * Human Tasks:
 * 1. Configure rate limiting for points-related endpoints
 * 2. Set up monitoring for points transactions
 * 3. Configure caching strategy for leaderboard endpoint
 * 4. Review and adjust authentication rules for each endpoint
 * 5. Set up automated testing for points routes
 */

/**
 * Express router configuration for points-based gamification system endpoints
 * Requirement: Points system and leaderboards - Implementation of points tracking, achievements, and leaderboard functionality
 */
const router: Router = express.Router();

/**
 * Initialize routes with points controller instance
 * @param pointsController - Instance of PointsController for handling points-related requests
 * @returns Configured Express router instance
 */
const initializeRoutes = (pointsController: PointsController): Router => {
  /**
   * POST /points/transaction
   * Creates a new point transaction for user actions
   * Requirement: Points-based gamification engine - Core component implementing points system functionality
   */
  router.post(
    '/points/transaction',
    authenticateRequest,
    pointsController.createPointTransaction
  );

  /**
   * GET /points/user/:userId
   * Retrieves points data for a specific user
   * Requirement: Points system and leaderboards - Implementation of points tracking
   */
  router.get(
    '/points/user/:userId',
    authenticateRequest,
    pointsController.getUserPoints
  );

  /**
   * POST /points/achievements/claim
   * Processes an achievement claim request
   * Requirement: Points system and leaderboards - Implementation of achievements
   */
  router.post(
    '/points/achievements/claim',
    authenticateRequest,
    pointsController.claimAchievement
  );

  /**
   * GET /points/leaderboard
   * Retrieves leaderboard data for specified period
   * Requirement: Points system and leaderboards - Implementation of leaderboard functionality
   */
  router.get(
    '/points/leaderboard',
    authenticateRequest,
    pointsController.getLeaderboard
  );

  return router;
};

// Export configured points router for use in main application
export default initializeRoutes;