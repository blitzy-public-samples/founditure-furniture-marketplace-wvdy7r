//
// HomeView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure pull-to-refresh animation timing in Xcode project settings
// 2. Verify accessibility labels with VoiceOver enabled
// 3. Test category filter animations on different devices
// 4. Ensure proper error message localization
// 5. Review search bar keyboard handling behavior

import SwiftUI // iOS 14.0+
import Combine // iOS 14.0+

/// Main home feed view of the Founditure iOS application
/// Requirement: Mobile Applications - Implements native iOS user interface using SwiftUI for the main furniture discovery feed
@available(iOS 14.0, *)
struct HomeView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: FurnitureViewModel
    @State private var searchText: String = ""
    @State private var selectedCategory: FurnitureCategory?
    @State private var isRefreshing: Bool = false
    @State private var showLocationPermissionAlert: Bool = false
    
    // MARK: - Initialization
    
    init() {
        let appState = AppState()
        _viewModel = StateObject(wrappedValue: FurnitureViewModel(appState: appState))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    // Search bar
                    searchBar()
                    
                    // Category filter
                    categoryFilterView()
                        .padding(.vertical, 8)
                    
                    // Furniture list
                    furnitureListView()
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
                
                // Error overlay
                if let error = viewModel.error {
                    VStack {
                        Text("Error")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            refreshContent()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }
            }
            .navigationTitle("Discover Furniture")
            .alert(isPresented: $showLocationPermissionAlert) {
                Alert(
                    title: Text("Location Access Required"),
                    message: Text("Please enable location services to see furniture near you."),
                    primaryButton: .default(Text("Settings"), action: openSettings),
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // MARK: - Private Views
    
    /// Creates the search bar view
    /// Requirement: Furniture documentation and discovery - Provides search functionality for furniture items
    private func searchBar() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search furniture", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: searchText) { newValue in
                    viewModel.searchQuery = newValue
                }
        }
        .padding()
    }
    
    /// Creates the category filter view
    /// Requirement: Furniture documentation and discovery - Implements category-based filtering
    private func categoryFilterView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All categories option
                categoryChip(nil, "All")
                
                // Category chips
                ForEach([
                    FurnitureCategory.seating,
                    .tables,
                    .storage,
                    .beds,
                    .lighting,
                    .decor,
                    .outdoor,
                    .other
                ], id: \.self) { category in
                    categoryChip(category, category.rawValue.capitalized)
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// Creates a category filter chip
    private func categoryChip(_ category: FurnitureCategory?, _ title: String) -> some View {
        Button(action: {
            withAnimation {
                selectedCategory = category
                viewModel.selectedCategory = category
            }
        }) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    selectedCategory == category ?
                        Color.accentColor :
                        Color(.systemGray6)
                )
                .foregroundColor(
                    selectedCategory == category ?
                        .white :
                        .primary
                )
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title) category filter")
    }
    
    /// Creates the main furniture list view
    /// Requirement: Furniture documentation and discovery - Displays scrollable list of furniture items
    private func furnitureListView() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Pull-to-refresh functionality
                GeometryReader { geometry in
                    if geometry.frame(in: .global).minY > 50 && !isRefreshing {
                        ProgressView()
                            .onAppear {
                                refreshContent()
                            }
                    }
                }
                .frame(height: 0)
                
                // Furniture items
                ForEach(viewModel.filteredItems) { furniture in
                    FurnitureCard(
                        furniture: furniture,
                        onTap: { selectedFurniture in
                            // Navigate to detail view
                            // Note: Navigation handling will be implemented by parent view
                        },
                        onSave: { savedFurniture in
                            // Handle save action
                            // Note: Save functionality will be implemented in future iteration
                        }
                    )
                    .padding(.horizontal)
                }
                
                // Empty state
                if viewModel.filteredItems.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No furniture found")
                            .font(.headline)
                        Text("Try adjusting your filters or search terms")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 48)
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await refreshContent()
        }
    }
    
    // MARK: - Private Methods
    
    /// Refreshes the furniture content
    /// Requirement: Furniture documentation and discovery - Implements content refresh functionality
    private func refreshContent() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        // Fetch new furniture items
        viewModel.fetchFurnitureItems()
            .sink(
                receiveCompletion: { completion in
                    isRefreshing = false
                    if case .failure = completion {
                        // Error handling is managed by viewModel
                    }
                },
                receiveValue: { _ in
                    isRefreshing = false
                }
            )
            .store(in: &viewModel.cancellables)
    }
    
    /// Opens the iOS Settings app
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
}

// MARK: - Preview Provider

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView()
            
            HomeView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif