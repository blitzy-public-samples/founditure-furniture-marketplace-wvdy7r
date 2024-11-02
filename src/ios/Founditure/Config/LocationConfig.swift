//
// LocationConfig.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify "Privacy - Location When In Use Usage Description" is set in Info.plist
// 2. Verify "Privacy - Location Always and When In Use Usage Description" is set in Info.plist
// 3. Enable background location updates capability in Xcode project settings
// 4. Configure location usage description strings in localization files

// CoreLocation framework - iOS 14.0+
import CoreLocation
// Foundation framework - iOS 14.0+
import Foundation

// Import internal dependencies
import AppConstants

// MARK: - Location Accuracy Level
/// Defines different accuracy levels for location tracking
/// Requirement: Location Services - Configures location services with privacy controls and battery optimization
public enum LocationAccuracyLevel {
    case high
    case balanced
    case low
    case minimal
    
    var desiredAccuracy: CLLocationAccuracy {
        switch self {
        case .high:
            return kCLLocationAccuracyBest
        case .balanced:
            return kCLLocationAccuracyNearestTenMeters
        case .low:
            return kCLLocationAccuracyHundredMeters
        case .minimal:
            return kCLLocationAccuracyKilometer
        }
    }
    
    var updateInterval: TimeInterval {
        switch self {
        case .high:
            return 60 // 1 minute
        case .balanced:
            return 300 // 5 minutes
        case .low:
            return 900 // 15 minutes
        case .minimal:
            return 1800 // 30 minutes
        }
    }
}

// MARK: - Location Update Frequency
/// Defines update frequency modes for location tracking
/// Requirement: Location Services - Configures battery-optimized location update frequencies
public enum LocationUpdateFrequency {
    case realtime
    case normal
    case battery_saving
    case manual
    
    var interval: TimeInterval {
        switch self {
        case .realtime:
            return 5 // 5 seconds
        case .normal:
            return AppConstants.Location.updateInterval
        case .battery_saving:
            return 1800 // 30 minutes
        case .manual:
            return Double.infinity
        }
    }
    
    var distanceFilter: CLLocationDistance {
        switch self {
        case .realtime:
            return 5 // 5 meters
        case .normal:
            return 100 // 100 meters
        case .battery_saving:
            return 500 // 500 meters
        case .manual:
            return CLLocationDistanceMax
        }
    }
}

// MARK: - Privacy Zone Type
/// Defines types of privacy zones for location obfuscation
/// Requirement: Privacy Controls - Configures location privacy zones and precision levels
public enum PrivacyZoneType {
    case none
    case approximate
    case radius
    case custom
}

// MARK: - Location Service Configuration
/// Configuration structure for location service settings
/// Requirement: Location-based Search - Defines search radius and accuracy parameters for furniture discovery
public struct LocationServiceConfig {
    let defaultSearchRadius: CLLocationDistance
    let minimumSearchRadius: CLLocationDistance
    let maximumSearchRadius: CLLocationDistance
    let defaultAccuracy: CLLocationAccuracy
    let defaultUpdateInterval: TimeInterval
    let significantLocationChangeDistance: CLLocationDistance
    let geofenceRadius: CLLocationDistance
    let backgroundUpdatesEnabled: Bool
}

// MARK: - Global Configuration Constants
/// Default location service configuration
public let DEFAULT_LOCATION_CONFIG = LocationServiceConfig(
    defaultSearchRadius: AppConstants.Location.defaultRadius,
    minimumSearchRadius: AppConstants.Location.minRadius,
    maximumSearchRadius: AppConstants.Location.maxRadius,
    defaultAccuracy: kCLLocationAccuracyNearestTenMeters,
    defaultUpdateInterval: AppConstants.Location.updateInterval,
    significantLocationChangeDistance: 500.0,
    geofenceRadius: AppConstants.Location.geofenceRadius,
    backgroundUpdatesEnabled: true
)

/// Default privacy zone radius in meters
public let PRIVACY_ZONE_RADIUS: CLLocationDistance = 200.0

/// Location cache duration in seconds (24 hours)
public let LOCATION_CACHE_DURATION: TimeInterval = 86400

// MARK: - Accuracy Level Calculator
/// Returns appropriate accuracy level based on app state and battery level
/// Requirement: Location Services - Configures battery-optimized location services
public func getAccuracyLevel(isBackgrounded: Bool, batteryLevel: Float) -> LocationAccuracyLevel {
    // Check if app is backgrounded
    if isBackgrounded {
        return .minimal
    }
    
    // Check battery level and return appropriate accuracy
    switch batteryLevel {
    case 0..<0.15: // Below 15%
        return .minimal
    case 0.15..<0.30: // 15-30%
        return .low
    case 0.30..<0.70: // 30-70%
        return .balanced
    default: // Above 70%
        return .high
    }
}