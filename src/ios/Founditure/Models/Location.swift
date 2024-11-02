//
// Location.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify CoreLocation permissions are properly configured in Info.plist
// 2. Ensure location privacy settings are documented in user privacy policy
// 3. Configure appropriate location usage strings in localization files
// 4. Review and adjust privacy zone radius values for different regions

// CoreLocation framework - iOS 14.0+
import CoreLocation
// Foundation framework - iOS 14.0+
import Foundation

// Import internal dependencies
import LocationConfig

// MARK: - LocationType
/// Defines different types of locations in the system
/// Requirement: Location Services - Supports different location types for furniture discovery
public enum LocationType: String, Codable {
    case pickupPoint
    case dropOffPoint
    case userLocation
    case furnitureLocation
    case meetingPoint
}

// MARK: - Coordinates
/// Structure representing geographic coordinates
/// Requirement: Location Services - Core location data structure
public struct Coordinates: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double?
    let altitude: Double?
}

// MARK: - PrivacySettings
/// Structure defining location privacy configuration
/// Requirement: Privacy Controls - Location privacy settings and data protection
public struct PrivacySettings: Codable {
    let visibilityLevel: PrivacyZoneType
    let blurRadius: Double
    let hideExactLocation: Bool
}

// MARK: - Location
/// Main location model structure
/// Requirement: Location Services - Core location model with offline-first architecture
public struct Location: Codable, Identifiable, Equatable {
    // MARK: - Properties
    public let id: UUID
    public let userId: UUID
    public let coordinates: Coordinates
    public let address: String
    public let city: String
    public let state: String
    public let country: String
    public let postalCode: String
    public let type: LocationType
    public let privacySettings: PrivacySettings
    public let createdAt: Date
    public let updatedAt: Date
    
    // MARK: - Initialization
    public init(
        id: UUID = UUID(),
        userId: UUID,
        coordinates: Coordinates,
        address: String,
        city: String,
        state: String,
        country: String,
        postalCode: String,
        type: LocationType,
        privacySettings: PrivacySettings,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.coordinates = coordinates
        self.address = address
        self.city = city
        self.state = state
        self.country = country
        self.postalCode = postalCode
        self.type = type
        self.privacySettings = privacySettings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Public Methods
    
    /// Converts to CLLocation for CoreLocation compatibility
    /// Requirement: Location Services - Integration with iOS location services
    public func toCLLocation() -> CLLocation {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            ),
            altitude: coordinates.altitude ?? 0,
            horizontalAccuracy: coordinates.accuracy ?? -1,
            verticalAccuracy: -1,
            timestamp: updatedAt
        )
        return location
    }
    
    /// Calculates distance to another location
    /// Requirement: Location-based Search - Geospatial search capabilities
    public func distanceTo(_ other: Location) -> CLLocationDistance {
        let selfLocation = self.toCLLocation()
        let otherLocation = other.toCLLocation()
        return selfLocation.distance(from: otherLocation)
    }
    
    /// Returns a privacy-adjusted copy of the location
    /// Requirement: Privacy Controls - Location data protection mechanisms
    public func withPrivacyApplied() -> Location {
        guard privacySettings.hideExactLocation else {
            return self
        }
        
        var adjustedCoordinates = coordinates
        
        switch privacySettings.visibilityLevel {
        case .none:
            return self
            
        case .approximate:
            // Round coordinates to lower precision
            let precision = 0.01 // Approximately 1km
            adjustedCoordinates = Coordinates(
                latitude: Double(round(coordinates.latitude / precision) * precision),
                longitude: Double(round(coordinates.longitude / precision) * precision),
                accuracy: coordinates.accuracy,
                altitude: nil
            )
            
        case .radius:
            // Add random offset within blur radius
            let radiusInDegrees = privacySettings.blurRadius / 111000 // Convert meters to degrees
            let randomAngle = Double.random(in: 0..<2 * .pi)
            let randomRadius = Double.random(in: 0..<radiusInDegrees)
            
            adjustedCoordinates = Coordinates(
                latitude: coordinates.latitude + (randomRadius * cos(randomAngle)),
                longitude: coordinates.longitude + (randomRadius * sin(randomAngle)),
                accuracy: privacySettings.blurRadius,
                altitude: nil
            )
            
        case .custom:
            // Use custom privacy zone settings
            let customRadius = max(PRIVACY_ZONE_RADIUS, privacySettings.blurRadius)
            let radiusInDegrees = customRadius / 111000
            let randomAngle = Double.random(in: 0..<2 * .pi)
            let randomRadius = Double.random(in: 0..<radiusInDegrees)
            
            adjustedCoordinates = Coordinates(
                latitude: coordinates.latitude + (randomRadius * cos(randomAngle)),
                longitude: coordinates.longitude + (randomRadius * sin(randomAngle)),
                accuracy: customRadius,
                altitude: nil
            )
        }
        
        return Location(
            id: id,
            userId: userId,
            coordinates: adjustedCoordinates,
            address: address,
            city: city,
            state: state,
            country: country,
            postalCode: postalCode,
            type: type,
            privacySettings: privacySettings,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Equatable Implementation
extension Location {
    public static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.id == rhs.id &&
            lhs.userId == rhs.userId &&
            lhs.coordinates.latitude == rhs.coordinates.latitude &&
            lhs.coordinates.longitude == rhs.coordinates.longitude &&
            lhs.type == rhs.type
    }
}