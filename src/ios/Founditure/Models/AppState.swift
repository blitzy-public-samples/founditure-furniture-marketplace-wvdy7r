//
// AppState.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure Keychain integration for secure state persistence
// 2. Set up background sync task scheduling
// 3. Configure network reachability monitoring
// 4. Set up push notification handling
// 5. Configure local storage encryption

// External dependencies - iOS 14.0+
import Foundation
import SwiftUI
import Combine

// Internal dependencies
import User
import Furniture
import Message
import Point

/// Represents possible states of data synchronization
/// Requirement: Offline-first architecture - Manages local state persistence and synchronization
enum SyncState: String, Codable {
    case upToDate
    case syncing
    case needsSync
    case error
}

/// Represents network connection states
/// Requirement: Offline-first architecture - Manages local state persistence and synchronization
enum ConnectionState: String, Codable {
    case connected
    case disconnected
    case connecting
}

/// Main application state class that manages global app state
/// Requirement: Offline-first architecture - Manages local state persistence and synchronization
@MainActor
final class AppState: ObservableObject {
    // MARK: - Published Properties
    
    /// Current authenticated user
    /// Requirement: User authentication and authorization - Handles authentication state management
    @Published private(set) var currentUser: User?
    
    /// Authentication state
    /// Requirement: User authentication and authorization - Handles authentication state management
    @Published private(set) var isAuthenticated: Bool = false
    
    /// Loading state indicator
    @Published private(set) var isLoading: Bool = false
    
    /// Recent furniture listings
    /// Requirement: Furniture documentation and discovery - Manages furniture listing state
    @Published private(set) var recentFurniture: [Furniture] = []
    
    /// Unread messages
    /// Requirement: Real-time messaging - Manages messaging state and updates
    @Published private(set) var unreadMessages: [Message] = []
    
    /// Total user points
    /// Requirement: Points system and leaderboards - Manages points state
    @Published private(set) var totalPoints: Int = 0
    
    /// Network connection status
    /// Requirement: Offline-first architecture - Manages local state persistence and synchronization
    @Published private(set) var hasNetworkConnection: Bool = false
    
    /// Last sync timestamp
    /// Requirement: Offline-first architecture - Manages local state persistence and synchronization
    @Published private(set) var lastSyncTimestamp: Date?
    
    // MARK: - Private Properties
    
    /// App configuration dictionary
    private var appConfiguration: [String: Any] = [:]
    
    /// Cancellable subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Network monitor instance
    private let networkMonitor = NetworkMonitor.shared
    
    /// Background sync task identifier
    private var backgroundSyncTask: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Initialization
    
    /// Initializes the application state
    /// Requirement: Offline-first architecture - Manages local state persistence and synchronization
    init() {
        setupInitialState()
        setupObservers()
        setupNetworkMonitoring()
        setupBackgroundTasks()
    }
    
    // MARK: - Public Methods
    
    /// Updates authentication state after user login/logout
    /// Requirement: User authentication and authorization - Handles authentication state management
    /// - Parameter user: Optional user instance
    func updateAuthState(user: User?) {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            // Update current user and auth state
            currentUser = user
            isAuthenticated = user != nil
            
            // Update points if user exists
            if let user = user {
                totalPoints = user.totalPoints
            }
            
            // Trigger auth state notifications
            NotificationCenter.default.post(
                name: NSNotification.Name("AuthStateChanged"),
                object: self,
                userInfo: ["isAuthenticated": isAuthenticated]
            )
            
            // Update background tasks
            if isAuthenticated {
                startBackgroundTasks()
            } else {
                stopBackgroundTasks()
            }
            
            // Persist state
            await persistState()
        }
    }
    
    /// Updates the list of recent furniture items
    /// Requirement: Furniture documentation and discovery - Manages furniture listing state
    /// - Parameter furniture: Array of furniture items
    func updateFurnitureList(_ furniture: [Furniture]) {
        Task {
            // Sort furniture by timestamp
            let sortedFurniture = furniture.sorted { $0.createdAt > $1.createdAt }
            
            // Filter out expired or removed items
            let filteredFurniture = sortedFurniture.filter { 
                $0.status != .expired && $0.status != .removed 
            }
            
            // Update state
            recentFurniture = filteredFurniture
            
            // Persist changes
            await persistState()
            
            // Trigger UI updates
            NotificationCenter.default.post(
                name: NSNotification.Name("FurnitureListUpdated"),
                object: self,
                userInfo: ["count": filteredFurniture.count]
            )
        }
    }
    
    /// Processes incoming messages and updates unread count
    /// Requirement: Real-time messaging - Manages messaging state and updates
    /// - Parameter message: New message instance
    func handleNewMessage(_ message: Message) {
        Task {
            // Add message to unread array if not read
            if !message.isRead {
                unreadMessages.append(message)
                
                // Update badge count
                await updateMessageBadges()
                
                // Trigger local notification if needed
                if UIApplication.shared.applicationState != .active {
                    await sendMessageNotification(message)
                }
            }
            
            // Persist state
            await persistState()
        }
    }
    
    /// Synchronizes local state with backend
    /// Requirement: Offline-first architecture - Manages local state persistence and synchronization
    /// - Returns: Success status of sync operation
    func syncState() async -> Bool {
        guard hasNetworkConnection else { return false }
        
        do {
            // Start sync operation
            let syncStartTime = Date()
            
            // Fetch remote changes
            let remoteChanges = try await fetchRemoteChanges()
            
            // Resolve conflicts
            try await resolveConflicts(remoteChanges)
            
            // Update local state
            try await updateLocalState(remoteChanges)
            
            // Update sync timestamp
            lastSyncTimestamp = syncStartTime
            
            // Persist state
            await persistState()
            
            return true
        } catch {
            print("Sync error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up initial application state
    private func setupInitialState() {
        // Load persisted state
        if let persistedState = loadPersistedState() {
            currentUser = persistedState.currentUser
            isAuthenticated = persistedState.isAuthenticated
            recentFurniture = persistedState.recentFurniture
            unreadMessages = persistedState.unreadMessages
            totalPoints = persistedState.totalPoints
            lastSyncTimestamp = persistedState.lastSyncTimestamp
        }
        
        // Load app configuration
        appConfiguration = loadAppConfiguration()
    }
    
    /// Sets up state observation publishers
    private func setupObservers() {
        // Observe network state changes
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.hasNetworkConnection = connected
                if connected {
                    Task {
                        await self?.syncState()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe message updates
        NotificationCenter.default.publisher(for: NSNotification.Name("MessageRead"))
            .sink { [weak self] notification in
                if let messageId = notification.userInfo?["messageId"] as? UUID {
                    self?.unreadMessages.removeAll { $0.id == messageId }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Sets up network monitoring
    private func setupNetworkMonitoring() {
        networkMonitor.startMonitoring()
    }
    
    /// Sets up background tasks
    private func setupBackgroundTasks() {
        registerBackgroundTasks()
    }
    
    /// Starts background sync tasks
    private func startBackgroundTasks() {
        guard isAuthenticated else { return }
        scheduleBackgroundSync()
    }
    
    /// Stops background sync tasks
    private func stopBackgroundTasks() {
        UIApplication.shared.endBackgroundTask(backgroundSyncTask)
        backgroundSyncTask = .invalid
    }
    
    /// Updates message badge count
    private func updateMessageBadges() async {
        let badgeCount = unreadMessages.count
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = badgeCount
        }
    }
    
    /// Sends a local notification for new message
    private func sendMessageNotification(_ message: Message) async {
        let content = UNMutableNotificationContent()
        content.title = "New Message"
        content.body = message.content
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: message.id.uuidString,
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    /// Persists current state to local storage
    private func persistState() async {
        let state = AppStateData(
            currentUser: currentUser,
            isAuthenticated: isAuthenticated,
            recentFurniture: recentFurniture,
            unreadMessages: unreadMessages,
            totalPoints: totalPoints,
            lastSyncTimestamp: lastSyncTimestamp
        )
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(state)
            try data.write(to: getStateStorageURL())
        } catch {
            print("Failed to persist state: \(error.localizedDescription)")
        }
    }
    
    /// Loads persisted state from local storage
    private func loadPersistedState() -> AppStateData? {
        do {
            let data = try Data(contentsOf: getStateStorageURL())
            let decoder = JSONDecoder()
            return try decoder.decode(AppStateData.self, from: data)
        } catch {
            print("Failed to load persisted state: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Returns URL for state storage
    private func getStateStorageURL() -> URL {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        return documentsDirectory.appendingPathComponent("appState.json")
    }
    
    /// Loads app configuration
    private func loadAppConfiguration() -> [String: Any] {
        // Load configuration from plist or remote config
        return [:]
    }
    
    /// Registers background tasks
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.founditure.sync",
            using: nil
        ) { task in
            self.handleBackgroundSync(task as! BGProcessingTask)
        }
    }
    
    /// Schedules background sync task
    private func scheduleBackgroundSync() {
        let request = BGProcessingTaskRequest(identifier: "com.founditure.sync")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background sync: \(error.localizedDescription)")
        }
    }
    
    /// Handles background sync task
    private func handleBackgroundSync(_ task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            let success = await syncState()
            task.setTaskCompleted(success: success)
            
            // Schedule next sync
            if isAuthenticated {
                scheduleBackgroundSync()
            }
        }
    }
}

// MARK: - AppStateData

/// Structure for persisting app state
private struct AppStateData: Codable {
    let currentUser: User?
    let isAuthenticated: Bool
    let recentFurniture: [Furniture]
    let unreadMessages: [Message]
    let totalPoints: Int
    let lastSyncTimestamp: Date?
}