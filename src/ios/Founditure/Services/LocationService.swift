//
// LocationService.swift
// Founditure
//
// MARK: - Human Tasks
/*
 TODO: Human Configuration Required
 1. Verify "Privacy - Location When In Use Usage Description" is set in Info.plist
 2. Verify "Privacy - Location Always and When In Use Usage Description" is set in Info.plist
 3. Enable background location updates capability in Xcode project settings
 4. Configure location usage description strings in localization files
 5. Add NSLocationAlwaysAndWhenInUseUsageDescription to Info.plist
 6. Add NSLocationWhenInUseUsageDescription to Info.plist
*/

import CoreLocation // iOS 14.0+
import Combine // iOS 14.0+
import Foundation

// MARK: - LocationServiceDelegate Protocol
/// Delegate protocol for location service events
@available(iOS 14.0, *)
protocol LocationServiceDelegate: AnyObject {
    /// Called when location is updated
    func didUpdateLocation(_ location: CLLocation)
    
    /// Called when entering a furniture search region
    func didEnterRegion(_ regionId: UUID)
}

// MARK: - LocationService Class
/// Service class implementing location-based features with privacy controls and offline support
@available(iOS 14.0, *)
final class LocationService: ServiceProtocol {
    // MARK: - Properties
    
    /// Base URL for location-related API endpoints
    let baseURL: String
    
    /// URLSession for network requests
    let session: URLSession
    
    /// Reference to shared location manager
    private let locationManager: LocationManager
    
    /// Publisher for current location updates
    private let currentLocation = CurrentValueSubject<CLLocation?, Never>(nil)
    
    /// Set of active search region identifiers
    private var activeSearchRegions: Set<UUID>
    
    /// Current location accuracy level
    private var accuracyLevel: LocationAccuracyLevel
    
    /// Current privacy zone setting
    private var privacyZone: PrivacyZoneType
    
    /// Delegate for location events
    weak var delegate: LocationServiceDelegate?
    
    // MARK: - Initialization
    
    /// Initializes the location service with default settings
    init() {
        // Initialize location manager reference
        self.locationManager = LocationManager.shared
        
        // Initialize network components
        self.baseURL = "api/v1/location"
        self.session = URLSession.shared
        
        // Initialize tracking properties
        self.activeSearchRegions = Set<UUID>()
        self.accuracyLevel = .balanced
        self.privacyZone = .none
        
        // Set up location publishers
        setupLocationObservers()
    }
    
    // MARK: - Private Methods
    
    /// Sets up location update observers
    private func setupLocationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRegionEntry(_:)),
            name: Notification.Name(rawValue: "furnitureNearby"),
            object: nil
        )
    }
    
    /// Handles region entry notifications
    @objc private func handleRegionEntry(_ notification: Notification) {
        guard let region = notification.userInfo?["region"] as? CLCircularRegion,
              let regionId = UUID(uuidString: region.identifier) else { return }
        
        delegate?.didEnterRegion(regionId)
    }
    
    /// Applies privacy zone to location
    private func applyPrivacyZone(to location: CLLocation) -> CLLocation {
        switch privacyZone {
        case .none:
            return location
        case .approximate:
            // Round coordinates to lower precision
            let roundedLat = round(location.coordinate.latitude * 100) / 100
            let roundedLng = round(location.coordinate.longitude * 100) / 100
            return CLLocation(latitude: roundedLat, longitude: roundedLng)
        case .radius:
            // Add random offset within privacy radius
            let randomAngle = Double.random(in: 0...(2 * .pi))
            let randomDistance = Double.random(in: 0...PRIVACY_ZONE_RADIUS)
            return location.coordinate.location(at: randomDistance, bearing: randomAngle)
        case .custom:
            // Use custom privacy zone logic
            return location
        }
    }
    
    // MARK: - Public Methods
    
    /// Begins location tracking with specified accuracy and privacy settings
    /// - Parameters:
    ///   - accuracy: Desired location accuracy level
    ///   - privacyZone: Type of privacy zone to apply
    /// - Returns: Publisher emitting location updates
    func startLocationUpdates(accuracy: LocationAccuracyLevel, privacyZone: PrivacyZoneType) -> AnyPublisher<CLLocation, Error> {
        // Update settings
        self.accuracyLevel = accuracy
        self.privacyZone = privacyZone
        
        // Request location permissions
        return locationManager.requestLocationPermission(requirePrecise: accuracy == .high)
            .flatMap { [weak self] granted -> AnyPublisher<CLLocation, Error> in
                guard let self = self else {
                    return Fail(error: ServiceError.unknownError).eraseToAnyPublisher()
                }
                
                // Start location updates with specified accuracy
                return self.locationManager.startUpdatingLocation(accuracyLevel: accuracy)
                    .map { [weak self] location -> CLLocation in
                        guard let self = self else { return location }
                        // Apply privacy zone if enabled
                        let processedLocation = self.applyPrivacyZone(to: location)
                        // Update current location
                        self.currentLocation.send(processedLocation)
                        // Notify delegate
                        self.delegate?.didUpdateLocation(processedLocation)
                        return processedLocation
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// Stops location tracking and clears active regions
    func stopLocationUpdates() {
        // Stop location manager updates
        locationManager.stopUpdatingLocation()
        
        // Clear active search regions
        activeSearchRegions.removeAll()
        
        // Reset location publishers
        currentLocation.send(nil)
    }
    
    /// Initiates furniture search in the specified radius
    /// - Parameter radius: Search radius in meters
    /// - Returns: Publisher emitting nearby furniture locations
    func searchFurnitureNearby(radius: CLLocationDistance) -> AnyPublisher<[FurnitureLocation], Error> {
        // Validate search radius
        guard radius >= DEFAULT_LOCATION_CONFIG.minimumSearchRadius,
              radius <= DEFAULT_LOCATION_CONFIG.maximumSearchRadius else {
            return Fail(error: ServiceError.validationError).eraseToAnyPublisher()
        }
        
        // Get current location
        guard let location = currentLocation.value else {
            return Fail(error: ServiceError.validationError).eraseToAnyPublisher()
        }
        
        // Apply privacy zone if enabled
        let searchLocation = applyPrivacyZone(to: location)
        
        // Create search region
        let regionId = locationManager.startMonitoringRegion(
            coordinate: searchLocation.coordinate,
            radius: radius
        )
        activeSearchRegions.insert(regionId)
        
        // Create and configure request
        var components = URLComponents(string: baseURL + "/search")
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(searchLocation.coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(searchLocation.coordinate.longitude)),
            URLQueryItem(name: "radius", value: String(radius))
        ]
        
        guard let url = components?.url else {
            return Fail(error: ServiceError.validationError).eraseToAnyPublisher()
        }
        
        let request = URLRequest(url: url)
        
        // Return search results publisher
        return performRequest(request: request)
            .mapError { [weak self] error -> Error in
                // Clean up region on error
                if let self = self {
                    self.activeSearchRegions.remove(regionId)
                }
                return error
            }
            .eraseToAnyPublisher()
    }
    
    /// Updates location privacy settings
    /// - Parameter zoneType: Type of privacy zone to apply
    func updatePrivacyZone(_ zoneType: PrivacyZoneType) {
        // Update privacy zone setting
        self.privacyZone = zoneType
        
        // Apply to active location updates
        if let location = currentLocation.value {
            let processedLocation = applyPrivacyZone(to: location)
            currentLocation.send(processedLocation)
            delegate?.didUpdateLocation(processedLocation)
        }
        
        // Update search regions if needed
        if !activeSearchRegions.isEmpty {
            // Re-create active search regions with new privacy settings
            let regions = activeSearchRegions
            activeSearchRegions.removeAll()
            
            for regionId in regions {
                if let location = currentLocation.value {
                    let newRegionId = locationManager.startMonitoringRegion(
                        coordinate: location.coordinate,
                        radius: DEFAULT_LOCATION_CONFIG.defaultSearchRadius
                    )
                    activeSearchRegions.insert(newRegionId)
                }
            }
        }
    }
}

// MARK: - CLLocation Extension
private extension CLLocationCoordinate2D {
    /// Returns a new location at specified distance and bearing from current location
    func location(at distance: CLLocationDistance, bearing: Double) -> CLLocation {
        let earthRadius = 6371000.0 // Earth radius in meters
        
        let lat1 = latitude * .pi / 180
        let lon1 = longitude * .pi / 180
        
        let angularDistance = distance / earthRadius
        
        let lat2 = asin(sin(lat1) * cos(angularDistance) +
                       cos(lat1) * sin(angularDistance) * cos(bearing))
        
        let lon2 = lon1 + atan2(sin(bearing) * sin(angularDistance) * cos(lat1),
                               cos(angularDistance) - sin(lat1) * sin(lat2))
        
        return CLLocation(
            latitude: lat2 * 180 / .pi,
            longitude: lon2 * 180 / .pi
        )
    }
}