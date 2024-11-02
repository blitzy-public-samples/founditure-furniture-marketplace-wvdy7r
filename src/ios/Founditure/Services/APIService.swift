//
// APIService.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure SSL certificate pinning for production environment
// 2. Set up request caching policies in Info.plist
// 3. Configure offline storage limits for request queue
// 4. Verify network permissions in app capabilities
// 5. Set up proper timeout intervals for different request types
// 6. Configure error tracking service integration
// 7. Set up monitoring for network request cancellations

import Foundation // version: iOS 14.0+
import Combine // version: iOS 14.0+

// MARK: - APIServiceProtocol Definition
/// Protocol defining the API service interface
/// Requirement: Mobile Client Architecture - Defines API service interface
@available(iOS 14.0, *)
public protocol APIServiceProtocol {
    /// Makes a type-safe API request with automatic response decoding
    /// - Parameters:
    ///   - route: API route configuration
    ///   - responseType: Expected response type
    /// - Returns: Publisher that emits decoded response or error
    func request<T: Decodable>(route: APIRoutable, responseType: T.Type) -> AnyPublisher<T, ServiceError>
    
    /// Uploads data with progress tracking
    /// - Parameters:
    ///   - data: Data to upload
    ///   - endpoint: Target endpoint
    ///   - metadata: Additional metadata
    /// - Returns: Publisher that emits upload progress
    func upload(data: Data, endpoint: String, metadata: [String: String]) -> AnyPublisher<Progress, ServiceError>
    
    /// Downloads data with progress tracking
    /// - Parameter url: URL to download from
    /// - Returns: Publisher that emits download progress and file URL
    func download(url: URL) -> AnyPublisher<(URL, Progress), ServiceError>
    
    /// Cancels a specific request
    /// - Parameter requestId: ID of request to cancel
    func cancelRequest(requestId: String)
}

// MARK: - APIService Implementation
/// Main API service class implementing ServiceProtocol for handling all network requests
/// Requirement: Mobile Client Architecture - Implements core API service layer
@available(iOS 14.0, *)
public final class APIService: ServiceProtocol, APIServiceProtocol {
    // MARK: - Properties
    
    public let baseURL: String
    public let session: URLSession
    private let apiClient: APIClient
    private let config: APIConfig
    private var cancellables = Set<AnyCancellable>()
    private var activeRequests: [String: URLSessionTask] = [:]
    
    // MARK: - Initialization
    
    /// Initializes the API service with custom configuration
    /// Requirement: Mobile Client Architecture - Configures API service
    public init(configuration: URLSessionConfiguration = .default) {
        // Configure URLSession
        self.session = URLSession(configuration: configuration)
        
        // Initialize dependencies
        self.config = APIConfig.shared
        self.baseURL = config.getBaseURL()
        self.apiClient = APIClient(configuration: configuration)
        
        // Configure session
        configuration.timeoutIntervalForRequest = config.timeoutInterval
        configuration.timeoutIntervalForResource = config.timeoutInterval * 2
        configuration.waitsForConnectivity = true
        
        // Set up request monitoring
        setupRequestMonitoring()
    }
    
    // MARK: - APIServiceProtocol Implementation
    
    /// Makes a type-safe API request with automatic response decoding
    /// Requirement: System Interactions - Manages API request/response cycle
    public func request<T: Decodable>(
        route: APIRoutable,
        responseType: T.Type
    ) -> AnyPublisher<T, ServiceError> {
        do {
            // Build URLRequest from route
            let request = try route.asURLRequest()
            
            // Generate request ID
            let requestId = UUID().uuidString
            
            // Track request
            trackRequest(request, id: requestId)
            
            // Execute request through APIClient
            return apiClient.request(
                endpoint: route.path,
                method: route.method,
                body: route.parameters,
                additionalHeaders: route.requiresAuth ? config.getHeaders(requiresAuth: true) : nil
            )
            .mapError { [weak self] error -> ServiceError in
                self?.removeRequest(id: requestId)
                return self?.handleError(error) ?? .unknownError
            }
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.removeRequest(id: requestId)
                },
                receiveCancel: { [weak self] in
                    self?.removeRequest(id: requestId)
                }
            )
            .eraseToAnyPublisher()
        } catch {
            return Fail(error: handleError(error))
                .eraseToAnyPublisher()
        }
    }
    
    /// Uploads data with progress tracking
    /// Requirement: System Interactions - Implements file upload functionality
    public func upload(
        data: Data,
        endpoint: String,
        metadata: [String: String]
    ) -> AnyPublisher<Progress, ServiceError> {
        return Future<Progress, ServiceError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError))
                return
            }
            
            // Create upload request
            var request = URLRequest(url: URL(string: "\(self.baseURL)/\(endpoint)")!)
            request.httpMethod = "POST"
            
            // Add headers
            let headers = self.config.getHeaders(requiresAuth: true)
            headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            
            // Create upload task
            let requestId = UUID().uuidString
            let task = self.session.uploadTask(
                with: request,
                from: data
            ) { data, response, error in
                if let error = error {
                    promise(.failure(self.handleError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    promise(.failure(.invalidResponse))
                    return
                }
                
                // Create progress
                let progress = Progress(totalUnitCount: Int64(data?.count ?? 0))
                progress.completedUnitCount = progress.totalUnitCount
                promise(.success(progress))
            }
            
            // Track request
            self.trackRequest(task, id: requestId)
            
            // Start upload
            task.resume()
        }
        .eraseToAnyPublisher()
    }
    
    /// Downloads data with progress tracking
    /// Requirement: System Interactions - Implements file download functionality
    public func download(url: URL) -> AnyPublisher<(URL, Progress), ServiceError> {
        return Future<(URL, Progress), ServiceError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError))
                return
            }
            
            // Create download request
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            // Add headers
            let headers = self.config.getHeaders(requiresAuth: true)
            headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            
            // Create download task
            let requestId = UUID().uuidString
            let task = self.session.downloadTask(
                with: request
            ) { localURL, response, error in
                if let error = error {
                    promise(.failure(self.handleError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let localURL = localURL else {
                    promise(.failure(.invalidResponse))
                    return
                }
                
                // Create progress
                let progress = Progress(totalUnitCount: Int64(httpResponse.expectedContentLength))
                progress.completedUnitCount = progress.totalUnitCount
                
                promise(.success((localURL, progress)))
            }
            
            // Track request
            self.trackRequest(task, id: requestId)
            
            // Start download
            task.resume()
        }
        .eraseToAnyPublisher()
    }
    
    /// Cancels a specific request
    /// Requirement: Mobile Client Architecture - Implements request management
    public func cancelRequest(requestId: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if let task = self.activeRequests[requestId] {
                task.cancel()
                self.removeRequest(id: requestId)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private let queue = DispatchQueue(label: "com.founditure.apiservice", qos: .userInitiated)
    
    /// Tracks active requests
    private func trackRequest(_ request: URLRequest, id: String) {
        trackRequest(session.dataTask(with: request), id: id)
    }
    
    private func trackRequest(_ task: URLSessionTask, id: String) {
        queue.async { [weak self] in
            self?.activeRequests[id] = task
        }
    }
    
    /// Removes completed requests
    private func removeRequest(id: String) {
        queue.async { [weak self] in
            self?.activeRequests.removeValue(forKey: id)
        }
    }
    
    /// Sets up request monitoring
    private func setupRequestMonitoring() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                // Cancel non-essential requests when app enters background
                self?.cancelNonEssentialRequests()
            }
            .store(in: &cancellables)
    }
    
    /// Cancels non-essential requests
    private func cancelNonEssentialRequests() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Cancel requests that aren't critical
            self.activeRequests.forEach { id, task in
                if !self.isEssentialRequest(task.originalRequest) {
                    task.cancel()
                    self.removeRequest(id: id)
                }
            }
        }
    }
    
    /// Determines if a request is essential
    private func isEssentialRequest(_ request: URLRequest?) -> Bool {
        guard let path = request?.url?.path else { return false }
        
        // Define essential endpoints that shouldn't be cancelled
        let essentialPaths = [
            "/api/v1/auth",
            "/api/v1/sync"
        ]
        
        return essentialPaths.contains { path.hasPrefix($0) }
    }
}