//
// NotificationService.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure push notification certificates in Apple Developer Portal
// 2. Set up notification categories and actions in Info.plist
// 3. Configure notification sound files in project bundle
// 4. Set up proper notification permissions in project capabilities
// 5. Configure notification service extension for rich notifications
// 6. Set up notification content extension for custom UI
// 7. Configure background modes for remote notifications

import Foundation // version: iOS 14.0+
import UserNotifications // version: iOS 14.0+
import Combine // version: iOS 14.0+

// MARK: - NotificationServiceDelegate Protocol
/// Protocol for handling notification responses and user interactions
/// Requirement: Push notifications - Defines notification handling interface
@available(iOS 14.0, *)
public protocol NotificationServiceDelegate: AnyObject {
    /// Called when a notification is received
    func didReceiveNotification(_ notification: UNNotification)
    
    /// Called when user taps on a notification
    func didSelectNotification(_ response: UNNotificationResponse)
}

// MARK: - NotificationCategory Enumeration
/// Defines different notification categories
/// Requirement: Push notifications - Categorizes different types of notifications
@available(iOS 14.0, *)
public enum NotificationCategory: String {
    case message = "message_category"
    case furniture = "furniture_category"
    case points = "points_category"
    case achievement = "achievement_category"
    case reminder = "reminder_category"
    
    var identifier: String {
        return rawValue
    }
}

// MARK: - NotificationService Implementation
/// Main service class for managing notifications
/// Requirement: Push notifications - Implements notification handling and management
@available(iOS 14.0, *)
public final class NotificationService: NSObject {
    // MARK: - Properties
    
    private let apiService: APIService
    private let center: UNUserNotificationCenter
    private var cancellables = Set<AnyCancellable>()
    public weak var delegate: NotificationServiceDelegate?
    
    // MARK: - Initialization
    
    /// Initializes the notification service
    /// Requirement: Push notifications - Sets up notification service
    public init(apiService: APIService) {
        self.apiService = apiService
        self.center = UNUserNotificationCenter.current()
        super.init()
        
        // Set notification center delegate
        center.delegate = self
        
        // Configure notification categories
        setupNotificationCategories()
        
        // Log initialization
        Logger.log(
            "NotificationService initialized",
            level: .info,
            category: .security
        )
    }
    
    // MARK: - Public Methods
    
    /// Requests notification permissions from user
    /// Requirement: Push notifications - Handles notification permission requests
    public func requestAuthorization() -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "NotificationService", code: -1)))
                return
            }
            
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            
            self.center.requestAuthorization(options: options) { granted, error in
                if let error = error {
                    Logger.log(
                        "Failed to request notification authorization",
                        level: .error,
                        category: .security,
                        error: error
                    )
                    promise(.failure(error))
                    return
                }
                
                Logger.log(
                    "Notification authorization status: \(granted)",
                    level: .info,
                    category: .security
                )
                
                promise(.success(granted))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Registers device for remote notifications
    /// Requirement: Push notifications - Handles device token registration
    public func registerForPushNotifications() -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                
                // Note: The actual token is received in AppDelegate/SceneDelegate
                // and should be forwarded to this service
                
                Logger.log(
                    "Registered for remote notifications",
                    level: .info,
                    category: .security
                )
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Schedules a local notification
    /// Requirement: Push notifications - Implements local notification scheduling
    public func scheduleLocalNotification(
        title: String,
        body: String,
        type: Notification,
        delay: TimeInterval
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Set category based on notification type
        switch type {
        case .newMessage:
            content.categoryIdentifier = NotificationCategory.message.identifier
        case .furnitureNearby:
            content.categoryIdentifier = NotificationCategory.furniture.identifier
        case .pointsEarned:
            content.categoryIdentifier = NotificationCategory.points.identifier
        case .achievementUnlocked:
            content.categoryIdentifier = NotificationCategory.achievement.identifier
        case .recoveryReminder:
            content.categoryIdentifier = NotificationCategory.reminder.identifier
        }
        
        // Create trigger with delay
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: delay,
            repeats: false
        )
        
        // Create request with unique identifier
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        // Add request to notification center
        center.add(request) { error in
            if let error = error {
                Logger.log(
                    "Failed to schedule local notification",
                    level: .error,
                    category: .security,
                    error: error
                )
                return
            }
            
            Logger.log(
                "Local notification scheduled: \(type)",
                level: .info,
                category: .security
            )
        }
    }
    
    /// Processes received push notification
    /// Requirement: Real-time messaging - Handles real-time message notifications
    public func handlePushNotification(_ userInfo: [AnyHashable: Any]) {
        // Parse notification payload
        guard let type = userInfo["type"] as? String else {
            Logger.log(
                "Invalid notification payload",
                level: .warning,
                category: .security
            )
            return
        }
        
        // Log notification receipt
        Logger.log(
            "Received push notification: \(type)",
            level: .info,
            category: .security
        )
        
        // Handle different notification types
        switch type {
        case Notification.newMessage:
            handleMessageNotification(userInfo)
        case Notification.furnitureNearby:
            handleFurnitureNotification(userInfo)
        case Notification.pointsEarned:
            handlePointsNotification(userInfo)
        case Notification.achievementUnlocked:
            handleAchievementNotification(userInfo)
        case Notification.recoveryReminder:
            handleReminderNotification(userInfo)
        default:
            Logger.log(
                "Unknown notification type: \(type)",
                level: .warning,
                category: .security
            )
        }
    }
    
    /// Cancels a pending notification
    /// Requirement: Push notifications - Implements notification cancellation
    public func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        Logger.log(
            "Cancelled notification: \(identifier)",
            level: .info,
            category: .security
        )
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationCategories() {
        // Message category actions
        let messageActions = [
            UNNotificationAction(
                identifier: "reply",
                title: "Reply",
                options: .foreground
            ),
            UNNotificationAction(
                identifier: "mark_read",
                title: "Mark as Read",
                options: .authenticationRequired
            )
        ]
        
        // Furniture category actions
        let furnitureActions = [
            UNNotificationAction(
                identifier: "view",
                title: "View Details",
                options: .foreground
            ),
            UNNotificationAction(
                identifier: "save",
                title: "Save Item",
                options: .authenticationRequired
            )
        ]
        
        // Points category actions
        let pointsActions = [
            UNNotificationAction(
                identifier: "view_points",
                title: "View Points",
                options: .foreground
            )
        ]
        
        // Create categories
        let categories: Set<UNNotificationCategory> = [
            UNNotificationCategory(
                identifier: NotificationCategory.message.identifier,
                actions: messageActions,
                intentIdentifiers: [],
                options: .customDismissAction
            ),
            UNNotificationCategory(
                identifier: NotificationCategory.furniture.identifier,
                actions: furnitureActions,
                intentIdentifiers: [],
                options: .customDismissAction
            ),
            UNNotificationCategory(
                identifier: NotificationCategory.points.identifier,
                actions: pointsActions,
                intentIdentifiers: [],
                options: .customDismissAction
            )
        ]
        
        // Set categories
        center.setNotificationCategories(categories)
    }
    
    private func handleMessageNotification(_ userInfo: [AnyHashable: Any]) {
        // Handle real-time message notifications
        if Features.pushNotifications {
            // Update unread message count
            // Notify message view controller
            // Update badge count
        }
    }
    
    private func handleFurnitureNotification(_ userInfo: [AnyHashable: Any]) {
        // Handle furniture-related notifications
        if Features.pushNotifications {
            // Update furniture list
            // Show nearby furniture alert
            // Update map annotations
        }
    }
    
    private func handlePointsNotification(_ userInfo: [AnyHashable: Any]) {
        // Handle points system notifications
        if Features.pushNotifications {
            // Update points balance
            // Show points animation
            // Update achievements progress
        }
    }
    
    private func handleAchievementNotification(_ userInfo: [AnyHashable: Any]) {
        // Handle achievement notifications
        if Features.pushNotifications {
            // Update achievements list
            // Show achievement animation
            // Update profile badges
        }
    }
    
    private func handleReminderNotification(_ userInfo: [AnyHashable: Any]) {
        // Handle reminder notifications
        if Features.pushNotifications {
            // Update reminders list
            // Show reminder alert
            // Update calendar events
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate Implementation
@available(iOS 14.0, *)
extension NotificationService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Log notification receipt
        Logger.log(
            "Will present notification: \(notification.request.identifier)",
            level: .info,
            category: .security
        )
        
        // Notify delegate
        delegate?.didReceiveNotification(notification)
        
        // Show notification banner and play sound
        completionHandler([.banner, .sound])
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Log notification selection
        Logger.log(
            "Did receive notification response: \(response.notification.request.identifier)",
            level: .info,
            category: .security
        )
        
        // Notify delegate
        delegate?.didSelectNotification(response)
        
        // Handle notification action
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // Handle default action (notification tapped)
            handleDefaultAction(response)
        case UNNotificationDismissActionIdentifier:
            // Handle dismiss action
            handleDismissAction(response)
        default:
            // Handle custom actions
            handleCustomAction(response)
        }
        
        completionHandler()
    }
    
    private func handleDefaultAction(_ response: UNNotificationResponse) {
        // Handle notification tap based on category
        switch response.notification.request.content.categoryIdentifier {
        case NotificationCategory.message.identifier:
            // Open message thread
            break
        case NotificationCategory.furniture.identifier:
            // Open furniture details
            break
        case NotificationCategory.points.identifier:
            // Open points summary
            break
        case NotificationCategory.achievement.identifier:
            // Open achievements
            break
        case NotificationCategory.reminder.identifier:
            // Open reminder details
            break
        default:
            break
        }
    }
    
    private func handleDismissAction(_ response: UNNotificationResponse) {
        // Handle notification dismissal
        Logger.log(
            "Notification dismissed: \(response.notification.request.identifier)",
            level: .info,
            category: .security
        )
    }
    
    private func handleCustomAction(_ response: UNNotificationResponse) {
        // Handle custom notification actions
        switch response.actionIdentifier {
        case "reply":
            // Handle message reply
            break
        case "mark_read":
            // Mark message as read
            break
        case "view":
            // View furniture details
            break
        case "save":
            // Save furniture item
            break
        case "view_points":
            // View points details
            break
        default:
            break
        }
    }
}