// @package mongoose ^6.0.0

import mongoose, { Schema, Document } from 'mongoose';
import { 
  IPointTransaction, 
  IUserPoints, 
  IAchievement, 
  ILeaderboardEntry,
  PointTransactionStatus,
  AchievementStatus,
  LeaderboardPeriod
} from '../interfaces/point.interface';
import { 
  BASE_POINTS, 
  MULTIPLIERS, 
  ACHIEVEMENT_THRESHOLDS, 
  LEVEL_REQUIREMENTS 
} from '../constants/points';

/**
 * Human Tasks:
 * 1. Configure MongoDB indexes for optimal query performance
 * 2. Set up monitoring for transaction processing times
 * 3. Review and adjust TTL indexes for leaderboard entries
 * 4. Configure backup schedule for points data
 * 5. Set up alerts for unusual point accumulation patterns
 */

// Requirement: Points-based gamification engine - Core component implementing data models
const pointTransactionSchema = new Schema<IPointTransaction>({
  userId: { 
    type: Schema.Types.ObjectId, 
    ref: 'User', 
    required: true,
    index: true 
  },
  actionType: { 
    type: String, 
    required: true,
    enum: Object.keys(BASE_POINTS)
  },
  points: { 
    type: Number, 
    required: true,
    min: 0 
  },
  multiplier: { 
    type: Number, 
    required: true,
    default: 1.0,
    min: 0 
  },
  totalPoints: { 
    type: Number, 
    required: true 
  },
  status: { 
    type: String, 
    required: true,
    enum: Object.values(PointTransactionStatus),
    default: PointTransactionStatus.PENDING 
  },
  metadata: { 
    type: Map,
    of: Schema.Types.Mixed,
    default: {} 
  },
  createdAt: { 
    type: Date, 
    default: Date.now,
    index: true 
  },
  updatedAt: { 
    type: Date, 
    default: Date.now 
  }
});

// Pre-save hook to calculate total points with multipliers
pointTransactionSchema.pre('save', async function() {
  if (this.isModified('points') || this.isModified('multiplier')) {
    this.totalPoints = Math.round(this.points * this.multiplier);
  }
  this.updatedAt = new Date();
});

// Requirement: Points system and leaderboards - Implements data models for points tracking
const userPointsSchema = new Schema<IUserPoints>({
  userId: { 
    type: Schema.Types.ObjectId, 
    ref: 'User', 
    required: true,
    unique: true 
  },
  totalPoints: { 
    type: Number, 
    required: true,
    default: 0,
    min: 0 
  },
  availablePoints: { 
    type: Number, 
    required: true,
    default: 0,
    min: 0 
  },
  level: { 
    type: Number, 
    required: true,
    default: 1,
    min: 1 
  },
  rank: { 
    type: Number,
    default: 0 
  },
  achievements: [{
    id: String,
    name: String,
    description: String,
    threshold: Number,
    progress: { 
      type: Number, 
      default: 0 
    },
    status: { 
      type: String,
      enum: Object.values(AchievementStatus),
      default: AchievementStatus.LOCKED 
    },
    unlockedAt: Date,
    claimedAt: Date
  }],
  lastUpdated: { 
    type: Date, 
    default: Date.now 
  }
});

// Updates user level based on total points
userPointsSchema.methods.updateLevel = async function(): Promise<void> {
  const levels = Object.entries(LEVEL_REQUIREMENTS)
    .sort(([, a], [, b]) => b - a);
  
  for (const [level, requirement] of levels) {
    if (this.totalPoints >= requirement) {
      const newLevel = parseInt(level.split('_')[1]);
      if (newLevel !== this.level) {
        this.level = newLevel;
        this.markModified('level');
      }
      break;
    }
  }
};

// Requirement: Points system and leaderboards - Implements achievement functionality
const achievementSchema = new Schema<IAchievement>({
  id: { 
    type: String, 
    required: true,
    unique: true 
  },
  name: { 
    type: String, 
    required: true 
  },
  description: { 
    type: String, 
    required: true 
  },
  threshold: { 
    type: Number, 
    required: true,
    min: 0 
  },
  progress: { 
    type: Number, 
    default: 0,
    min: 0 
  },
  status: { 
    type: String,
    enum: Object.values(AchievementStatus),
    default: AchievementStatus.LOCKED 
  },
  unlockedAt: Date,
  claimedAt: Date
});

// Updates achievement progress and status
achievementSchema.methods.checkProgress = async function(): Promise<void> {
  if (this.progress >= this.threshold && this.status === AchievementStatus.IN_PROGRESS) {
    this.status = AchievementStatus.COMPLETED;
    this.unlockedAt = new Date();
    this.markModified('status');
    this.markModified('unlockedAt');
  }
};

// Requirement: Points system and leaderboards - Implements leaderboard functionality
const leaderboardEntrySchema = new Schema<ILeaderboardEntry>({
  userId: { 
    type: Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  username: { 
    type: String, 
    required: true 
  },
  points: { 
    type: Number, 
    required: true,
    min: 0 
  },
  rank: { 
    type: Number, 
    required: true,
    min: 1 
  },
  level: { 
    type: Number, 
    required: true,
    min: 1 
  },
  achievements: { 
    type: Number, 
    required: true,
    default: 0,
    min: 0 
  },
  period: { 
    type: String,
    enum: Object.values(LeaderboardPeriod),
    required: true,
    index: true 
  }
}, {
  timestamps: true
});

// Compound index for efficient leaderboard queries
leaderboardEntrySchema.index({ period: 1, points: -1 });

// Updates entry rank based on points
leaderboardEntrySchema.methods.updateRank = async function(): Promise<void> {
  const count = await this.constructor.countDocuments({
    period: this.period,
    points: { $gt: this.points }
  });
  this.rank = count + 1;
  this.markModified('rank');
};

// Create and export the models
export const PointTransaction = mongoose.model<IPointTransaction>('PointTransaction', pointTransactionSchema);
export const UserPoints = mongoose.model<IUserPoints>('UserPoints', userPointsSchema);
export const Achievement = mongoose.model<IAchievement>('Achievement', achievementSchema);
export const LeaderboardEntry = mongoose.model<ILeaderboardEntry>('LeaderboardEntry', leaderboardEntrySchema);