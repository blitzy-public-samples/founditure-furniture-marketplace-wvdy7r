//
// MessageViewModel.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure WebSocket SSL certificates for secure connections
// 2. Set up message persistence encryption
// 3. Configure push notification handling for new messages
// 4. Set up offline message queue size limits
// 5. Configure message retention policies

import Foundation // iOS 14.0+
import Combine // iOS 14.0+
import SwiftUI // iOS 14.0+

/// ViewModel responsible for managing message-related business logic and real-time messaging functionality
/// Requirement: Real-time messaging - Implements real-time messaging system with WebSocket integration
@MainActor
final class MessageViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Collection of messages for the current conversation
    /// Requirement: Real-time messaging - Manages message state
    @Published private(set) var messages: [Message] = []
    
    /// Loading state indicator
    /// Requirement: Mobile Client Architecture - Loading state management
    @Published private(set) var isLoading: Bool = false
    
    /// Current error state
    /// Requirement: Mobile Client Architecture - Error handling
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    /// WebSocket service for real-time messaging
    /// Requirement: Real-time messaging - WebSocket integration
    private let webSocketService: WebSocketService
    
    /// Set of active Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Global application state
    private let appState: AppState
    
    /// Queue for handling offline messages
    /// Requirement: Offline-first architecture - Message queueing
    private var offlineMessageQueue: [(Message, UUID)] = []
    
    // MARK: - Initialization
    
    /// Initializes the MessageViewModel with required dependencies
    /// - Parameters:
    ///   - appState: Global application state
    ///   - webSocketService: WebSocket service for real-time messaging
    init(appState: AppState, webSocketService: WebSocketService) {
        self.appState = appState
        self.webSocketService = webSocketService
        setupSubscriptions()
        connectWebSocket()
    }
    
    // MARK: - Public Methods
    
    /// Sends a new message through WebSocket connection
    /// Requirement: Real-time messaging - Message sending functionality
    /// - Parameters:
    ///   - content: Message content
    ///   - receiverId: Recipient's UUID
    ///   - furnitureId: Optional furniture item UUID
    ///   - type: Type of message
    /// - Returns: Publisher emitting sent message or error
    func sendMessage(
        content: String,
        receiverId: UUID,
        furnitureId: UUID? = nil,
        type: MessageType
    ) -> AnyPublisher<Message, Error> {
        isLoading = true
        
        let message = Message(
            senderId: appState.currentUser.id,
            receiverId: receiverId,
            content: content,
            type: type,
            furnitureId: furnitureId
        )
        
        // Encode message for transmission
        guard let messageData = try? JSONEncoder().encode(message) else {
            return Fail(error: NSError(domain: "MessageEncoding", code: -1))
                .eraseToAnyPublisher()
        }
        
        // Handle offline scenario
        guard appState.isOnline else {
            offlineMessageQueue.append((message, receiverId))
            messages.append(message)
            isLoading = false
            return Just(message)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Send through WebSocket
        return webSocketService.send(message: messageData, type: .newMessage)
            .map { _ in message }
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveOutput: { [weak self] message in
                    self?.messages.append(message)
                }
            )
            .eraseToAnyPublisher()
    }
    
    /// Loads message history for a conversation
    /// Requirement: Real-time messaging - Message history management
    /// - Parameter conversationId: UUID of the conversation
    func loadMessages(conversationId: UUID) {
        isLoading = true
        
        // First load from local storage
        loadLocalMessages(conversationId: conversationId)
        
        // Then fetch from server if online
        guard appState.isOnline else {
            isLoading = false
            return
        }
        
        // Request message history through WebSocket
        let request = ["type": "history", "conversationId": conversationId.uuidString]
        guard let requestData = try? JSONEncoder().encode(request) else {
            handleError(NSError(domain: "MessageEncoding", code: -1))
            isLoading = false
            return
        }
        
        webSocketService.send(message: requestData, type: .newMessage)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    /// Marks messages as read
    /// Requirement: Real-time messaging - Message status management
    /// - Parameter messageIds: Array of message UUIDs to mark as read
    func markAsRead(_ messageIds: [UUID]) {
        let request = ["type": "read", "messageIds": messageIds.map { $0.uuidString }]
        guard let requestData = try? JSONEncoder().encode(request) else {
            handleError(NSError(domain: "MessageEncoding", code: -1))
            return
        }
        
        // Update local state
        messages = messages.map { message in
            if messageIds.contains(message.id) {
                message.markAsRead()
            }
            return message
        }
        
        // Send read receipts if online
        guard appState.isOnline else { return }
        
        webSocketService.send(message: requestData, type: .newMessage)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    /// Sets up Combine publishers and subscribers
    /// Requirement: Real-time capabilities - State synchronization
    private func setupSubscriptions() {
        // Subscribe to WebSocket events
        webSocketService.connect()
            .sink { [weak self] event in
                switch event {
                case .connected:
                    self?.handleWebSocketConnected()
                case .disconnected:
                    self?.handleWebSocketDisconnected()
                case .message(let data):
                    self?.handleWebSocketMessage(data)
                case .error(let error):
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to network state changes
        appState.$isOnline
            .sink { [weak self] isOnline in
                if isOnline {
                    self?.processPendingMessages()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Connects to WebSocket service
    /// Requirement: Real-time messaging - WebSocket connection management
    private func connectWebSocket() {
        webSocketService.connect()
            .sink { _ in }
            .store(in: &cancellables)
    }
    
    /// Handles WebSocket connection established
    private func handleWebSocketConnected() {
        if !offlineMessageQueue.isEmpty {
            processPendingMessages()
        }
    }
    
    /// Handles WebSocket disconnection
    private func handleWebSocketDisconnected() {
        // Implementation handled by WebSocketService reconnection logic
    }
    
    /// Processes WebSocket messages
    /// Requirement: Real-time messaging - Message processing
    private func handleWebSocketMessage(_ data: Data) {
        guard let message = try? JSONDecoder().decode(Message.self, from: data) else {
            handleError(NSError(domain: "MessageDecoding", code: -1))
            return
        }
        
        // Update message collection
        if !messages.contains(message) {
            messages.append(message)
            
            // Sort messages by timestamp
            messages.sort { $0.sentAt < $1.sentAt }
            
            // Mark as delivered
            message.markAsDelivered()
        }
    }
    
    /// Loads messages from local storage
    /// Requirement: Offline-first architecture - Local data persistence
    private func loadLocalMessages(conversationId: UUID) {
        // Load messages from CoreData or other local storage
        // Implementation depends on storage service
    }
    
    /// Processes pending offline messages
    /// Requirement: Offline-first architecture - Message queue processing
    private func processPendingMessages() {
        guard !offlineMessageQueue.isEmpty else { return }
        
        offlineMessageQueue.forEach { message, receiverId in
            guard let messageData = try? JSONEncoder().encode(message) else { return }
            
            webSocketService.send(message: messageData, type: .newMessage)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.handleError(error)
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
        
        offlineMessageQueue.removeAll()
    }
    
    /// Handles errors in a standardized way
    /// Requirement: Mobile Client Architecture - Error handling
    private func handleError(_ error: Error) {
        self.error = error
        isLoading = false
    }
}

// MARK: - ViewModelProtocol Conformance

extension MessageViewModel: ViewModelProtocol {
    convenience init(appState: AppState) {
        self.init(appState: appState, webSocketService: WebSocketService())
    }
    
    func cleanUp() {
        cancellables.removeAll()
        webSocketService.disconnect()
    }
}

// MARK: - WebSocketServiceDelegate Conformance

extension MessageViewModel: WebSocketServiceDelegate {
    func didReceiveMessage(_ message: Data, type: WebSocketMessageType) {
        handleWebSocketMessage(message)
    }
    
    func didChangeState(_ event: WebSocketEvent) {
        switch event {
        case .connected:
            handleWebSocketConnected()
        case .disconnected:
            handleWebSocketDisconnected()
        case .message(let data):
            handleWebSocketMessage(data)
        case .error(let error):
            handleError(error)
        }
    }
}