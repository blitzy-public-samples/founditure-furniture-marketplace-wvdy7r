//
// AchievementsView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure achievement unlock thresholds with product team
// 2. Set up analytics events for achievement unlocks
// 3. Verify accessibility labels for achievement badges
// 4. Test achievement animations with VoiceOver enabled
// 5. Validate achievement filter performance with large datasets

import SwiftUI // iOS 14.0+
import Combine // iOS 14.0+

/// SwiftUI view that displays user achievements and points progress in the gamification system
/// Requirement: Points system and leaderboards - Implements the user interface for displaying achievements and points progress
/// Requirement: Mobile-first platform - Native iOS view implementation using SwiftUI
@available(iOS 14.0, *)
struct AchievementsView: View {
    // MARK: - Properties
    
    /// View model for managing points and achievements data
    @StateObject private var viewModel: PointsViewModel
    
    /// Selected filter for achievements list
    @State private var selectedFilter: AchievementFilter = .all
    
    /// Flag for showing achievement detail sheet
    @State private var showingDetail: Bool = false
    
    /// Currently selected achievement for detail view
    @State private var selectedAchievement: Point? = nil
    
    /// Animation state for points total
    @State private var animatePoints: Bool = false
    
    // MARK: - Initialization
    
    init(appState: AppState = AppState.shared) {
        _viewModel = StateObject(wrappedValue: PointsViewModel(appState: appState))
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Total points header
                    totalPointsHeader
                    
                    // Current streak display
                    if viewModel.currentStreak > 0 {
                        streakSection
                    }
                    
                    // Achievement filters
                    filterSection
                    
                    // Achievements grid
                    achievementsList
                    
                    // Points history
                    pointsHistory
                }
                .padding()
            }
            .navigationTitle("Achievements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
        }
        .onAppear {
            loadData()
        }
        // Error alert
        .alert(item: Binding(
            get: { viewModel.error as? LocalizedError },
            set: { _ in viewModel.error = nil }
        )) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Subviews
    
    /// Header displaying total points
    private var totalPointsHeader: some View {
        VStack(spacing: 8) {
            Text("Total Points")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("\(viewModel.totalPoints)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.primary)
                .scaleEffect(animatePoints ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6))
                .onAppear {
                    animatePoints = true
                }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    /// Section displaying current streak information
    private var streakSection: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.currentStreak) Day Streak")
                    .font(.headline)
                
                Text("Keep it going!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            PointsBadge(
                points: viewModel.currentStreak * PointType.streak.baseValue,
                type: .streak,
                animate: true,
                scale: 0.8
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    /// Filter section for achievements list
    private var filterSection: some View {
        HStack {
            ForEach(AchievementFilter.allCases, id: \.self) { filter in
                filterChip(filter)
            }
        }
        .padding(.horizontal)
    }
    
    /// Individual filter chip
    private func filterChip(_ filter: AchievementFilter) -> some View {
        Button(action: {
            withAnimation {
                selectedFilter = filter
            }
        }) {
            Text(filter.rawValue.capitalized)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedFilter == filter ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(selectedFilter == filter ? .white : .primary)
                .cornerRadius(16)
        }
    }
    
    /// Grid of achievement badges
    private var achievementsList: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(filteredAchievements, id: \.id) { achievement in
                PointsBadge(
                    points: achievement.value,
                    type: PointType(rawValue: achievement.type) ?? .achievement,
                    scale: 1.2
                )
                .onTapGesture {
                    selectedAchievement = achievement
                    showingDetail = true
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingDetail) {
            if let achievement = selectedAchievement {
                achievementDetail(achievement)
            }
        }
    }
    
    /// Points history list
    private var pointsHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Points History")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(viewModel.points.prefix(10), id: \.id) { point in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(point.description)
                            .font(.subheadline)
                        
                        Text(point.formattedTimestamp())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("+\(point.value)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 1)
            }
        }
    }
    
    /// Achievement detail sheet
    private func achievementDetail(_ achievement: Point) -> some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    PointsBadge(
                        points: achievement.value,
                        type: PointType(rawValue: achievement.type) ?? .achievement,
                        animate: true,
                        scale: 2.0
                    )
                    
                    VStack(spacing: 8) {
                        Text(achievement.description)
                            .font(.headline)
                        
                        Text(achievement.formattedTimestamp())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let referenceId = achievement.referenceId {
                        Text("Reference ID: \(referenceId.uuidString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Achievement Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingDetail = false
                    }
                }
            }
        }
    }
    
    /// Filter button in navigation bar
    private var filterButton: some View {
        Menu {
            ForEach(AchievementFilter.allCases, id: \.self) { filter in
                Button(action: {
                    withAnimation {
                        selectedFilter = filter
                    }
                }) {
                    Label(
                        filter.rawValue.capitalized,
                        systemImage: selectedFilter == filter ? "checkmark" : ""
                    )
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .imageScale(.large)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Loads achievement and points data
    private func loadData() {
        viewModel.fetchPoints()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &viewModel.cancellables)
    }
    
    /// Returns filtered achievements based on selected filter
    private var filteredAchievements: [Point] {
        switch selectedFilter {
        case .all:
            return viewModel.points
        case .unlocked:
            return viewModel.points.filter { $0.isProcessed }
        case .inProgress:
            return viewModel.points.filter { !$0.isProcessed }
        }
    }
}

// MARK: - Achievement Filter Enum

/// Filter options for achievements list
enum AchievementFilter: String, CaseIterable {
    case all
    case unlocked
    case inProgress
}

// MARK: - Preview Provider

#if DEBUG
struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AchievementsView()
            
            AchievementsView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif