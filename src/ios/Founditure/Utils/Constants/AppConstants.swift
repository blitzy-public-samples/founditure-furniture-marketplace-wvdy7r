//
// AppConstants.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify minimum iOS version (14.0) is set in Xcode project settings
// 2. Configure appropriate entitlements for location services
// 3. Set up push notification certificates in Apple Developer Portal
// 4. Configure biometric authentication capabilities in project settings
// 5. Verify bundle identifier matches APP_BUNDLE_ID in project settings

// Foundation framework - iOS 14.0+
import Foundation

// MARK: - App Constants
/// General application constants
/// Requirement: Mobile Applications - Provides configuration constants for native iOS application (iOS 14+)
enum App {
    static let minIOSVersion: String = "14.0"
    static let maxImageSize: Int = 10485760 // 10MB in bytes
    static let maxImageCount: Int = 5
    static let cacheExpirationDays: Int = 7
    static let sessionTimeout: TimeInterval = 3600 // 1 hour in seconds
    static let maxRetryAttempts: Int = 3
}

// MARK: - Feature Flags
/// Feature flag constants for controlling app functionality
/// Requirement: Mobile Applications - Defines feature availability
enum Features {
    static let offlineMode: Bool = true
    static let imageRecognition: Bool = true
    static let locationSharing: Bool = true
    static let pushNotifications: Bool = true
    static let chatEncryption: Bool = true
    static let biometricAuth: Bool = true
}

// MARK: - Points System
/// Points system constants for gamification
/// Requirement: Points System - Defines points system and gamification constants
enum Points {
    static let basePostPoints: Int = 10
    static let baseRecoveryPoints: Int = 50
    static let dailyBonusPoints: Int = 5
    static let referralPoints: Int = 100
    static let achievementPoints: Int = 25
    static let streakMultiplier: Double = 1.5
}

// MARK: - Location Services
/// Location service constants for geofencing and tracking
/// Requirement: Location Services - Defines location and geofencing constants
enum Location {
    static let defaultRadius: Double = 5000.0 // meters
    static let minRadius: Double = 1000.0 // meters
    static let maxRadius: Double = 50000.0 // meters
    static let accuracyThreshold: Double = 100.0 // meters
    static let updateInterval: TimeInterval = 300 // 5 minutes in seconds
    static let geofenceRadius: Double = 200.0 // meters
}

// MARK: - Cache Keys
/// Cache key constants for local storage
enum Cache {
    static let userProfile: String = "user_profile"
    static let furnitureList: String = "furniture_list"
    static let messageHistory: String = "message_history"
    static let pointsData: String = "points_data"
    static let locationData: String = "location_data"
}

// MARK: - Notification Types
/// Notification type constants for push notifications
enum Notification {
    static let newMessage: String = "new_message"
    static let furnitureNearby: String = "furniture_nearby"
    static let pointsEarned: String = "points_earned"
    static let achievementUnlocked: String = "achievement_unlocked"
    static let recoveryReminder: String = "recovery_reminder"
}

// MARK: - Global Constants
/// Application-wide global constants
let APP_NAME: String = "Founditure"
let APP_BUNDLE_ID: String = "com.founditure.ios"
let APP_SCHEME: String = "founditure"
let DEFAULT_ANIMATION_DURATION: TimeInterval = 0.3
let MAX_MESSAGE_LENGTH: Int = 1000
let MAX_TITLE_LENGTH: Int = 100
let MAX_DESCRIPTION_LENGTH: Int = 500
let MIN_PASSWORD_LENGTH: Int = 8