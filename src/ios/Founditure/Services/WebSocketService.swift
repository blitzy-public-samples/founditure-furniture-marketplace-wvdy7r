// MARK: - Human Tasks
/*
 TODO: Human Configuration Required
 1. Configure WebSocket SSL certificates for secure connections
 2. Set up WebSocket connection monitoring in APM tools
 3. Configure WebSocket reconnection thresholds in APIConfig
 4. Set up message queue persistence strategy for offline mode
 5. Verify WebSocket endpoint URLs in environment configurations
*/

import Foundation // v14.0+
import Combine // v14.0+

// MARK: - Internal Dependencies
import Protocols.ServiceProtocol
import Utils.Constants.APIEndpoints
import Utils.Logger

// MARK: - WebSocket Event Enumeration
/// Defines different types of WebSocket events
/// Requirement: Real-time Messaging - Event types for WebSocket communication
public enum WebSocketEvent {
    case connected
    case disconnected
    case message(Data)
    case error(Error)
}

// MARK: - WebSocket Message Type Enumeration
/// Types of messages that can be sent/received via WebSocket
/// Requirement: System Interactions - Message types for real-time updates
public enum WebSocketMessageType: String, Codable {
    case furnitureUpdate
    case newMessage
    case notification
    case locationUpdate
    case pointsUpdate
}

// MARK: - WebSocket Service Delegate Protocol
/// Protocol for handling WebSocket service events
/// Requirement: Real-time Messaging - Delegate pattern for WebSocket events
public protocol WebSocketServiceDelegate: AnyObject {
    /// Called when a new message is received
    func didReceiveMessage(_ message: Data, type: WebSocketMessageType)
    
    /// Called when connection state changes
    func didChangeState(_ event: WebSocketEvent)
}

// MARK: - WebSocket Service Implementation
/// Main service class handling WebSocket connections and message processing
/// Requirement: Mobile Client Architecture - Service layer WebSocket implementation
@available(iOS 14.0, *)
public class WebSocketService: NSObject, ServiceProtocol {
    // MARK: - Properties
    public var baseURL: String {
        return APIEndpoints.BASE_API_PATH
    }
    
    public var session: URLSession {
        return urlSession
    }
    
    private var urlSession: URLSession!
    private var webSocketTask: URLSessionWebSocketTask?
    private let eventSubject = PassthroughSubject<WebSocketEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var isConnected = false
    private let messageQueue = DispatchQueue(label: "com.founditure.websocket.messageQueue")
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var reconnectTimer: Timer?
    private var pendingMessages: [(Data, WebSocketMessageType)] = []
    
    // MARK: - Initialization
    public override init() {
        super.init()
        setupSession()
        setupMessageQueue()
    }
    
    // MARK: - Public Methods
    /// Establishes WebSocket connection with automatic retry
    /// Requirement: Real-time Messaging - WebSocket connection management
    public func connect() -> AnyPublisher<WebSocketEvent, Never> {
        guard !isConnected else {
            return eventSubject.eraseToAnyPublisher()
        }
        
        setupWebSocketTask()
        webSocketTask?.resume()
        receive()
        
        return eventSubject.eraseToAnyPublisher()
    }
    
    /// Gracefully closes WebSocket connection
    /// Requirement: System Interactions - Clean connection termination
    public func disconnect() {
        Logger.log("Disconnecting WebSocket", level: .info, category: .network)
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        eventSubject.send(.disconnected)
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        reconnectAttempts = 0
    }
    
    /// Sends a message through WebSocket connection
    /// Requirement: Real-time Messaging - Message sending functionality
    public func send(message: Data, type: WebSocketMessageType) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(ServiceError.unknownError))
                return
            }
            
            let messageWrapper = try? JSONEncoder().encode([
                "type": type.rawValue,
                "data": message.base64EncodedString()
            ])
            
            guard let messageWrapper = messageWrapper else {
                promise(.failure(ServiceError.encodingError))
                return
            }
            
            if !self.isConnected {
                self.queueMessage(message, type: type)
                promise(.failure(ServiceError.networkError))
                return
            }
            
            self.webSocketTask?.send(.data(messageWrapper)) { error in
                if let error = error {
                    Logger.log("Failed to send WebSocket message", level: .error, category: .network, error: error)
                    promise(.failure(error))
                } else {
                    Logger.log("WebSocket message sent successfully", level: .debug, category: .network)
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    private func setupSession() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    private func setupMessageQueue() {
        messageQueue.async { [weak self] in
            self?.processPendingMessages()
        }
    }
    
    private func setupWebSocketTask() {
        guard let url = URL(string: "\(baseURL)/ws") else {
            Logger.log("Invalid WebSocket URL", level: .error, category: .network)
            return
        }
        
        var request = URLRequest(url: url)
        // Add any required headers (e.g., authentication)
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        webSocketTask = urlSession.webSocketTask(with: request)
    }
    
    private func receive() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.receive() // Continue receiving messages
                
            case .failure(let error):
                Logger.log("WebSocket receive error", level: .error, category: .network, error: error)
                self.handleError(error)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            do {
                let decoder = JSONDecoder()
                let wrapper = try decoder.decode([String: String].self, from: data)
                
                guard let typeString = wrapper["type"],
                      let type = WebSocketMessageType(rawValue: typeString),
                      let base64Data = wrapper["data"],
                      let messageData = Data(base64Encoded: base64Data) else {
                    throw ServiceError.decodingError
                }
                
                eventSubject.send(.message(messageData))
                Logger.log("WebSocket message received", level: .debug, category: .network)
                
            } catch {
                Logger.log("Failed to decode WebSocket message", level: .error, category: .network, error: error)
            }
            
        case .string(let string):
            if let data = string.data(using: .utf8) {
                eventSubject.send(.message(data))
            }
            
        @unknown default:
            Logger.log("Unknown WebSocket message type received", level: .warning, category: .network)
        }
    }
    
    private func handleError(_ error: Error) {
        eventSubject.send(.error(error))
        isConnected = false
        
        if reconnectAttempts < maxReconnectAttempts {
            attemptReconnect()
        } else {
            Logger.log("Max reconnection attempts reached", level: .error, category: .network)
        }
    }
    
    private func attemptReconnect() {
        reconnectAttempts += 1
        let delay = Double(min(reconnectAttempts * 2, 30))
        
        Logger.log("Attempting WebSocket reconnection in \(delay) seconds", level: .info, category: .network)
        
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connect().sink { _ in }.store(in: &self!.cancellables)
        }
    }
    
    private func queueMessage(_ message: Data, type: WebSocketMessageType) {
        pendingMessages.append((message, type))
        Logger.log("Message queued for later sending", level: .debug, category: .network)
    }
    
    private func processPendingMessages() {
        guard isConnected else { return }
        
        while !pendingMessages.isEmpty {
            let (message, type) = pendingMessages.removeFirst()
            send(message: message, type: type)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            Logger.log("Failed to send queued message", level: .error, category: .network, error: error)
                            self?.queueMessage(message, type: type)
                        }
                    },
                    receiveValue: { _ in
                        Logger.log("Queued message sent successfully", level: .debug, category: .network)
                    }
                )
                .store(in: &cancellables)
        }
    }
}

// MARK: - URLSessionWebSocketDelegate Implementation
@available(iOS 14.0, *)
extension WebSocketService: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        reconnectAttempts = 0
        eventSubject.send(.connected)
        Logger.log("WebSocket connected", level: .info, category: .network)
        processPendingMessages()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
        eventSubject.send(.disconnected)
        
        if let reasonData = reason, let reasonString = String(data: reasonData, encoding: .utf8) {
            Logger.log("WebSocket closed: \(reasonString)", level: .info, category: .network)
        } else {
            Logger.log("WebSocket closed", level: .info, category: .network)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Logger.log("WebSocket session error", level: .error, category: .network, error: error)
            handleError(error)
        }
    }
}