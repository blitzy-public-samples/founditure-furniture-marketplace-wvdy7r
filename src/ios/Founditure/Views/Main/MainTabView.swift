//
// MainTabView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify camera usage description is set in Info.plist
// 2. Configure tab bar appearance in UIKit appearance proxy
// 3. Test deep linking to specific tabs
// 4. Verify proper tab bar icon rendering on all devices
// 5. Test tab switching performance with large datasets

import SwiftUI // iOS 14.0+
import AVFoundation // iOS 14.0+

/// Main tab navigation view for the Founditure iOS app
/// Requirement: Mobile Applications - Implements native iOS application navigation using SwiftUI with offline-first architecture
/// Requirement: Mobile Client Architecture - Implements the main navigation structure of the mobile client using tab-based navigation
@available(iOS 14.0, *)
struct MainTabView: View {
    // MARK: - Properties
    
    /// Currently selected tab index
    @State private var selectedTab: Int = 0
    
    /// Camera permission alert state
    @State private var showingCameraPermission: Bool = false
    
    // MARK: - Constants
    
    private enum TabIndex {
        static let home = 0
        static let map = 1
        static let camera = 2
        static let messages = 3
        static let profile = 4
    }
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Feed Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(TabIndex.home)
            
            // Map View Tab
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(TabIndex.map)
            
            // Camera Tab
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(TabIndex.camera)
                .onChange(of: selectedTab) { newValue in
                    if newValue == TabIndex.camera {
                        checkCameraPermission()
                    }
                }
            
            // Messages Tab
            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
                .tag(TabIndex.messages)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(TabIndex.profile)
        }
        .onAppear {
            // Configure tab bar appearance
            configureTabBarAppearance()
        }
        .alert(isPresented: $showingCameraPermission) {
            Alert(
                title: Text("Camera Access Required"),
                message: Text("Please enable camera access in Settings to use this feature."),
                primaryButton: .default(Text("Settings"), action: openSettings),
                secondaryButton: .cancel(Text("Cancel")) {
                    // Switch back to home tab if camera access denied
                    selectedTab = TabIndex.home
                }
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// Configures the UITabBar appearance
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Configure normal state
        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        
        // Configure selected state
        appearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        // Apply appearance
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    /// Checks and handles camera permission status
    /// Requirement: Mobile Applications - Implements proper permission handling for camera access
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Camera access already granted
            break
            
        case .notDetermined:
            // Request camera access
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        showingCameraPermission = true
                    }
                }
            }
            
        case .denied, .restricted:
            // Show permission alert
            showingCameraPermission = true
            
        @unknown default:
            // Handle future cases
            showingCameraPermission = true
        }
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
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            MainTabView()
            
            // Dark mode preview
            MainTabView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif