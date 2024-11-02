//
// FounditureApp.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure Firebase/Analytics in Info.plist
// 2. Set up push notification certificates in Apple Developer Portal
// 3. Configure deep linking URL schemes in Info.plist
// 4. Verify app appearance settings for all iOS versions
// 5. Test app state restoration scenarios

import SwiftUI // iOS 14.0+

/// Main application entry point for the Founditure iOS app
/// Requirement: Mobile Applications - Implements native iOS application (iOS 14+) with offline-first architecture
/// Requirement: Mobile Client Architecture - Implements the core application structure and state management
@main
@available(iOS 14.0, *)
struct FounditureApp: App {
    // MARK: - Properties
    
    /// Global application state
    @StateObject private var appState = AppState()
    
    // MARK: - Initialization
    
    init() {
        // Configure app appearance
        configureAppearance()
        
        // Initialize analytics
        setupAnalytics()
        
        // Configure push notifications
        setupPushNotifications()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .onAppear {
                    // Configure deep linking
                    setupDeepLinking()
                }
                .onChange(of: scenePhase) { newPhase in
                    handleScenePhase(newPhase)
                }
        }
    }
    
    // MARK: - Private Methods
    
    /// Configures global app appearance settings
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        navigationBarAppearance.backgroundColor = .systemBackground
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        // Configure tab bar styling
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // Set up color scheme
        if #available(iOS 15.0, *) {
            let colorScheme = UITraitCollection.current.userInterfaceStyle
            UIWindow.appearance().overrideUserInterfaceStyle = colorScheme
        }
        
        // Configure font styles
        UIFont.preferredFont(forTextStyle: .body)
        UIFont.preferredFont(forTextStyle: .headline)
        UIFont.preferredFont(forTextStyle: .subheadline)
    }
    
    /// Sets up analytics tracking
    private func setupAnalytics() {
        #if DEBUG
        // Configure debug analytics
        Analytics.setAnalyticsCollectionEnabled(false)
        #else
        // Configure production analytics
        Analytics.setAnalyticsCollectionEnabled(true)
        Analytics.setSessionTimeoutInterval(1800) // 30 minutes
        #endif
        
        // Track app launch
        Analytics.logEvent("app_launch", parameters: [
            "ios_version": UIDevice.current.systemVersion,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])
    }
    
    /// Configures push notification handling
    private func setupPushNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            if let error = error {
                print("Push notification authorization error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Sets up deep linking handling
    private func setupDeepLinking() {
        // Register URL scheme handler
        guard let urlScheme = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLSchemes") as? [String],
              let scheme = urlScheme.first else {
            return
        }
        
        // Configure universal links
        let universalLinkDomains = ["founditure.com", "www.founditure.com"]
        NSUserActivity.enableUniversalLinks(universalLinkDomains)
    }
    
    /// Handles scene phase changes
    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App became active
            Task {
                // Refresh app state
                await appState.syncState()
                
                // Reset badge count
                await UIApplication.shared.setApplicationIconBadgeNumber(0)
            }
            
        case .inactive:
            // App became inactive
            Task {
                // Persist current state
                await appState.persistState()
            }
            
        case .background:
            // App entered background
            Task {
                // Perform cleanup
                await appState.persistState()
                
                // Schedule background tasks
                scheduleBackgroundTasks()
            }
            
        @unknown default:
            break
        }
    }
    
    /// Schedules background tasks
    private func scheduleBackgroundTasks() {
        let request = BGAppRefreshTaskRequest(identifier: "com.founditure.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension FounditureApp: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle foreground notifications
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification response
        let userInfo = response.notification.request.content.userInfo
        
        // Process notification data
        Task {
            await handleNotificationResponse(userInfo)
            completionHandler()
        }
    }
    
    /// Handles notification response data
    private func handleNotificationResponse(_ userInfo: [AnyHashable: Any]) async {
        if let type = userInfo["type"] as? String {
            switch type {
            case "message":
                if let messageId = userInfo["messageId"] as? String {
                    // Navigate to message
                    await navigateToMessage(messageId)
                }
                
            case "furniture":
                if let furnitureId = userInfo["furnitureId"] as? String {
                    // Navigate to furniture details
                    await navigateToFurniture(furnitureId)
                }
                
            default:
                break
            }
        }
    }
    
    /// Navigates to specific message
    private func navigateToMessage(_ messageId: String) async {
        // Handle message navigation
    }
    
    /// Navigates to furniture details
    private func navigateToFurniture(_ furnitureId: String) async {
        // Handle furniture navigation
    }
}

// MARK: - Preview Provider

#if DEBUG
struct FounditureApp_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            MainTabView()
                .environmentObject(AppState())
            
            // Dark mode preview
            MainTabView()
                .environmentObject(AppState())
                .preferredColorScheme(.dark)
        }
    }
}
#endif