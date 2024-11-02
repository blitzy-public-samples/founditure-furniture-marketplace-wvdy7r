//
// User.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify Keychain integration for secure user data storage
// 2. Configure CloudKit sync for user preferences if enabled
// 3. Set up appropriate user data encryption keys in Keychain
// 4. Review and adjust user privacy settings with legal team
// 5. Configure user data backup and recovery mechanisms

// Foundation framework - iOS 14.0+
import Foundation

// Internal dependencies
import AppConstants
import Point
import Location

// MARK: - UserStatus
/// Defines possible user account statuses
/// Requirement: User registration and authentication - Core user status tracking
enum UserStatus: String, Codable {
    case active
    case inactive
    case suspended
    case deleted
}

// MARK: - UserPreferenceKey
/// Keys for user preference settings
/// Requirement: Privacy controls - User preferences management
enum UserPreferenceKey: String, Codable {
    case notificationsEnabled
    case locationSharingEnabled
    case darkModeEnabled
    case languageCode
    case radiusPreference
}

// MARK: - User
/// Main user model class representing a user in the Founditure application
/// Requirement: User registration and authentication - Core data model for user authentication and profile management
@objc
@objcMembers
class User: NSObject {
    // MARK: - Properties
    
    let id: UUID
    let email: String
    let fullName: String
    var phoneNumber: String?
    var profileImageUrl: String
    var totalPoints: Int
    var currentStreak: Int
    var lastKnownLocation: Location
    var privacySettings: PrivacySettings
    let createdAt: Date
    var lastLoginAt: Date
    var isVerified: Bool
    var isActive: Bool
    var preferences: [String: Any]
    
    // MARK: - Initialization
    
    /// Initializes a new user instance
    /// - Parameters:
    ///   - email: User's email address
    ///   - fullName: User's full name
    ///   - phoneNumber: Optional phone number
    ///   - location: Optional initial location
    init(email: String, fullName: String, phoneNumber: String? = nil, location: Location? = nil) {
        // Generate new UUID for id
        self.id = UUID()
        
        // Set current timestamp for createdAt
        self.createdAt = Date()
        
        // Initialize user with provided data
        self.email = email
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.profileImageUrl = ""
        
        // Set default values for points and streak
        self.totalPoints = 0
        self.currentStreak = 0
        
        // Initialize location with default or provided value
        self.lastKnownLocation = location ?? Location(
            userId: id,
            coordinates: Coordinates(latitude: 0, longitude: 0, accuracy: nil, altitude: nil),
            address: "",
            city: "",
            state: "",
            country: "",
            postalCode: "",
            type: .userLocation,
            privacySettings: PrivacySettings(
                visibilityLevel: .approximate,
                blurRadius: 1000,
                hideExactLocation: true
            )
        )
        
        // Initialize privacy settings with default values
        self.privacySettings = PrivacySettings(
            visibilityLevel: .approximate,
            blurRadius: 1000,
            hideExactLocation: true
        )
        
        // Set isVerified and isActive to false by default
        self.isVerified = false
        self.isActive = false
        
        self.lastLoginAt = Date()
        
        // Initialize default preferences
        self.preferences = [
            UserPreferenceKey.notificationsEnabled.rawValue: true,
            UserPreferenceKey.locationSharingEnabled.rawValue: false,
            UserPreferenceKey.darkModeEnabled.rawValue: false,
            UserPreferenceKey.languageCode.rawValue: "en",
            UserPreferenceKey.radiusPreference.rawValue: Location.defaultRadius
        ]
        
        super.init()
    }
    
    // MARK: - Points Management
    
    /// Updates user points based on activity
    /// Requirement: Points system and leaderboards - Integration with points system for user achievements
    /// - Parameter point: Point transaction to process
    /// - Returns: New total points value
    func updatePoints(point: Point) -> Int {
        // Validate point transaction
        guard point.userId == id && !point.isProcessed else {
            return totalPoints
        }
        
        // Apply streak multiplier if applicable
        let multiplier = point.calculateMultiplier()
        let pointValue = Int(Double(point.value) * multiplier)
        
        // Update total points
        totalPoints += pointValue
        
        // Update streak if daily bonus
        if point.type == PointType.dailyBonus.rawValue {
            currentStreak += 1
        }
        
        // Return new points total
        return totalPoints
    }
    
    // MARK: - Location Management
    
    /// Updates user's last known location
    /// Requirement: Privacy controls - User privacy settings and preferences management
    /// - Parameter newLocation: New location to update
    func updateLocation(newLocation: Location) {
        // Apply privacy settings to location
        let privacyAdjustedLocation = newLocation.withPrivacyApplied()
        
        // Update lastKnownLocation
        lastKnownLocation = privacyAdjustedLocation
        
        // Trigger location update notifications
        NotificationCenter.default.post(
            name: NSNotification.Name("UserLocationUpdated"),
            object: self,
            userInfo: ["location": privacyAdjustedLocation]
        )
    }
    
    // MARK: - Privacy Management
    
    /// Updates user privacy preferences
    /// Requirement: Privacy controls - User privacy settings and preferences management
    /// - Parameter settings: New privacy settings to apply
    func updatePrivacySettings(settings: PrivacySettings) {
        // Validate new privacy settings
        guard settings.blurRadius >= 0 else { return }
        
        // Update privacy configuration
        privacySettings = settings
        
        // Apply changes to location sharing
        if settings.hideExactLocation {
            preferences[UserPreferenceKey.locationSharingEnabled.rawValue] = false
        }
        
        // Update user preferences
        preferences["privacyUpdatedAt"] = Date()
    }
}

// MARK: - Codable Extension
extension User: Codable {
    enum CodingKeys: String, CodingKey {
        case id, email, fullName, phoneNumber, profileImageUrl
        case totalPoints, currentStreak, lastKnownLocation
        case privacySettings, createdAt, lastLoginAt
        case isVerified, isActive, preferences
    }
}

// MARK: - Identifiable Extension
extension User: Identifiable {}

// MARK: - Equatable Extension
extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}