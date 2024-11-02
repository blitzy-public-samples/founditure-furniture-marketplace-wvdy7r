// Third-party imports
import { Request, Response } from 'express'; // ^4.17.1
import { Types } from 'mongoose'; // ^6.0.0

// Internal imports
import PointsService from '../services/points.service';
import { 
  validatePointTransaction, 
  validateAchievementClaim, 
  validateLeaderboardQuery 
} from '../validators/point.validator';
import { 
  IPointTransaction, 
  IUserPoints, 
  ILeaderboardEntry, 
  LeaderboardPeriod 
} from '../interfaces/point.interface';

/**
 * Human Tasks:
 * 1. Configure rate limiting for point transaction endpoints
 * 2. Set up monitoring alerts for failed transactions
 * 3. Review and adjust error handling strategies
 * 4. Configure caching for leaderboard endpoints
 * 5. Set up automated testing for point calculation scenarios
 */

/**
 * Controller handling points-based gamification system endpoints
 * Requirement: Points-based gamification engine - Core component implementing points system functionality
 */
export class PointsController {
  private _pointsService: PointsService;

  constructor(pointsService: PointsService) {
    this._pointsService = pointsService;
  }

  /**
   * Creates a new point transaction for a user action
   * Requirement: Points-based gamification engine - Implements transaction processing
   */
  public createPointTransaction = async (req: Request, res: Response): Promise<void> => {
    try {
      // Validate request body
      const validationResult = await validatePointTransaction(req.body);
      if (!validationResult.isValid) {
        res.status(400).json({
          success: false,
          error: validationResult.errorCode,
          message: validationResult.errorMessage
        });
        return;
      }

      // Extract transaction data
      const transactionData: Partial<IPointTransaction> = {
        userId: new Types.ObjectId(req.body.userId),
        actionType: req.body.actionType,
        points: req.body.points,
        multiplier: req.body.multiplier || 1,
        metadata: req.body.metadata || {}
      };

      // Calculate total points
      const calculationParams = {
        actionType: transactionData.actionType!,
        userId: transactionData.userId!,
        userLevel: req.body.userLevel || 1,
        responseTime: req.body.responseTime || null,
        locationVerified: req.body.locationVerified || false,
        specialEvent: req.body.specialEvent || null,
        metadata: transactionData.metadata
      };

      const totalPoints = await this._pointsService.calculatePoints(calculationParams);
      transactionData.totalPoints = totalPoints;

      // Create transaction
      const transaction = await this._pointsService.createTransaction(transactionData as IPointTransaction);

      res.status(201).json({
        success: true,
        data: transaction
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'TRANSACTION_CREATION_FAILED',
        message: 'Failed to create point transaction'
      });
    }
  };

  /**
   * Retrieves points data for a specific user
   * Requirement: Points system and leaderboards - Implements points tracking
   */
  public getUserPoints = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.params.userId;

      // Validate user ID format
      if (!Types.ObjectId.isValid(userId)) {
        res.status(400).json({
          success: false,
          error: 'INVALID_USER_ID',
          message: 'Invalid user ID format'
        });
        return;
      }

      // Retrieve user points
      const userPoints: IUserPoints = await this._pointsService.getUserPoints(userId);

      res.status(200).json({
        success: true,
        data: userPoints
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'POINTS_RETRIEVAL_FAILED',
        message: 'Failed to retrieve user points'
      });
    }
  };

  /**
   * Processes an achievement claim request
   * Requirement: Points system and leaderboards - Implements achievement system
   */
  public claimAchievement = async (req: Request, res: Response): Promise<void> => {
    try {
      // Validate claim request
      const validationResult = await validateAchievementClaim(req.body);
      if (!validationResult.isValid) {
        res.status(400).json({
          success: false,
          error: validationResult.errorCode,
          message: validationResult.errorMessage
        });
        return;
      }

      // Process achievement claim
      const achievements = await this._pointsService.updateAchievements(req.body.userId);

      res.status(200).json({
        success: true,
        data: achievements
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'ACHIEVEMENT_CLAIM_FAILED',
        message: 'Failed to process achievement claim'
      });
    }
  };

  /**
   * Retrieves leaderboard data for specified period
   * Requirement: Points system and leaderboards - Implements leaderboard functionality
   */
  public getLeaderboard = async (req: Request, res: Response): Promise<void> => {
    try {
      // Validate query parameters
      const validationResult = validateLeaderboardQuery(req.query);
      if (!validationResult.isValid) {
        res.status(400).json({
          success: false,
          error: validationResult.errorCode,
          message: validationResult.errorMessage
        });
        return;
      }

      // Extract query parameters
      const period = req.query.period as LeaderboardPeriod;
      const limit = parseInt(req.query.limit as string) || 100;

      // Retrieve leaderboard
      const leaderboard: ILeaderboardEntry[] = await this._pointsService.getLeaderboard(period, limit);

      res.status(200).json({
        success: true,
        data: leaderboard
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'LEADERBOARD_RETRIEVAL_FAILED',
        message: 'Failed to retrieve leaderboard data'
      });
    }
  };
}

export default PointsController;