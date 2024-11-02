//
// APIClient.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure SSL certificate pinning in production environment
// 2. Set up proper request caching policies in Info.plist
// 3. Configure offline storage limits for request queue
// 4. Verify network permissions in app capabilities
// 5. Set up proper timeout intervals for different request types

import Foundation // version: iOS 14.0+
import Combine // version: iOS 14.0+

// MARK: - Enums

/// Supported HTTP methods for API requests
/// Requirement: System Interactions - Defines supported API methods
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// Custom error types for API operations
/// Requirement: System Interactions - Defines API error types
public enum APIError: Error {
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case unauthorized
    case serverError(Int)
    case offline
}

// MARK: - Protocols

/// Protocol defining API client interface for dependency injection
/// Requirement: Mobile Client Architecture - Defines API client interface
public protocol APIClientProtocol {
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        additionalHeaders: [String: String]?
    ) -> AnyPublisher<T, APIError>
}

// MARK: - API Client Implementation

/// Main API client class handling all network requests
/// Requirement: Mobile Client Architecture - Implements core network client
@available(iOS 14.0, *)
public final class APIClient: APIClientProtocol {
    // MARK: - Private Properties
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let queue: DispatchQueue
    private var requestQueue: [URLRequest]
    private let queueStorageKey = "com.founditure.requestQueue"
    
    // Dependency instances
    private let networkMonitor = NetworkMonitor.shared
    private let apiConfig = APIConfig.shared
    
    // MARK: - Initialization
    
    /// Initializes the API client with custom configuration
    /// Requirement: Mobile Client Architecture - Configures network client
    public init(configuration: URLSessionConfiguration = .default) {
        // Configure URLSession
        self.session = URLSession(configuration: configuration)
        
        // Initialize JSON encoder/decoder
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        
        // Initialize dispatch queue
        self.queue = DispatchQueue(label: "com.founditure.apiclient", qos: .userInitiated)
        
        // Initialize request queue
        self.requestQueue = []
        
        // Load persisted queue
        loadRequestQueue()
        
        // Set up network monitoring
        setupNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Makes a type-safe API request with automatic decoding
    /// Requirement: System Interactions - Handles API request/response cycle
    public func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable? = nil,
        additionalHeaders: [String: String]? = nil
    ) -> AnyPublisher<T, APIError> {
        // Check network connectivity
        guard networkMonitor.isConnected.value else {
            if method == .get {
                return Fail(error: APIError.offline).eraseToAnyPublisher()
            } else {
                // Queue non-GET requests for later
                do {
                    let request = try buildRequest(endpoint: endpoint, method: method, body: body, additionalHeaders: additionalHeaders)
                    queueRequest(request)
                    return Fail(error: APIError.offline).eraseToAnyPublisher()
                } catch {
                    return Fail(error: APIError.networkError(error)).eraseToAnyPublisher()
                }
            }
        }
        
        do {
            // Build request
            let request = try buildRequest(
                endpoint: endpoint,
                method: method,
                body: body,
                additionalHeaders: additionalHeaders
            )
            
            // Log request
            Logger.log(
                "API Request: \(method.rawValue) \(endpoint)",
                level: .info,
                category: .network
            )
            
            // Execute request and handle response
            return session.dataTaskPublisher(for: request)
                .tryMap { [weak self] data, response in
                    guard let self = self else { throw APIError.networkError(NSError(domain: "", code: -1)) }
                    return try self.handleResponse(data: data, response: response)
                }
                .decode(type: T.self, decoder: decoder)
                .mapError { error in
                    if let apiError = error as? APIError {
                        return apiError
                    }
                    if error is DecodingError {
                        return APIError.decodingError(error)
                    }
                    return APIError.networkError(error)
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: APIError.networkError(error)).eraseToAnyPublisher()
        }
    }
    
    // MARK: - Private Methods
    
    /// Builds URLRequest with proper configuration
    /// Requirement: Security Architecture - Implements secure request configuration
    private func buildRequest(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        additionalHeaders: [String: String]?
    ) throws -> URLRequest {
        // Construct URL
        guard let url = URL(string: "\(apiConfig.getBaseURL())/\(endpoint)") else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add headers
        apiConfig.getHeaders().forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        additionalHeaders?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body for non-GET requests
        if let body = body, method != .get {
            request.httpBody = try encoder.encode(body)
        }
        
        // Configure caching policy
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Set timeout
        request.timeoutInterval = apiConfig.timeoutInterval
        
        return request
    }
    
    /// Processes API response and handles errors
    /// Requirement: System Interactions - Handles API response processing
    private func handleResponse(data: Data, response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Log response
        Logger.log(
            "API Response: Status \(httpResponse.statusCode)",
            level: .info,
            category: .network
        )
        
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw APIError.unauthorized
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.invalidResponse
        }
    }
    
    /// Queues request for later execution when offline
    /// Requirement: Offline-first architecture - Implements offline request queueing
    private func queueRequest(_ request: URLRequest) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Add request to queue
            self.requestQueue.append(request)
            
            // Persist queue
            self.saveRequestQueue()
            
            // Log queued request
            Logger.log(
                "Request queued for offline execution",
                level: .info,
                category: .network
            )
        }
    }
    
    /// Sets up network connectivity monitoring
    /// Requirement: Offline-first architecture - Monitors network connectivity
    private func setupNetworkMonitoring() {
        networkMonitor.isConnected
            .filter { $0 }
            .sink { [weak self] _ in
                self?.processQueuedRequests()
            }
            .store(in: &cancellables)
    }
    
    /// Processes queued requests when back online
    /// Requirement: Offline-first architecture - Processes queued requests
    private func processQueuedRequests() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            guard !self.requestQueue.isEmpty else { return }
            
            Logger.log(
                "Processing \(self.requestQueue.count) queued requests",
                level: .info,
                category: .network
            )
            
            let requests = self.requestQueue
            self.requestQueue.removeAll()
            self.saveRequestQueue()
            
            for request in requests {
                self.session.dataTask(with: request) { data, response, error in
                    if let error = error {
                        Logger.log(
                            "Failed to process queued request: \(error.localizedDescription)",
                            level: .error,
                            category: .network,
                            error: error
                        )
                    }
                }.resume()
            }
        }
    }
    
    /// Persists request queue to disk
    private func saveRequestQueue() {
        queue.async {
            let requestData = self.requestQueue.compactMap { request -> Data? in
                guard let url = request.url?.absoluteString,
                      let method = request.httpMethod,
                      let headers = request.allHTTPHeaders else {
                    return nil
                }
                
                let requestInfo: [String: Any] = [
                    "url": url,
                    "method": method,
                    "headers": headers,
                    "body": request.httpBody ?? Data()
                ]
                
                return try? JSONSerialization.data(withJSONObject: requestInfo)
            }
            
            UserDefaults.standard.set(requestData, forKey: self.queueStorageKey)
        }
    }
    
    /// Loads persisted request queue from disk
    private func loadRequestQueue() {
        queue.async {
            guard let requestData = UserDefaults.standard.array(forKey: self.queueStorageKey) as? [Data] else {
                return
            }
            
            self.requestQueue = requestData.compactMap { data -> URLRequest? in
                guard let requestInfo = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let urlString = requestInfo["url"] as? String,
                      let url = URL(string: urlString),
                      let method = requestInfo["method"] as? String,
                      let headers = requestInfo["headers"] as? [String: String],
                      let bodyData = requestInfo["body"] as? Data else {
                    return nil
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = method
                headers.forEach { key, value in
                    request.setValue(value, forHTTPHeaderField: key)
                }
                request.httpBody = bodyData
                
                return request
            }
        }
    }
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - URLRequest Extensions

private extension URLRequest {
    var allHTTPHeaders: [String: String]? {
        allHTTPHeaderFields
    }
}