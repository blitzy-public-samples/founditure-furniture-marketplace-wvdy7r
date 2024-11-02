//
// MapView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify "Privacy - Location When In Use Usage Description" is set in Info.plist
// 2. Verify "Privacy - Location Always and When In Use Usage Description" is set in Info.plist
// 3. Enable background location updates capability in Xcode project settings
// 4. Configure location usage description strings in localization files
// 5. Set up map tile caching policy in Xcode project settings
// 6. Review and adjust clustering thresholds for different zoom levels

import SwiftUI // iOS 14.0+
import MapKit // iOS 14.0+
import Combine // iOS 14.0+

/// Main map view component for furniture discovery
/// Requirement: Location-based search - Enables users to discover furniture items based on geographic location
/// Requirement: Mobile Applications - Implements native iOS map interface with offline-first architecture
struct MapView: View {
    // MARK: - Properties
    
    @StateObject private var locationViewModel: LocationViewModel
    @State private var selectedFurniture: Furniture?
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: DEFAULT_LOCATION_CONFIG.defaultLatitude,
            longitude: DEFAULT_LOCATION_CONFIG.defaultLongitude
        ),
        span: MKCoordinateSpan(
            latitudeDelta: DEFAULT_LOCATION_CONFIG.defaultZoomLevel,
            longitudeDelta: DEFAULT_LOCATION_CONFIG.defaultZoomLevel
        )
    )
    @State private var isLocationPickerPresented: Bool = false
    @State private var searchRadius: Double = DEFAULT_LOCATION_CONFIG.defaultSearchRadius
    
    // Clustering configuration
    private let clusteringIdentifier = "FurnitureCluster"
    private let annotationViewIdentifier = "FurnitureAnnotation"
    
    // MARK: - Initialization
    
    init() {
        // Initialize locationViewModel with app state
        _locationViewModel = StateObject(
            wrappedValue: LocationViewModel(
                appState: AppState.shared,
                locationService: LocationService()
            )
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Map layer
            Map(
                coordinateRegion: $mapRegion,
                showsUserLocation: true,
                annotationItems: setupMapAnnotations()
            ) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    // Custom annotation view
                    VStack {
                        Image(systemName: "chair.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 40, height: 40)
                                    .shadow(radius: 2)
                            )
                        
                        if annotation.isCluster {
                            Text("\(annotation.clusterCount)")
                                .font(.caption)
                                .padding(4)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                    }
                    .onTapGesture {
                        if let furniture = annotation.furniture {
                            handleFurnitureSelection(furniture)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onChange(of: mapRegion) { newRegion in
                updateSearchRegion(newRegion)
            }
            
            // Location picker overlay
            VStack {
                Spacer()
                
                Button(action: {
                    isLocationPickerPresented = true
                }) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                        Text("Change Location")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 2)
                }
                .padding(.bottom)
            }
            
            // Search radius indicator
            if locationViewModel.locationPermissionGranted {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .frame(
                        width: searchRadiusToPoints(),
                        height: searchRadiusToPoints()
                    )
            }
        }
        .sheet(isPresented: $isLocationPickerPresented) {
            LocationPicker(
                selectedLocation: Binding(
                    get: { CLLocationCoordinate2D(
                        latitude: mapRegion.center.latitude,
                        longitude: mapRegion.center.longitude
                    )},
                    set: { newLocation in
                        mapRegion.center = newLocation
                    }
                ),
                searchRadius: $searchRadius,
                privacyZone: Binding(
                    get: { locationViewModel.privacyZoneType },
                    set: { locationViewModel.privacyZoneType = $0 }
                )
            )
        }
        .sheet(item: $selectedFurniture) { furniture in
            FurnitureCard(
                furniture: furniture,
                isInteractive: false
            )
            .padding()
        }
        .onAppear {
            Task {
                await startLocationTracking()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Starts location tracking and initial furniture search
    /// Requirement: Location-based search - Enables users to discover furniture items based on geographic location
    private func startLocationTracking() async {
        await locationViewModel.startLocationUpdates()
        
        if let location = locationViewModel.currentLocation {
            mapRegion.center = CLLocationCoordinate2D(
                latitude: location.coordinates.latitude,
                longitude: location.coordinates.longitude
            )
            await locationViewModel.searchNearbyFurniture(radius: searchRadius)
        }
    }
    
    /// Sets up map annotations for furniture items
    /// Requirement: Mobile Applications - Implements native iOS map interface with clustering support
    private func setupMapAnnotations() -> [FurnitureAnnotation] {
        let annotations = locationViewModel.nearbyFurniture.compactMap { location -> FurnitureAnnotation? in
            guard let furniture = location.furniture else { return nil }
            
            return FurnitureAnnotation(
                coordinate: CLLocationCoordinate2D(
                    latitude: location.coordinates.latitude,
                    longitude: location.coordinates.longitude
                ),
                furniture: furniture,
                isCluster: false,
                clusterCount: 0
            )
        }
        
        // Apply clustering based on zoom level and density
        return clusterAnnotations(annotations)
    }
    
    /// Handles furniture item selection on map
    /// Requirement: Location-based search - Enables users to discover and view furniture items
    private func handleFurnitureSelection(_ furniture: Furniture) {
        selectedFurniture = furniture
        
        // Center map on selected item
        withAnimation {
            mapRegion.center = CLLocationCoordinate2D(
                latitude: furniture.location.coordinates.latitude,
                longitude: furniture.location.coordinates.longitude
            )
        }
    }
    
    /// Updates the search region when map is moved
    /// Requirement: Location-based search - Implements dynamic search area updates
    private func updateSearchRegion(_ region: MKCoordinateRegion) {
        Task {
            // Calculate new search radius based on visible map region
            let newRadius = region.radius
            if abs(newRadius - searchRadius) > DEFAULT_LOCATION_CONFIG.radiusUpdateThreshold {
                searchRadius = min(
                    max(newRadius, DEFAULT_LOCATION_CONFIG.minimumSearchRadius),
                    DEFAULT_LOCATION_CONFIG.maximumSearchRadius
                )
                await locationViewModel.searchNearbyFurniture(radius: searchRadius)
            }
        }
    }
    
    /// Converts search radius to screen points for visualization
    private func searchRadiusToPoints() -> CGFloat {
        let distanceInMeters = searchRadius
        let region = mapRegion
        let midPoint = CLLocationCoordinate2D(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        let radiusCoordinate = CLLocationCoordinate2D(
            latitude: midPoint.latitude + region.span.latitudeDelta / 2,
            longitude: midPoint.longitude
        )
        
        let midPointLocation = CLLocation(latitude: midPoint.latitude, longitude: midPoint.longitude)
        let radiusLocation = CLLocation(latitude: radiusCoordinate.latitude, longitude: radiusCoordinate.longitude)
        
        let metersPerPoint = radiusLocation.distance(from: midPointLocation) / (UIScreen.main.bounds.height / 2)
        return CGFloat(distanceInMeters / metersPerPoint)
    }
    
    /// Clusters annotations based on zoom level and density
    /// Requirement: Mobile Applications - Implements efficient map annotation clustering
    private func clusterAnnotations(_ annotations: [FurnitureAnnotation]) -> [FurnitureAnnotation] {
        let zoomLevel = log2(360 * UIScreen.main.bounds.width / (mapRegion.span.longitudeDelta * 256))
        let clusterDistance: Double
        
        // Adjust clustering distance based on zoom level
        switch zoomLevel {
        case 0...10:
            clusterDistance = 100 // Large clusters for zoomed out view
        case 11...15:
            clusterDistance = 50 // Medium clusters for mid-range zoom
        default:
            return annotations // No clustering for zoomed in view
        }
        
        var clusters: [FurnitureAnnotation] = []
        var processedAnnotations = Set<FurnitureAnnotation>()
        
        for annotation in annotations {
            if processedAnnotations.contains(annotation) { continue }
            
            var clusterAnnotations = [annotation]
            processedAnnotations.insert(annotation)
            
            for otherAnnotation in annotations {
                if processedAnnotations.contains(otherAnnotation) { continue }
                
                let distance = CLLocation(
                    latitude: annotation.coordinate.latitude,
                    longitude: annotation.coordinate.longitude
                ).distance(
                    from: CLLocation(
                        latitude: otherAnnotation.coordinate.latitude,
                        longitude: otherAnnotation.coordinate.longitude
                    )
                )
                
                if distance <= clusterDistance {
                    clusterAnnotations.append(otherAnnotation)
                    processedAnnotations.insert(otherAnnotation)
                }
            }
            
            if clusterAnnotations.count > 1 {
                // Create cluster annotation
                let centerCoordinate = calculateClusterCenter(clusterAnnotations)
                clusters.append(
                    FurnitureAnnotation(
                        coordinate: centerCoordinate,
                        furniture: annotation.furniture,
                        isCluster: true,
                        clusterCount: clusterAnnotations.count
                    )
                )
            } else {
                clusters.append(annotation)
            }
        }
        
        return clusters
    }
    
    /// Calculates the center coordinate for a cluster of annotations
    private func calculateClusterCenter(_ annotations: [FurnitureAnnotation]) -> CLLocationCoordinate2D {
        let totalLatitude = annotations.reduce(0) { $0 + $1.coordinate.latitude }
        let totalLongitude = annotations.reduce(0) { $0 + $1.coordinate.longitude }
        let count = Double(annotations.count)
        
        return CLLocationCoordinate2D(
            latitude: totalLatitude / count,
            longitude: totalLongitude / count
        )
    }
}

// MARK: - FurnitureAnnotation

/// Custom annotation type for furniture items on map
private struct FurnitureAnnotation: Identifiable, Hashable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let furniture: Furniture?
    let isCluster: Bool
    let clusterCount: Int
    
    static func == (lhs: FurnitureAnnotation, rhs: FurnitureAnnotation) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview Provider

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}