//
// AppDelegate.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure push notification certificates in Apple Developer Portal
// 2. Set up proper notification entitlements in project capabilities
// 3. Configure background modes for remote notifications
// 4. Set up proper environment configuration in build settings
// 5. Verify proper provisioning profiles for each environment

// UIKit framework - iOS 14.0+
import UIKit
// UserNotifications framework - iOS 14.0+
import UserNotifications
// Combine framework - iOS 14.0+
import Combine

/// Main application delegate class implementing core application lifecycle methods
/// Requirement: Mobile Applications - Implements native iOS application with offline-first architecture
@main
@available(iOS 14.0, *)
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Properties
    
    /// Notification service instance for handling push notifications
    /// Requirement: Push notifications - Handles push notification registration and management
    private var notificationService: NotificationService!
    
    /// Set of cancellables for managing Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UIApplicationDelegate Methods
    
    /// Called when application finishes launching
    /// Requirement: System Architecture - Initializes and configures client-side architecture components
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure application environment
        configureEnvironment()
        
        // Setup core services
        setupServices()
        
        // Request notification permissions and register for remote notifications
        setupNotifications()
        
        // Initialize offline storage
        initializeOfflineStorage()
        
        // Configure logging
        configureLogging()
        
        return true
    }
    
    /// Handles successful device token registration for push notifications
    /// Requirement: Push notifications - Handles push notification token registration
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Convert token to string format
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Log token registration
        Logger.log(
            "Registered for push notifications with token",
            level: .info,
            category: .security
        )
        
        // Register token with notification service
        notificationService.registerForPushNotifications()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Logger.log(
                            "Failed to register push notification token",
                            level: .error,
                            category: .security,
                            error: error
                        )
                    }
                },
                receiveValue: { _ in
                    Logger.log(
                        "Successfully registered push notification token",
                        level: .info,
                        category: .security
                    )
                }
            )
            .store(in: &cancellables)
    }
    
    /// Handles push notification reception
    /// Requirement: Push notifications - Processes received push notifications
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Process notification payload
        notificationService.handlePushNotification(userInfo)
        
        // Update application state
        updateApplicationState(with: userInfo)
        
        // Log notification receipt
        Logger.log(
            "Received remote notification",
            level: .info,
            category: .security
        )
        
        // Call completion handler
        completionHandler(.newData)
    }
    
    // MARK: - Private Methods
    
    /// Configures application environment settings
    private func configureEnvironment() {
        // Determine environment from build configuration
        #if DEBUG
        AppConfig.shared.configure(environment: .development)
        #elseif STAGING
        AppConfig.shared.configure(environment: .staging)
        #else
        AppConfig.shared.configure(environment: .production)
        #endif
        
        Logger.log(
            "Configured environment: \(AppConfig.shared.environment)",
            level: .info,
            category: .system
        )
    }
    
    /// Sets up core services
    private func setupServices() {
        // Initialize notification service
        notificationService = NotificationService(apiService: APIService())
        notificationService.delegate = self
        
        Logger.log(
            "Core services initialized",
            level: .info,
            category: .system
        )
    }
    
    /// Configures notification permissions and registration
    private func setupNotifications() {
        // Request notification authorization
        notificationService.requestAuthorization()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Logger.log(
                            "Failed to request notification authorization",
                            level: .error,
                            category: .security,
                            error: error
                        )
                    }
                },
                receiveValue: { granted in
                    if granted {
                        Logger.log(
                            "Notification authorization granted",
                            level: .info,
                            category: .security
                        )
                    } else {
                        Logger.log(
                            "Notification authorization denied",
                            level: .warning,
                            category: .security
                        )
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// Initializes offline storage system
    private func initializeOfflineStorage() {
        // Configure cache settings based on environment
        let cacheConfig = CacheConfiguration(
            expirationInterval: TimeInterval(7 * 24 * 60 * 60), // 7 days
            maxCacheSize: 100 * 1024 * 1024, // 100 MB
            clearOnLogout: true
        )
        AppConfig.shared.updateCacheConfig(cacheConfig)
        
        Logger.log(
            "Offline storage initialized",
            level: .info,
            category: .system
        )
    }
    
    /// Configures application logging
    private func configureLogging() {
        // Set logging level based on environment
        switch AppConfig.shared.environment {
        case .development:
            // Enable verbose logging
            Logger.setLogLevel(.debug)
        case .staging:
            // Enable info and above
            Logger.setLogLevel(.info)
        case .production:
            // Enable warnings and errors only
            Logger.setLogLevel(.warning)
        }
        
        Logger.log(
            "Logging configured",
            level: .info,
            category: .system
        )
    }
    
    /// Updates application state with notification data
    private func updateApplicationState(with userInfo: [AnyHashable: Any]) {
        // Extract notification type
        guard let type = userInfo["type"] as? String else { return }
        
        // Update relevant application state based on notification type
        switch type {
        case "message":
            updateUnreadMessageCount()
        case "furniture":
            updateNearbyFurnitureList()
        case "points":
            updateUserPoints()
        case "achievement":
            updateUserAchievements()
        default:
            break
        }
    }
    
    private func updateUnreadMessageCount() {
        // Update unread message badge count
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber += 1
        }
    }
    
    private func updateNearbyFurnitureList() {
        // Refresh nearby furniture data
        NotificationCenter.default.post(
            name: NSNotification.Name("RefreshNearbyFurniture"),
            object: nil
        )
    }
    
    private func updateUserPoints() {
        // Refresh user points
        NotificationCenter.default.post(
            name: NSNotification.Name("RefreshUserPoints"),
            object: nil
        )
    }
    
    private func updateUserAchievements() {
        // Refresh user achievements
        NotificationCenter.default.post(
            name: NSNotification.Name("RefreshUserAchievements"),
            object: nil
        )
    }
}

// MARK: - NotificationServiceDelegate Implementation
@available(iOS 14.0, *)
extension AppDelegate: NotificationServiceDelegate {
    /// Handles received notifications
    func didReceiveNotification(_ notification: UNNotification) {
        // Process notification content
        let content = notification.request.content
        
        // Log notification receipt
        Logger.log(
            "Received notification: \(content.title)",
            level: .info,
            category: .security
        )
        
        // Update application state based on notification category
        switch content.categoryIdentifier {
        case NotificationCategory.message.identifier:
            updateUnreadMessageCount()
        case NotificationCategory.furniture.identifier:
            updateNearbyFurnitureList()
        case NotificationCategory.points.identifier:
            updateUserPoints()
        case NotificationCategory.achievement.identifier:
            updateUserAchievements()
        default:
            break
        }
    }
    
    /// Handles notification selection
    func didSelectNotification(_ response: UNNotificationResponse) {
        // Process notification response
        let content = response.notification.request.content
        
        // Log notification selection
        Logger.log(
            "Selected notification: \(content.title)",
            level: .info,
            category: .security
        )
        
        // Handle notification action based on category
        switch content.categoryIdentifier {
        case NotificationCategory.message.identifier:
            handleMessageNotificationSelection(response)
        case NotificationCategory.furniture.identifier:
            handleFurnitureNotificationSelection(response)
        case NotificationCategory.points.identifier:
            handlePointsNotificationSelection(response)
        case NotificationCategory.achievement.identifier:
            handleAchievementNotificationSelection(response)
        default:
            break
        }
    }
    
    private func handleMessageNotificationSelection(_ response: UNNotificationResponse) {
        // Navigate to message thread
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenMessageThread"),
            object: response.notification.request.content.userInfo
        )
    }
    
    private func handleFurnitureNotificationSelection(_ response: UNNotificationResponse) {
        // Navigate to furniture details
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenFurnitureDetails"),
            object: response.notification.request.content.userInfo
        )
    }
    
    private func handlePointsNotificationSelection(_ response: UNNotificationResponse) {
        // Navigate to points summary
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenPointsSummary"),
            object: response.notification.request.content.userInfo
        )
    }
    
    private func handleAchievementNotificationSelection(_ response: UNNotificationResponse) {
        // Navigate to achievements
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenAchievements"),
            object: response.notification.request.content.userInfo
        )
    }
}