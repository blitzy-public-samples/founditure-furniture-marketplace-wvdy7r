// @package mongoose ^6.0.0

import { Types } from 'mongoose';

/**
 * Enum defining possible states of a point transaction
 * Addresses requirement: Points-based gamification engine
 */
export enum PointTransactionStatus {
  PENDING = 'PENDING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  REVERSED = 'REVERSED'
}

/**
 * Enum defining possible states of an achievement
 * Addresses requirement: Points system and leaderboards
 */
export enum AchievementStatus {
  LOCKED = 'LOCKED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CLAIMED = 'CLAIMED'
}

/**
 * Enum defining time periods for leaderboard calculations
 * Addresses requirement: Points system and leaderboards
 */
export enum LeaderboardPeriod {
  DAILY = 'DAILY',
  WEEKLY = 'WEEKLY',
  MONTHLY = 'MONTHLY',
  ALL_TIME = 'ALL_TIME'
}

/**
 * Interface defining structure of a point transaction
 * Addresses requirement: Points-based gamification engine
 */
export interface IPointTransaction {
  id: Types.ObjectId;
  userId: Types.ObjectId;
  actionType: string;
  points: number;
  multiplier: number;
  totalPoints: number;
  status: PointTransactionStatus;
  metadata: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Interface defining structure of user point data
 * Addresses requirement: Points system and leaderboards
 */
export interface IUserPoints {
  userId: Types.ObjectId;
  totalPoints: number;
  availablePoints: number;
  level: number;
  rank: number;
  achievements: IAchievement[];
  lastUpdated: Date;
}

/**
 * Interface defining structure of an achievement
 * Addresses requirement: Points system and leaderboards
 */
export interface IAchievement {
  id: string;
  name: string;
  description: string;
  threshold: number;
  progress: number;
  status: AchievementStatus;
  unlockedAt: Date | null;
  claimedAt: Date | null;
}

/**
 * Interface defining parameters for point calculations
 * Addresses requirement: Points-based gamification engine
 */
export interface IPointCalculation {
  actionType: string;
  userId: Types.ObjectId;
  userLevel: number;
  responseTime: number | null;
  locationVerified: boolean;
  specialEvent: string | null;
  metadata: Record<string, any>;
}

/**
 * Interface defining structure of a leaderboard entry
 * Addresses requirement: Points system and leaderboards
 */
export interface ILeaderboardEntry {
  userId: Types.ObjectId;
  username: string;
  points: number;
  rank: number;
  level: number;
  achievements: number;
  period: LeaderboardPeriod;
}