//
// ProfileView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure analytics events for profile interactions
// 2. Set up proper error tracking integration
// 3. Verify accessibility labels and VoiceOver support
// 4. Test deep linking to profile sections
// 5. Configure user data export functionality

import SwiftUI // iOS 14.0+
import Combine // iOS 14.0+

/// Main profile view showing user information and achievements
/// Requirement: User registration and authentication - Displays and manages user profile information
@available(iOS 14.0, *)
struct ProfileView: View {
    // MARK: - Properties
    
    /// View model for managing profile data
    @StateObject private var viewModel: ProfileViewModel
    
    /// State for showing edit profile sheet
    @State private var showingEditProfile: Bool = false
    
    /// State for showing settings sheet
    @State private var showingSettings: Bool = false
    
    /// State for showing achievements view
    @State private var showingAchievements: Bool = false
    
    // MARK: - Initialization
    
    init(appState: AppState = AppState.shared) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(
            authService: AuthService.shared,
            appState: appState
        ))
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header with user info
                    profileHeader
                    
                    // Points and achievements summary
                    pointsSection
                    
                    // User information section
                    if let user = viewModel.user {
                        userInfoSection(user)
                    }
                    
                    // Points history preview
                    pointsHistoryPreview
                }
                .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                navigationButtons
            }
            .refreshable {
                // Requirement: Mobile-first design - Support pull-to-refresh
                await refreshData()
            }
        }
        // Edit profile sheet
        .sheet(isPresented: $showingEditProfile) {
            NavigationView {
                ProfileEditView(user: viewModel.user)
            }
        }
        // Settings sheet
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView()
            }
        }
        // Full screen achievements view
        .fullScreenCover(isPresented: $showingAchievements) {
            AchievementsView()
        }
        // Loading overlay
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
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
    
    /// Creates the profile header section
    /// Requirement: User registration and authentication - Displays user profile information
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile image
            if let user = viewModel.user {
                AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.secondary)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.secondary, lineWidth: 2))
                .shadow(radius: 2)
                
                // User name and status
                VStack(spacing: 4) {
                    Text(user.fullName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Member since \(user.formattedJoinDate)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                // Sign in prompt
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Sign in to view your profile")
                        .font(.headline)
                    
                    Button("Sign In") {
                        // Navigate to auth flow
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    /// Creates the points and achievements section
    /// Requirement: Points system and leaderboards - Shows user points and achievements
    private var pointsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Points & Achievements")
                    .font(.headline)
                
                Spacer()
                
                Button("See All") {
                    showingAchievements = true
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            HStack(spacing: 20) {
                // Total points badge
                PointsBadge(
                    points: viewModel.pointsHistory.reduce(0) { $0 + $1.value },
                    type: .posting,
                    animate: true
                )
                
                // Recent achievements preview
                if !viewModel.pointsHistory.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.pointsHistory.prefix(3)) { point in
                                PointsBadge(
                                    points: point.value,
                                    type: PointType(rawValue: point.type) ?? .achievement
                                )
                            }
                        }
                    }
                } else {
                    Text("No achievements yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    /// Creates the user information section
    /// Requirement: User registration and authentication - Displays user details
    private func userInfoSection(_ user: User) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Email
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.secondary)
                    Text(user.email)
                        .font(.subheadline)
                    Spacer()
                }
                
                // Phone number if available
                if let phone = user.phoneNumber {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.secondary)
                        Text(phone)
                            .font(.subheadline)
                        Spacer()
                    }
                }
                
                // Privacy settings indicator
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                    Text(user.privacySettings.description)
                        .font(.subheadline)
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    /// Creates the points history preview section
    /// Requirement: Points system and leaderboards - Shows points history
    private var pointsHistoryPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Points")
                    .font(.headline)
                
                Spacer()
                
                Button("See All") {
                    showingAchievements = true
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            if !viewModel.pointsHistory.isEmpty {
                ForEach(viewModel.pointsHistory.prefix(5)) { point in
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
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            } else {
                Text("No points earned yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - View Extensions

extension ProfileView {
    /// Creates navigation bar buttons
    /// Requirement: Privacy controls - Provides access to settings
    @ToolbarContent
    private var navigationButtons: some ToolbarContent {
        Group {
            // Settings button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                        .imageScale(.large)
                }
            }
            
            // Edit profile button if authenticated
            if viewModel.user != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditProfile = true
                    } label: {
                        Image(systemName: "pencil")
                            .imageScale(.large)
                    }
                }
            }
        }
    }
    
    /// Refreshes profile data
    private func refreshData() async {
        // Load points history
        _ = await viewModel.loadPointsHistory()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &viewModel.cancellables)
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            ProfileView()
            
            // Dark mode preview
            ProfileView()
                .preferredColorScheme(.dark)
            
            // Loading state preview
            ProfileView()
                .preferredColorScheme(.light)
        }
    }
}
#endif