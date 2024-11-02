//
// SettingsView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure push notification permissions in Info.plist
// 2. Set up location services permissions in Info.plist
// 3. Verify privacy policy links are up to date
// 4. Configure data deletion request handling
// 5. Set up analytics tracking for settings changes

// External dependencies
import SwiftUI // iOS 14.0+
import Combine // iOS 14.0+

// Internal dependencies
import "../../Protocols/ViewModelProtocol"
import "../../Models/User"
import "../../Utils/Constants/AppConstants"
import "../../Utils/Extensions/View+Extension"

// MARK: - SettingsViewModel

@MainActor
final class SettingsViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var user: User
    @Published private(set) var toggleStates: [String: Bool]
    
    // MARK: - Properties
    
    let appState: AppState
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(appState: AppState) {
        self.appState = appState
        self.user = appState.currentUser
        self.toggleStates = [:]
        
        // Initialize toggle states from user preferences
        loadSettings()
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Updates a user setting and persists the change
    /// Requirement: Privacy controls - Implements user privacy settings and preferences management
    func updateSetting(key: UserPreferenceKey, value: Any) {
        isLoading = true
        
        Task {
            do {
                // Update local state
                user.preferences[key.rawValue] = value
                
                if let boolValue = value as? Bool {
                    toggleStates[key.rawValue] = boolValue
                }
                
                // Persist changes
                try await appState.updateUserPreferences(user.preferences)
                
                // Handle specific setting updates
                switch key {
                case .notificationsEnabled:
                    if let enabled = value as? Bool {
                        await handleNotificationPermission(enabled)
                    }
                case .locationSharingEnabled:
                    if let enabled = value as? Bool {
                        await handleLocationPermission(enabled)
                    }
                default:
                    break
                }
                
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    /// Loads user settings from storage
    /// Requirement: Offline-first architecture - Handles settings persistence and offline changes
    func loadSettings() {
        isLoading = true
        
        // Initialize toggle states from user preferences
        for key in UserPreferenceKey.allCases {
            if let boolValue = user.preferences[key.rawValue] as? Bool {
                toggleStates[key.rawValue] = boolValue
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func handleNotificationPermission(_ enabled: Bool) async {
        if enabled {
            // Request notification permission
            let granted = await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            
            if !granted {
                // Update toggle state if permission denied
                await MainActor.run {
                    toggleStates[UserPreferenceKey.notificationsEnabled.rawValue] = false
                    user.preferences[UserPreferenceKey.notificationsEnabled.rawValue] = false
                }
            }
        }
    }
    
    private func handleLocationPermission(_ enabled: Bool) async {
        if enabled {
            // Request location permission
            let manager = CLLocationManager()
            let status = manager.authorizationStatus
            
            if status == .denied || status == .restricted {
                // Update toggle state if permission denied
                await MainActor.run {
                    toggleStates[UserPreferenceKey.locationSharingEnabled.rawValue] = false
                    user.preferences[UserPreferenceKey.locationSharingEnabled.rawValue] = false
                }
            }
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(appState: appState))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                // Notification Settings Section
                notificationSection()
                
                // Location Settings Section
                locationSection()
                
                // Privacy Settings Section
                privacySection()
                
                // App Preferences Section
                Section(header: Text("App Preferences")) {
                    Toggle("Dark Mode", isOn: Binding(
                        get: { viewModel.toggleStates[UserPreferenceKey.darkModeEnabled.rawValue] ?? false },
                        set: { viewModel.updateSetting(key: .darkModeEnabled, value: $0) }
                    ))
                    
                    Picker("Language", selection: Binding(
                        get: { viewModel.user.preferences[UserPreferenceKey.languageCode.rawValue] as? String ?? "en" },
                        set: { viewModel.updateSetting(key: .languageCode, value: $0) }
                    )) {
                        Text("English").tag("en")
                        Text("Spanish").tag("es")
                        Text("French").tag("fr")
                    }
                }
                
                // Account Actions Section
                Section {
                    Button(role: .destructive) {
                        // Handle account deletion
                    } label: {
                        Text("Delete Account")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading)
        .errorBanner(errorMessage: viewModel.error?.localizedDescription)
    }
    
    // MARK: - Section Views
    
    /// Creates notification settings section
    /// Requirement: Privacy controls - Implements notification preferences management
    private func notificationSection() -> some View {
        Section(header: Text("Notifications")) {
            Toggle("Push Notifications", isOn: Binding(
                get: { viewModel.toggleStates[UserPreferenceKey.notificationsEnabled.rawValue] ?? false },
                set: { viewModel.updateSetting(key: .notificationsEnabled, value: $0) }
            ))
            
            if viewModel.toggleStates[UserPreferenceKey.notificationsEnabled.rawValue] == true {
                Toggle("In-App Notifications", isOn: .constant(true))
                Toggle("Sound", isOn: .constant(true))
            }
        }
    }
    
    /// Creates location settings section
    /// Requirement: Privacy controls - Implements location sharing preferences
    private func locationSection() -> some View {
        Section(header: Text("Location")) {
            Toggle("Location Sharing", isOn: Binding(
                get: { viewModel.toggleStates[UserPreferenceKey.locationSharingEnabled.rawValue] ?? false },
                set: { viewModel.updateSetting(key: .locationSharingEnabled, value: $0) }
            ))
            
            if viewModel.toggleStates[UserPreferenceKey.locationSharingEnabled.rawValue] == true {
                Picker("Search Radius", selection: Binding(
                    get: { viewModel.user.preferences[UserPreferenceKey.radiusPreference.rawValue] as? Double ?? Location.defaultRadius },
                    set: { viewModel.updateSetting(key: .radiusPreference, value: $0) }
                )) {
                    Text("1 km").tag(1000.0)
                    Text("5 km").tag(5000.0)
                    Text("10 km").tag(10000.0)
                    Text("25 km").tag(25000.0)
                }
                
                Toggle("Hide Exact Location", isOn: Binding(
                    get: { viewModel.user.privacySettings.hideExactLocation },
                    set: { viewModel.user.updatePrivacySettings(settings: PrivacySettings(
                        visibilityLevel: .approximate,
                        blurRadius: 1000,
                        hideExactLocation: $0
                    )) }
                ))
            }
        }
    }
    
    /// Creates privacy settings section
    /// Requirement: Privacy controls - Implements user privacy settings
    private func privacySection() -> some View {
        Section(header: Text("Privacy")) {
            Picker("Profile Visibility", selection: Binding(
                get: { viewModel.user.privacySettings.visibilityLevel },
                set: { viewModel.user.updatePrivacySettings(settings: PrivacySettings(
                    visibilityLevel: $0,
                    blurRadius: viewModel.user.privacySettings.blurRadius,
                    hideExactLocation: viewModel.user.privacySettings.hideExactLocation
                )) }
            )) {
                Text("Public").tag(VisibilityLevel.public)
                Text("Friends Only").tag(VisibilityLevel.friendsOnly)
                Text("Private").tag(VisibilityLevel.private)
            }
            
            Toggle("Data Sharing", isOn: Binding(
                get: { viewModel.user.preferences["dataSharing"] as? Bool ?? false },
                set: { viewModel.updateSetting(key: .dataSharing, value: $0) }
            ))
            
            NavigationLink("Privacy Policy") {
                // Privacy policy view
            }
        }
    }
}

// MARK: - Preview Provider

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(appState: AppState())
    }
}