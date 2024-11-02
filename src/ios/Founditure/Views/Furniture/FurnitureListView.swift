//
// FurnitureListView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure pull-to-refresh animation timing in Xcode project settings
// 2. Test accessibility labels with VoiceOver enabled
// 3. Verify search bar keyboard handling on different devices
// 4. Ensure proper category filter scroll behavior on smaller screens

import SwiftUI // iOS 14.0+
import Combine // iOS 14.0+

/// Main view for displaying the list of available furniture items
/// Requirement: Furniture documentation and discovery - Implements the main furniture listing interface
/// Requirement: Mobile Applications - Implements native iOS UI using SwiftUI
@available(iOS 14.0, *)
struct FurnitureListView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = FurnitureViewModel(appState: AppState.shared)
    @State private var searchText: String = ""
    @State private var isRefreshing: Bool = false
    @State private var selectedCategory: FurnitureCategory?
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Search bar
                    searchBar()
                    
                    // Category filter
                    categoryFilter()
                        .padding(.vertical, 8)
                    
                    // Furniture list
                    furnitureList()
                }
            }
            .navigationTitle("Furniture")
            .navigationBarTitleDisplayMode(.large)
        }
        .loadingOverlay(isLoading: viewModel.isLoading)
        .errorBanner(errorMessage: viewModel.error?.localizedDescription)
    }
    
    // MARK: - Private Views
    
    /// Creates the search bar view
    /// Requirement: Furniture documentation and discovery - Implements search functionality
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
    
    /// Creates the category filter section
    /// Requirement: Furniture documentation and discovery - Implements category filtering
    private func categoryFilter() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All categories button
                categoryButton(nil, "All")
                
                // Category buttons
                ForEach(FurnitureCategory.allCases, id: \.self) { category in
                    categoryButton(category, category.rawValue.capitalized)
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// Creates a category filter button
    /// - Parameters:
    ///   - category: Optional category to filter by
    ///   - title: Button title text
    private func categoryButton(_ category: FurnitureCategory?, _ title: String) -> some View {
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
                        Color.secondary.opacity(0.1)
                )
                .foregroundColor(
                    selectedCategory == category ?
                        .white :
                        .primary
                )
                .cornerRadius(20)
        }
        .accessibilityLabel("\(title) category filter")
    }
    
    /// Creates the scrollable furniture list
    /// Requirement: Furniture documentation and discovery - Displays furniture items in a scrollable list
    /// Requirement: Location-based search - Displays furniture items with location context
    private func furnitureList() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredItems) { furniture in
                    NavigationLink(
                        destination: FurnitureDetailView(furniture: furniture)
                    ) {
                        FurnitureCard(
                            furniture: furniture,
                            onSave: { item in
                                // Handle save action
                                // This would be implemented in a future story for bookmarking
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await refreshList()
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles pull-to-refresh action
    /// Requirement: Mobile Applications - Implements pull-to-refresh functionality
    private func refreshList() async {
        isRefreshing = true
        
        await withCheckedContinuation { continuation in
            viewModel.fetchFurnitureItems()
                .sink(
                    receiveCompletion: { completion in
                        isRefreshing = false
                        continuation.resume()
                    },
                    receiveValue: { _ in }
                )
                .store(in: &viewModel.cancellables)
        }
    }
}

// MARK: - View Protocol Conformance

extension FurnitureListView: View {
    // View protocol conformance is implicit through the body property
}

// MARK: - Preview Provider

#if DEBUG
struct FurnitureListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FurnitureListView()
            
            FurnitureListView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif