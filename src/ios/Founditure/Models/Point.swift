//
// Point.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify CoreData integration for local points persistence
// 2. Configure CloudKit sync for points data if enabled
// 3. Test points calculation with different multipliers
// 4. Validate streak multiplier logic with product team

// Foundation framework - iOS 14.0+
import Foundation

/// Internal dependencies
import AppConstants
import Date_Extension

/// Point model representing a point transaction in the gamification system
/// Requirement: Points system and leaderboards - Core data model for points tracking and gamification features
@objc
@objcMembers
class Point: NSObject, Codable {
    
    // MARK: - Properties
    
    /// Unique identifier for the point transaction
    let id: UUID
    
    /// Point value amount
    let value: Int
    
    /// Type of point transaction
    let type: String
    
    /// Description of the point transaction
    let description: String
    
    /// Timestamp of when points were earned
    let timestamp: Date
    
    /// User ID associated with the points
    let userId: UUID
    
    /// Optional reference ID (e.g., furniture ID, achievement ID)
    let referenceId: UUID?
    
    /// Processing status flag
    var isProcessed: Bool
    
    // MARK: - Initialization
    
    /// Initializes a new point transaction
    /// Requirement: Offline-first architecture - Supports local points data persistence
    /// - Parameters:
    ///   - value: Point value amount
    ///   - type: Type of point transaction
    ///   - description: Description of the transaction
    ///   - userId: Associated user ID
    ///   - referenceId: Optional reference ID
    init(value: Int, type: String, description: String, userId: UUID, referenceId: UUID? = nil) {
        self.id = UUID()
        self.value = value
        self.type = type
        self.description = description
        self.timestamp = Date()
        self.userId = userId
        self.referenceId = referenceId
        self.isProcessed = false
    }
    
    // MARK: - Public Methods
    
    /// Returns formatted timestamp string for display
    /// Requirement: Points system and leaderboards - Supports points history display
    /// - Returns: Formatted date string
    func formattedTimestamp() -> String {
        return timestamp.formatForPoints()
    }
    
    /// Calculates point multiplier based on streak or bonuses
    /// Requirement: Points system and leaderboards - Supports points calculation with multipliers
    /// - Returns: Point multiplier value
    func calculateMultiplier() -> Double {
        // Apply streak multiplier if applicable
        switch type {
        case PointType.streak.rawValue:
            return Points.streakMultiplier
        default:
            return 1.0
        }
    }
}

/// Defines different types of point transactions
/// Requirement: Points system and leaderboards - Supports various point earning activities
enum PointType: String {
    case posting
    case recovery
    case dailyBonus
    case referral
    case achievement
    case streak
    
    /// Returns base point value for the transaction type
    var baseValue: Int {
        switch self {
        case .posting:
            return Points.basePostPoints
        case .recovery:
            return Points.baseRecoveryPoints
        case .dailyBonus:
            return Points.dailyBonusPoints
        case .referral:
            return Points.referralPoints
        case .achievement:
            return Points.achievementPoints
        case .streak:
            return Points.dailyBonusPoints
        }
    }
}