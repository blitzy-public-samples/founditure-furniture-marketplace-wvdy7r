//
// FurnitureDetailView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure image caching policy in Xcode project settings
// 2. Test accessibility features with VoiceOver enabled
// 3. Verify MapKit integration and location permissions in Info.plist
// 4. Review message sheet UI/UX with design team
// 5. Set up proper image compression settings for AsyncImage loading

import SwiftUI // iOS 14.0+
import MapKit // iOS 14.0+

/// A SwiftUI view that displays detailed information about a furniture item
/// Requirement: Furniture documentation and discovery - Provides detailed view of furniture items with comprehensive information
struct FurnitureDetailView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: FurnitureViewModel
    @State private var showingMessageSheet = false
    @State private var showingMapSheet = false
    @State private var selectedImageIndex = 0
    
    let furniture: Furniture
    
    // MARK: - Map Region
    
    @State private var region: MKCoordinateRegion
    
    // MARK: - Initialization
    
    init(furniture: Furniture) {
        self.furniture = furniture
        _viewModel = StateObject(wrappedValue: FurnitureViewModel(appState: AppState.shared))
        
        // Initialize map region centered on furniture location
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: furniture.location.latitude,
                longitude: furniture.location.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Image carousel
                imageCarousel()
                    .frame(height: 300)
                
                // Details section
                detailsSection()
                    .padding(.horizontal)
                
                // Location section
                // Requirement: Location-based search - Shows location information and distance for furniture items
                locationSection()
                    .padding(.horizontal)
                
                // Action buttons
                actionButtons()
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMessageSheet) {
            // Requirement: Real-time messaging - Enables users to initiate conversations about furniture items
            MessageComposeView(furniture: furniture)
        }
        .sheet(isPresented: $showingMapSheet) {
            // Requirement: Location-based search - Shows detailed map view for furniture location
            MapDetailView(region: region, furniture: furniture)
        }
    }
    
    // MARK: - Private Views
    
    /// Creates the image carousel view
    private func imageCarousel() -> some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(furniture.imageUrls.indices, id: \.self) { index in
                AsyncImage(url: URL(string: furniture.imageUrls[index])) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
    
    /// Creates the furniture details section
    private func detailsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and description
            Text(furniture.title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(furniture.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            // Category and condition
            HStack {
                Label(
                    furniture.category.rawValue.capitalized,
                    systemImage: "tag"
                )
                
                Spacer()
                
                Label(
                    furniture.condition.rawValue.capitalized,
                    systemImage: "star"
                )
            }
            .font(.subheadline)
            
            // Dimensions
            if let dimensions = furniture.dimensions {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dimensions")
                        .font(.headline)
                    
                    HStack {
                        dimensionItem(
                            value: dimensions.length,
                            unit: dimensions.unit,
                            label: "Length"
                        )
                        Spacer()
                        dimensionItem(
                            value: dimensions.width,
                            unit: dimensions.unit,
                            label: "Width"
                        )
                        Spacer()
                        dimensionItem(
                            value: dimensions.height,
                            unit: dimensions.unit,
                            label: "Height"
                        )
                    }
                }
            }
            
            // Materials
            if !furniture.materials.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Materials")
                        .font(.headline)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(furniture.materials, id: \.self) { material in
                            Text(material)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(16)
                        }
                    }
                }
            }
            
            // Pickup details
            VStack(alignment: .leading, spacing: 8) {
                Text("Pickup Details")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available: \(furniture.pickupDetails.availableDays.joined(separator: ", "))")
                    Text("Time window: \(furniture.pickupDetails.timeWindow)")
                    
                    if let instructions = furniture.pickupDetails.specialInstructions {
                        Text("Instructions: \(instructions)")
                    }
                    
                    if furniture.pickupDetails.assistanceRequired {
                        Label("Assistance required", systemImage: "person.2.fill")
                            .foregroundColor(.orange)
                    }
                }
                .font(.subheadline)
            }
        }
    }
    
    /// Creates the location section view
    private func locationSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(.headline)
            
            // Map preview
            Map(coordinateRegion: .constant(region), annotationItems: [furniture]) { item in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: item.location.latitude,
                    longitude: item.location.longitude
                )) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.title)
                }
            }
            .frame(height: 200)
            .cornerRadius(12)
            .onTapGesture {
                showingMapSheet = true
            }
            
            // Distance information
            if let userLocation = viewModel.appState.userLocation {
                let distance = userLocation.distance(
                    from: CLLocation(
                        latitude: furniture.location.latitude,
                        longitude: furniture.location.longitude
                    )
                ) / 1000 // Convert to kilometers
                
                Label(
                    String(format: "%.1f km away", distance),
                    systemImage: "location.fill"
                )
                .font(.subheadline)
            }
        }
    }
    
    /// Creates the action buttons section
    private func actionButtons() -> some View {
        HStack(spacing: 16) {
            // Message button
            Button(action: {
                showingMessageSheet = true
            }) {
                Label("Message", systemImage: "message.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            // Claim button (if available)
            if furniture.status == .available {
                Button(action: {
                    viewModel.updateFurnitureStatus(
                        furnitureId: furniture.id,
                        newStatus: .pending
                    )
                    .sink { _ in } receiveValue: { _ in }
                    .cancel()
                }) {
                    Label("Claim", systemImage: "hand.raised.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            
            // Save button
            Button(action: {
                // Save functionality to be implemented
            }) {
                Image(systemName: "bookmark")
                    .font(.title3)
            }
            .buttonStyle(.bordered)
        }
    }
    
    /// Creates a dimension item view
    private func dimensionItem(value: Double, unit: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", value))
                .font(.headline)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct FurnitureDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFurniture = Furniture(
            title: "Vintage Wooden Chair",
            description: "Beautiful vintage chair in excellent condition",
            category: .seating,
            condition: .good,
            location: Location(latitude: 37.7749, longitude: -122.4194),
            userId: UUID()
        )
        
        NavigationView {
            FurnitureDetailView(furniture: sampleFurniture)
        }
    }
}
#endif