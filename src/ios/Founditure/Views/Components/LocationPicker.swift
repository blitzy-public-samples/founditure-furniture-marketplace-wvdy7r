//
// LocationPicker.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify "Privacy - Location When In Use Usage Description" is set in Info.plist
// 2. Verify "Privacy - Location Always and When In Use Usage Description" is set in Info.plist
// 3. Enable background location updates capability in Xcode project settings
// 4. Configure location usage description strings in localization files

// SwiftUI framework - iOS 14.0+
import SwiftUI
// MapKit framework - iOS 14.0+
import MapKit
// Combine framework - iOS 14.0+
import Combine

/// A SwiftUI view component for location selection and radius adjustment
/// Requirement: Location-based Search - Enables furniture discovery based on user location with configurable search radius
struct LocationPicker: View {
    // MARK: - Properties
    
    /// Binding for the selected location coordinate
    @Binding private var selectedLocation: CLLocationCoordinate2D
    
    /// Binding for the search radius in meters
    @Binding private var searchRadius: Double
    
    /// Binding for the privacy zone type
    @Binding private var privacyZone: PrivacyZoneType
    
    /// Location manager instance for handling location services
    @StateObject private var locationManager = LocationManager.shared
    
    /// State for map expansion
    @State private var isMapExpanded: Bool = false
    
    /// State for radius editing
    @State private var isEditingRadius: Bool = false
    
    /// Region for the map view
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    /// Cancellable for location updates
    private var locationCancellable: AnyCancellable?
    
    // MARK: - Initialization
    
    /// Initializes the location picker with bindings
    /// - Parameters:
    ///   - selectedLocation: Binding for the selected location coordinate
    ///   - searchRadius: Binding for the search radius
    ///   - privacyZone: Binding for the privacy zone type
    init(selectedLocation: Binding<CLLocationCoordinate2D>,
         searchRadius: Binding<Double>,
         privacyZone: Binding<PrivacyZoneType>) {
        self._selectedLocation = selectedLocation
        self._searchRadius = searchRadius
        self._privacyZone = privacyZone
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Map view with location pin
            ZStack {
                Map(coordinateRegion: $region, showsUserLocation: true)
                    .frame(height: isMapExpanded ? UIScreen.main.bounds.height * 0.6 : 200)
                    .cornerRadius(12)
                    .onTapGesture {
                        withAnimation {
                            isMapExpanded.toggle()
                        }
                    }
                
                // Location pin
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
                    .background(Color.white.clipShape(Circle()))
            }
            
            // Search radius slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Search Radius")
                    .font(.headline)
                
                HStack {
                    Slider(
                        value: $searchRadius,
                        in: DEFAULT_LOCATION_CONFIG.minimumSearchRadius...DEFAULT_LOCATION_CONFIG.maximumSearchRadius,
                        step: 500,
                        onEditingChanged: { editing in
                            isEditingRadius = editing
                            if !editing {
                                updateSearchRadius(radius: searchRadius)
                            }
                        }
                    )
                    
                    Text("\(Int(searchRadius/1000))km")
                        .font(.subheadline)
                        .frame(width: 60)
                }
            }
            
            // Privacy zone picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Location Privacy")
                    .font(.headline)
                
                Picker("Privacy Zone", selection: $privacyZone) {
                    Text("Exact").tag(PrivacyZoneType.none)
                    Text("Approximate").tag(PrivacyZoneType.approximate)
                    Text("Radius").tag(PrivacyZoneType.radius)
                    Text("Custom").tag(PrivacyZoneType.custom)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Current location button
            Button(action: requestLocationAccess) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Use Current Location")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            setupLocationUpdates()
        }
        .onDisappear {
            locationCancellable?.cancel()
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up location update subscription
    /// Requirement: Location-based Search - Enables furniture discovery based on user location
    private func setupLocationUpdates() {
        locationCancellable = locationManager
            .startUpdatingLocation(accuracyLevel: .balanced)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Location update error: \(error.localizedDescription)")
                    }
                },
                receiveValue: { location in
                    let coordinate = location.coordinate
                    selectedLocation = coordinate
                    region = MKCoordinateRegion(
                        center: coordinate,
                        latitudinalMeters: searchRadius * 2,
                        longitudinalMeters: searchRadius * 2
                    )
                }
            )
    }
    
    /// Requests location access from user
    /// Requirement: Privacy Controls - Implements location privacy and data protection measures
    private func requestLocationAccess() {
        locationManager.requestLocationPermission(requirePrecise: privacyZone == .none)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Location permission error: \(error.localizedDescription)")
                    }
                },
                receiveValue: { granted in
                    if granted {
                        setupLocationUpdates()
                    }
                }
            )
            .store(in: &Set<AnyCancellable>())
    }
    
    /// Updates the search radius with validation
    /// Requirement: Location-based Search - Enables furniture discovery based on user location
    private func updateSearchRadius(radius: Double) {
        let validatedRadius = min(
            max(radius, DEFAULT_LOCATION_CONFIG.minimumSearchRadius),
            DEFAULT_LOCATION_CONFIG.maximumSearchRadius
        )
        searchRadius = validatedRadius
        
        // Update map region to reflect new radius
        region = MKCoordinateRegion(
            center: selectedLocation,
            latitudinalMeters: validatedRadius * 2,
            longitudinalMeters: validatedRadius * 2
        )
    }
}

// MARK: - Preview Provider

struct LocationPicker_Previews: PreviewProvider {
    static var previews: some View {
        LocationPicker(
            selectedLocation: .constant(CLLocationCoordinate2D(latitude: 0, longitude: 0)),
            searchRadius: .constant(DEFAULT_LOCATION_CONFIG.defaultSearchRadius),
            privacyZone: .constant(.none)
        )
    }
}