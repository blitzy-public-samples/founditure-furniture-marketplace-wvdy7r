/**
 * Human Tasks:
 * 1. Review and adjust point values based on user engagement metrics
 * 2. Configure timezone settings for peak hours and daily resets
 * 3. Validate achievement thresholds against user progression data
 * 4. Review special event dates and multipliers with marketing team
 * 5. Ensure penalties align with terms of service violations
 */

// Base points awarded for different user actions
// Requirement: Points-based gamification engine - Core component defining point values
export const BASE_POINTS = {
  FURNITURE_LISTING: 100,    // Points for creating a new furniture listing
  SUCCESSFUL_RECOVERY: 200,  // Points for confirming furniture recovery
  VERIFIED_LOCATION: 50,     // Points for providing accurate location data
  QUALITY_PHOTO: 25,        // Points for high-quality furniture photos
  ACCURATE_DESCRIPTION: 25,  // Points for detailed item description
  CHAT_RESPONSE: 10,        // Points for responding to inquiries
  PROFILE_COMPLETION: 50,    // Points for completing user profile
  DAILY_LOGIN: 5            // Points for daily app engagement
} as const;

// Point multipliers for special conditions
// Requirement: Points system and leaderboards - Defines rules for user engagement
export const MULTIPLIERS = {
  QUICK_RESPONSE: 1.5,      // Multiplier for fast chat responses
  PEAK_HOURS: 2.0,          // Multiplier during high activity hours
  SPECIAL_EVENT: 3.0,       // Multiplier during platform events
  CONSECUTIVE_DAYS: 1.2,    // Multiplier for consecutive daily logins
  HIGH_DEMAND_AREA: 1.5,    // Multiplier for priority locations
  VERIFIED_USER: 1.25       // Multiplier for verified user status
} as const;

// Point thresholds for achieving different status levels
// Requirement: Points system and leaderboards - Defines achievement thresholds
export const ACHIEVEMENT_THRESHOLDS = {
  NOVICE_RECOVERER: 500,      // Entry-level achievement
  INTERMEDIATE_RECOVERER: 2000, // Mid-level achievement
  EXPERT_RECOVERER: 5000,      // Advanced achievement
  MASTER_RECOVERER: 10000,     // Expert-level achievement
  QUICK_RESPONDER: 1000,       // Communication achievement
  PHOTO_MASTER: 1500,          // Photography achievement
  LOCATION_EXPERT: 2000,       // Location accuracy achievement
  COMMUNITY_PILLAR: 3000       // Community contribution achievement
} as const;

// Point requirements for user level progression
// Requirement: Points-based gamification engine - Defines level progression
export const LEVEL_REQUIREMENTS = {
  LEVEL_1: 0,      // Starting level
  LEVEL_2: 1000,   // Bronze tier
  LEVEL_3: 3000,   // Silver tier
  LEVEL_4: 6000,   // Gold tier
  LEVEL_5: 10000,  // Platinum tier
  LEVEL_6: 15000,  // Diamond tier
  LEVEL_7: 21000,  // Master tier
  LEVEL_8: 28000,  // Elite tier
  LEVEL_9: 36000,  // Champion tier
  LEVEL_10: 45000  // Legend tier
} as const;

// Time-based constraints for point system
// Requirement: Points system and leaderboards - Defines time-based rules
export const TIME_CONSTRAINTS = {
  QUICK_RESPONSE_MINUTES: 15,     // Window for quick response bonus
  LISTING_EXPIRY_DAYS: 7,        // Days until listing expires
  POINTS_EXPIRY_DAYS: 90,        // Days until points expire
  DAILY_RESET_UTC: '00:00',      // Daily points reset time
  WEEKLY_RESET_DAY: 'MONDAY',    // Weekly achievements reset
  PEAK_HOURS_START: '17:00',     // Start of peak activity period
  PEAK_HOURS_END: '21:00'        // End of peak activity period
} as const;

// Point deductions for rule violations
// Requirement: Points-based gamification engine - Defines penalty system
export const PENALTIES = {
  INCORRECT_LOCATION: -50,       // Penalty for wrong location
  MISLEADING_DESCRIPTION: -100,  // Penalty for inaccurate description
  SPAM_LISTING: -200,           // Penalty for spam content
  INAPPROPRIATE_CONTENT: -300,   // Penalty for inappropriate content
  FAKE_RECOVERY: -500           // Penalty for false recovery claims
} as const;

// Special event configurations
// Requirement: Points system and leaderboards - Defines special event rules
export const SPECIAL_EVENTS = {
  EARTH_DAY: {
    multiplier: 3.0,
    duration_days: 1
  },
  ZERO_WASTE_WEEK: {
    multiplier: 2.5,
    duration_days: 7
  },
  HOLIDAY_SEASON: {
    multiplier: 2.0,
    duration_days: 30
  }
} as const;