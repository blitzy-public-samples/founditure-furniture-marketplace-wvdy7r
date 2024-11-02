//
// LocationManager.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify "Privacy - Location When In Use Usage Description" is set in Info.plist
// 2. Verify "Privacy - Location Always and When In Use Usage Description" is set in Info.plist
// 3. Enable background location updates capability in Xcode project settings
// 4. Configure location usage description strings in localization files
// 5. Add NSLocationAlwaysAndWhenInUseUsageDescription to Info.plist
// 6. Add NSLocationWhenInUseUsageDescription to Info.plist

// CoreLocation framework - iOS 14.0+
import CoreLocation
// Combine framework - iOS 14.0+
import Combine
// Foundation framework - iOS 14.0+
import Foundation

// Import internal dependencies
import AppConstants

/// A singleton manager class that handles location services for the iOS app
/// Requirement: Location Services - Implements location services with offline-first architecture
final class LocationManager: NSObject {
    
    // MARK: - Singleton
    
    /// Shared instance of LocationManager
    /// Requirement: Location Services - Provides centralized location service management
    static let shared = LocationManager()
    
    // MARK: - Properties
    
    /// Core Location manager instance
    private let locationManager: CLLocationManager
    
    /// Publisher for location updates
    /// Requirement: Location-based Search - Enables furniture discovery based on user location
    private let locationPublisher = PassthroughSubject<CLLocation, Error>()
    
    /// Set of active geofence region identifiers
    private var activeGeofences: Set<UUID>
    
    /// Flag indicating if location updates are active
    private var isUpdatingLocation: Bool
    
    /// Current location accuracy level
    private var currentAccuracyLevel: LocationAccuracyLevel
    
    // MARK: - Initialization
    
    private override init() {
        // Initialize properties
        self.locationManager = CLLocationManager()
        self.activeGeofences = Set<UUID>()
        self.isUpdatingLocation = false
        self.currentAccuracyLevel = .balanced
        
        super.init()
        
        // Configure location manager
        configureLocationManager()
    }
    
    // MARK: - Private Methods
    
    /// Configures the CLLocationManager instance
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = LocationAccuracyLevel.balanced.desiredAccuracy
        locationManager.distanceFilter = LocationUpdateFrequency.normal.distanceFilter
        locationManager.allowsBackgroundLocationUpdates = DEFAULT_LOCATION_CONFIG.backgroundUpdatesEnabled
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    /// Updates location manager settings based on accuracy level
    /// Requirement: Privacy Controls - Implements location privacy and data protection measures
    private func updateLocationSettings(for accuracyLevel: LocationAccuracyLevel) {
        locationManager.desiredAccuracy = accuracyLevel.desiredAccuracy
        locationManager.distanceFilter = LocationUpdateFrequency.normal.distanceFilter
        currentAccuracyLevel = accuracyLevel
    }
    
    // MARK: - Public Methods
    
    /// Starts updating location with specified accuracy level
    /// Requirement: Location Services - Implements location services with offline-first architecture
    func startUpdatingLocation(accuracyLevel: LocationAccuracyLevel) -> AnyPublisher<CLLocation, Error> {
        // Check authorization status
        guard CLLocationManager.locationServicesEnabled() else {
            return Fail(error: NSError(domain: "LocationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location services are disabled"]))
                .eraseToAnyPublisher()
        }
        
        // Update settings for requested accuracy level
        updateLocationSettings(for: accuracyLevel)
        
        // Start location updates
        locationManager.startUpdatingLocation()
        isUpdatingLocation = true
        
        return locationPublisher.eraseToAnyPublisher()
    }
    
    /// Stops location updates
    /// Requirement: Privacy Controls - Implements location privacy measures
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isUpdatingLocation = false
        activeGeofences.removeAll()
    }
    
    /// Starts monitoring a geographic region for furniture
    /// Requirement: Location-based Search - Enables furniture discovery based on user location
    func startMonitoringRegion(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) -> UUID {
        let identifier = UUID()
        let region = CLCircularRegion(
            center: coordinate,
            radius: min(radius, locationManager.maximumRegionMonitoringDistance),
            identifier: identifier.uuidString
        )
        
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
        activeGeofences.insert(identifier)
        
        return identifier
    }
    
    /// Requests location authorization from user
    /// Requirement: Privacy Controls - Implements location privacy and data protection measures
    func requestLocationPermission(requirePrecise: Bool) -> Future<Bool, Error> {
        return Future { promise in
            let currentStatus = CLLocationManager.authorizationStatus()
            
            // Check if we already have appropriate authorization
            switch currentStatus {
            case .authorizedAlways:
                promise(.success(true))
                return
            case .authorizedWhenInUse where !requirePrecise:
                promise(.success(true))
                return
            default:
                break
            }
            
            // Request appropriate authorization
            if requirePrecise {
                self.locationManager.requestAlwaysAuthorization()
            } else {
                self.locationManager.requestWhenInUseAuthorization()
            }
            
            // Observe authorization status changes
            NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
                let status = CLLocationManager.authorizationStatus()
                switch status {
                case .authorizedAlways, .authorizedWhenInUse:
                    promise(.success(true))
                case .denied, .restricted:
                    promise(.failure(NSError(domain: "LocationManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Location access denied"])))
                default:
                    break
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    /// Handles location update events
    /// Requirement: Location Services - Implements location services with offline-first architecture
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Validate location accuracy
        guard location.horizontalAccuracy <= AppConstants.Location.accuracyThreshold else { return }
        
        // Publish location update
        locationPublisher.send(location)
    }
    
    /// Handles location manager errors
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationPublisher.send(completion: .failure(error))
    }
    
    /// Handles changes in authorization status
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            if isUpdatingLocation {
                manager.startUpdatingLocation()
            }
        case .denied, .restricted:
            stopUpdatingLocation()
            locationPublisher.send(completion: .failure(NSError(domain: "LocationManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Location access denied"])))
        default:
            break
        }
    }
    
    /// Handles region monitoring events
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        NotificationCenter.default.post(
            name: Notification.Name(AppConstants.Notification.furnitureNearby),
            object: nil,
            userInfo: ["region": circularRegion]
        )
    }
}