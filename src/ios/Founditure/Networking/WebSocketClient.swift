//
// WebSocketClient.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure WebSocket heartbeat interval in production environment
// 2. Set up SSL certificate pinning for WebSocket connections
// 3. Configure proper reconnection backoff strategy based on network conditions
// 4. Set up proper error handling for production environment
// 5. Configure WebSocket compression if needed

import Foundation // version: iOS 14.0+
import Combine // version: iOS 14.0+

// MARK: - Internal Dependencies
import Config.APIConfig
import Utils.Logger

// MARK: - WebSocket Delegate Protocol
/// Protocol defining methods for WebSocket event handling
/// Requirement: Real-time messaging system - Defines WebSocket event handling interface
public protocol WebSocketDelegate: AnyObject {
    /// Called when WebSocket connection is established
    func didConnect()
    
    /// Called when WebSocket connection is closed
    func didDisconnect(error: Error?)
    
    /// Called when a message is received
    func didReceiveMessage(_ message: Data)
    
    /// Called when an error occurs
    func didReceiveError(_ error: Error)
}

// MARK: - Constants
private let MAX_RECONNECT_ATTEMPTS: Int = 5
private let PING_INTERVAL: TimeInterval = 30.0
private let CONNECTION_TIMEOUT: TimeInterval = 10.0

// MARK: - WebSocket Client Implementation
/// Core WebSocket client implementation handling real-time communication
/// Requirement: WebSocket connections - Provides WebSocket connection management
public final class WebSocketClient {
    // MARK: - Properties
    private weak var delegate: WebSocketDelegate?
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    private var isConnected: Bool = false
    private var reconnectAttempts: Int = 0
    private var pingTimer: Timer?
    
    // MARK: - Initialization
    /// Initializes WebSocket client with delegate
    /// - Parameter delegate: WebSocket event delegate
    public init(delegate: WebSocketDelegate?) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = CONNECTION_TIMEOUT
        
        self.session = URLSession(configuration: configuration)
        self.delegate = delegate
        
        // Log initialization
        Logger.log("WebSocket client initialized",
                  level: .info,
                  category: .network)
    }
    
    // MARK: - Public Methods
    /// Establishes WebSocket connection
    /// Requirement: System Interactions - Handles real-time data synchronization
    public func connect() {
        guard !isConnected else { return }
        
        // Get WebSocket URL from APIConfig
        let baseURL = APIConfig.shared.getBaseURL()
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
        
        guard let url = URL(string: "\(baseURL)/ws") else {
            Logger.log("Invalid WebSocket URL",
                      level: .error,
                      category: .network)
            return
        }
        
        // Create WebSocket task with headers
        var request = URLRequest(url: url)
        APIConfig.shared.getHeaders().forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        webSocketTask = session.webSocketTask(with: request)
        
        // Start receiving messages
        receiveMessage()
        
        // Resume WebSocket task
        webSocketTask?.resume()
        
        // Start ping timer
        startPingTimer()
        
        Logger.log("WebSocket connecting to \(url.absoluteString)",
                  level: .info,
                  category: .network)
    }
    
    /// Closes WebSocket connection
    public func disconnect() {
        stopPingTimer()
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        isConnected = false
        reconnectAttempts = 0
        
        Logger.log("WebSocket disconnected",
                  level: .info,
                  category: .network)
    }
    
    /// Sends a message through WebSocket
    /// - Parameter message: Data to send
    /// - Returns: Publisher indicating send result
    /// Requirement: Real-time messaging system - Implements message sending functionality
    public func send(_ message: Data) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self, self.isConnected else {
                promise(.failure(NSError(domain: "WebSocket",
                                      code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "WebSocket not connected"])))
                return
            }
            
            let message = URLSessionWebSocketTask.Message.data(message)
            self.webSocketTask?.send(message) { error in
                if let error = error {
                    Logger.log("Failed to send message",
                             level: .error,
                             category: .network,
                             error: error)
                    promise(.failure(error))
                } else {
                    Logger.log("Message sent successfully",
                             level: .debug,
                             category: .network)
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    /// Handles incoming WebSocket messages
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    Logger.log("Received message data",
                             level: .debug,
                             category: .network)
                    self.delegate?.didReceiveMessage(data)
                    
                case .string(let string):
                    if let data = string.data(using: .utf8) {
                        Logger.log("Received message string",
                                 level: .debug,
                                 category: .network)
                        self.delegate?.didReceiveMessage(data)
                    }
                    
                @unknown default:
                    Logger.log("Unknown message type received",
                             level: .warning,
                             category: .network)
                }
                
                // Continue receiving messages
                self.receiveMessage()
                
            case .failure(let error):
                Logger.log("WebSocket receive error",
                         level: .error,
                         category: .network,
                         error: error)
                
                self.delegate?.didReceiveError(error)
                self.handleDisconnection(error: error)
            }
        }
    }
    
    /// Manages automatic reconnection attempts
    private func handleReconnection() {
        guard reconnectAttempts < MAX_RECONNECT_ATTEMPTS else {
            Logger.log("Max reconnection attempts reached",
                      level: .error,
                      category: .network)
            delegate?.didDisconnect(error: NSError(domain: "WebSocket",
                                                 code: -1,
                                                 userInfo: [NSLocalizedDescriptionKey: "Max reconnection attempts reached"]))
            return
        }
        
        // Implement exponential backoff
        let delay = pow(2.0, Double(reconnectAttempts))
        reconnectAttempts += 1
        
        Logger.log("Attempting reconnection after \(delay) seconds (attempt \(reconnectAttempts))",
                  level: .info,
                  category: .network)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connect()
        }
    }
    
    /// Handles WebSocket disconnection
    private func handleDisconnection(error: Error?) {
        isConnected = false
        stopPingTimer()
        
        delegate?.didDisconnect(error: error)
        handleReconnection()
    }
    
    /// Starts ping timer for connection keep-alive
    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: PING_INTERVAL, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    /// Stops ping timer
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    /// Sends ping message to keep connection alive
    private func sendPing() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                Logger.log("Ping failed",
                         level: .error,
                         category: .network,
                         error: error)
                self?.handleDisconnection(error: error)
            }
        }
    }
}