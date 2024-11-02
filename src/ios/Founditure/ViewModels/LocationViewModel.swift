//
// LocationViewModel.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify location permissions are properly configured in Info.plist
// 2. Configure location usage description strings in localization files
// 3. Enable background location updates capability in Xcode project settings
// 4. Review and adjust privacy zone radius values for different regions
// 5. Set up analytics for location tracking events

import Combine // iOS 14.0+
import CoreLocation // iOS 14.0+
import Foundation

/// ViewModel responsible for managing location-related state and business logic
/// Requirement: Location Services - Implements location services with offline-first architecture
@MainActor
final class LocationViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    
    /// Current user location with privacy settings applied
    /// Requirement: Location Services - Provides real-time location updates
    @Published private(set) var currentLocation: Location?
    
    /// List of nearby furniture locations
    /// Requirement: Location-based Search - Enables furniture discovery based on user location
    @Published private(set) var nearbyFurniture: [Location] = []
    
    /// Current privacy zone setting for location sharing
    /// Requirement: Privacy Controls - Implements location privacy measures
    @Published var privacyZoneType: PrivacyZoneType = .approximate {
        didSet {
            Task {
                await updatePrivacySettings(zoneType: privacyZoneType)
            }
        }
    }
    
    /// Location accuracy level setting
    /// Requirement: Location Services - Configurable location accuracy
    @Published var accuracyLevel: LocationAccuracyLevel = .balanced {
        didSet {
            if isUpdatingLocation {
                Task {
                    await startLocationUpdates()
                }
            }
        }
    }
    
    /// Indicates if location permission is granted
    /// Requirement: Privacy Controls - Location permission management
    @Published private(set) var locationPermissionGranted: Bool = false
    
    // MARK: - ViewModelProtocol Properties
    
    /// Loading state indicator
    @Published private(set) var isLoading: Bool = false
    
    /// Current error state
    @Published private(set) var error: Error?
    
    /// Reference to global application state
    let appState: AppState
    
    // MARK: - Private Properties
    
    /// Location service instance
    private let locationService: LocationService
    
    /// Set of active Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Flag indicating if location updates are active
    private var isUpdatingLocation: Bool = false
    
    // MARK: - Initialization
    
    /// Initializes the LocationViewModel with required dependencies
    /// - Parameters:
    ///   - appState: Global application state
    ///   - locationService: Location service instance
    required init(appState: AppState, locationService: LocationService = LocationService()) {
        self.appState = appState
        self.locationService = locationService
        
        super.init(appState: appState)
        
        // Set initial privacy settings from app state
        self.privacyZoneType = appState.userPreferences.defaultPrivacyZone
        self.accuracyLevel = appState.userPreferences.defaultAccuracyLevel
        
        // Setup location service delegate
        locationService.delegate = self
        
        // Setup subscriptions
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Starts location tracking with current settings
    /// Requirement: Location Services - Implements location services with offline-first architecture
    func startLocationUpdates() async {
        guard !isUpdatingLocation else { return }
        
        isLoading = true
        isUpdatingLocation = true
        
        do {
            // Start location updates with current settings
            try await locationService.startLocationUpdates(
                accuracy: accuracyLevel,
                privacyZone: privacyZoneType
            ).sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.handleError(error)
                    self.isUpdatingLocation = false
                }
            } receiveValue: { [weak self] location in
                guard let self = self else { return }
                // Convert CLLocation to Location model
                self.updateCurrentLocation(from: location)
            }.store(in: &cancellables)
            
            // Update permission state
            locationPermissionGranted = true
            
        } catch {
            handleError(error)
            isUpdatingLocation = false
            locationPermissionGranted = false
        }
        
        isLoading = false
    }
    
    /// Stops location tracking
    /// Requirement: Privacy Controls - Implements location privacy measures
    func stopLocationUpdates() {
        guard isUpdatingLocation else { return }
        
        locationService.stopLocationUpdates()
        isUpdatingLocation = false
        currentLocation = nil
        
        // Clear nearby furniture
        nearbyFurniture.removeAll()
        
        // Cancel location subscriptions
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    /// Initiates search for nearby furniture
    /// Requirement: Location-based Search - Enables furniture discovery based on user location
    func searchNearbyFurniture(radius: CLLocationDistance) async {
        guard let currentLocation = currentLocation else {
            handleError(NSError(domain: "LocationViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current location available"]))
            return
        }
        
        isLoading = true
        
        do {
            // Search for furniture with privacy settings applied
            let locations = try await locationService.searchFurnitureNearby(radius: radius)
                .sink { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.handleError(error)
                    }
                } receiveValue: { [weak self] furnitureLocations in
                    guard let self = self else { return }
                    // Update nearby furniture with privacy settings applied
                    self.nearbyFurniture = furnitureLocations.map { location in
                        location.withPrivacyApplied()
                    }
                }.store(in: &cancellables)
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Updates location privacy configuration
    /// Requirement: Privacy Controls - Implements location privacy and data protection measures
    private func updatePrivacySettings(zoneType: PrivacyZoneType) async {
        isLoading = true
        
        // Update location service privacy settings
        locationService.updatePrivacyZone(zoneType)
        
        // Update current location with new privacy settings
        if let location = currentLocation {
            currentLocation = location.withPrivacyApplied()
        }
        
        // Refresh nearby furniture with new privacy settings
        if !nearbyFurniture.isEmpty {
            await searchNearbyFurniture(radius: DEFAULT_LOCATION_CONFIG.defaultSearchRadius)
        }
        
        // Update app state preferences
        await appState.updateUserPreferences(privacyZone: zoneType)
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    /// Updates current location from CLLocation
    private func updateCurrentLocation(from clLocation: CLLocation) {
        let location = Location(
            userId: appState.currentUser?.id ?? UUID(),
            coordinates: Coordinates(
                latitude: clLocation.coordinate.latitude,
                longitude: clLocation.coordinate.longitude,
                accuracy: clLocation.horizontalAccuracy,
                altitude: clLocation.altitude
            ),
            address: "", // Address will be reverse geocoded
            city: "",
            state: "",
            country: "",
            postalCode: "",
            type: .userLocation,
            privacySettings: PrivacySettings(
                visibilityLevel: privacyZoneType,
                blurRadius: DEFAULT_LOCATION_CONFIG.privacyBlurRadius,
                hideExactLocation: privacyZoneType != .none
            )
        )
        
        currentLocation = location.withPrivacyApplied()
    }
    
    // MARK: - ViewModelProtocol Methods
    
    /// Sets up Combine publishers and subscribers
    func setupSubscriptions() {
        // Observe app state changes
        appState.$userPreferences
            .sink { [weak self] preferences in
                guard let self = self else { return }
                // Update privacy settings if changed
                if preferences.defaultPrivacyZone != self.privacyZoneType {
                    self.privacyZoneType = preferences.defaultPrivacyZone
                }
                // Update accuracy level if changed
                if preferences.defaultAccuracyLevel != self.accuracyLevel {
                    self.accuracyLevel = preferences.defaultAccuracyLevel
                }
            }
            .store(in: &cancellables)
    }
    
    /// Performs cleanup when ViewModel is deallocated
    func cleanUp() {
        stopLocationUpdates()
        cancellables.removeAll()
    }
}

// MARK: - LocationServiceDelegate

extension LocationViewModel: LocationServiceDelegate {
    /// Handles location update events
    /// Requirement: Location Services - Implements location services with offline-first architecture
    func didUpdateLocation(_ location: CLLocation) {
        updateCurrentLocation(from: location)
    }
    
    /// Handles region entry events
    /// Requirement: Location-based Search - Enables furniture discovery based on user location
    func didEnterRegion(_ regionId: UUID) {
        Task {
            await searchNearbyFurniture(radius: DEFAULT_LOCATION_CONFIG.defaultSearchRadius)
        }
    }
}