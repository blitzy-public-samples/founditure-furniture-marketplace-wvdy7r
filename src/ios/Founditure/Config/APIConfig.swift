//
// APIConfig.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure environment-specific base URLs in Info.plist or configuration file
// 2. Set up SSL certificate pinning for production environment
// 3. Configure any required proxy settings for development environment
// 4. Update timeout intervals based on network performance requirements
// 5. Configure any environment-specific API keys or tokens

import Foundation // version: iOS 14.0+

/// APIConfig: Singleton class managing API configuration and network settings
/// Requirement: Mobile Client Architecture - Implements network client configuration and API settings
/// Requirement: System Interactions - Manages API request configurations and routing
/// Requirement: Security Architecture - Implements API security configurations and headers
final class APIConfig {
    
    // MARK: - Constants
    
    private let DEFAULT_TIMEOUT_INTERVAL: TimeInterval = 30.0
    private let MAX_RETRY_ATTEMPTS: Int = 3
    private let API_VERSION_HEADER: String = "X-API-Version"
    
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = APIConfig()
    
    /// Environment-specific base URLs
    private let baseURLs: [Environment: String] = [
        .development: "https://api-dev.founditure.com",
        .staging: "https://api-staging.founditure.com",
        .production: "https://api.founditure.com"
    ]
    
    /// Current environment setting
    private(set) var currentEnvironment: Environment
    
    /// Network timeout interval
    private(set) var timeoutInterval: TimeInterval
    
    /// Maximum number of retry attempts for failed requests
    private(set) var maxRetryAttempts: Int
    
    /// Default headers applied to all requests
    private(set) var defaultHeaders: [String: String]
    
    // MARK: - Initialization
    
    private init() {
        // Initialize with current environment from AppConfig
        self.currentEnvironment = AppConfig.shared.environment
        
        // Set default timeout interval
        self.timeoutInterval = DEFAULT_TIMEOUT_INTERVAL
        
        // Configure retry attempts
        self.maxRetryAttempts = MAX_RETRY_ATTEMPTS
        
        // Setup default headers
        self.defaultHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            API_VERSION_HEADER: APIEndpoints.API_VERSION,
            "Accept-Language": Locale.current.languageCode ?? "en"
        ]
        
        // Configure initial environment
        configure(environment: currentEnvironment)
    }
    
    // MARK: - Configuration Methods
    
    /// Configures API settings based on current environment
    /// - Parameter environment: Target environment to configure
    func configure(environment: Environment) {
        self.currentEnvironment = environment
        
        // Update environment-specific settings
        switch environment {
        case .development:
            timeoutInterval = 60.0 // Longer timeout for development
            defaultHeaders["X-Environment"] = "development"
            
        case .staging:
            timeoutInterval = 45.0 // Medium timeout for staging
            defaultHeaders["X-Environment"] = "staging"
            
        case .production:
            timeoutInterval = DEFAULT_TIMEOUT_INTERVAL // Standard timeout for production
            defaultHeaders["X-Environment"] = "production"
        }
        
        // Update security headers
        configureSecurityHeaders()
        
        // Configure retry policy
        configureRetryPolicy()
    }
    
    /// Returns the base URL for the current environment
    /// - Returns: Base URL string for API requests
    func getBaseURL() -> String {
        return baseURLs[currentEnvironment] ?? baseURLs[.development]!
    }
    
    /// Returns headers for API requests
    /// - Parameter requiresAuth: Boolean indicating if authorization is required
    /// - Returns: Dictionary of header fields and values
    func getHeaders(requiresAuth: Bool = true) -> [String: String] {
        var headers = defaultHeaders
        
        if requiresAuth {
            // Add authorization header if required
            if let token = getAuthToken() {
                headers["Authorization"] = "Bearer \(token)"
            }
        }
        
        // Add environment-specific headers
        switch currentEnvironment {
        case .development:
            headers["X-Debug-Mode"] = "1"
        case .staging:
            headers["X-Staging-Mode"] = "1"
        case .production:
            // Add any production-specific headers
            break
        }
        
        return headers
    }
    
    /// Updates the network timeout interval
    /// - Parameter interval: New timeout interval in seconds
    func updateTimeoutInterval(_ interval: TimeInterval) {
        guard interval > 0 else { return }
        
        self.timeoutInterval = interval
        
        // Update URLSession configuration if needed
        updateSessionConfiguration()
    }
    
    // MARK: - Private Methods
    
    private func configureSecurityHeaders() {
        // Add security headers
        defaultHeaders["X-Content-Type-Options"] = "nosniff"
        defaultHeaders["X-XSS-Protection"] = "1; mode=block"
        defaultHeaders["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        
        if currentEnvironment == .production {
            // Add additional security headers for production
            defaultHeaders["X-Frame-Options"] = "DENY"
            defaultHeaders["Content-Security-Policy"] = "default-src 'self'"
        }
    }
    
    private func configureRetryPolicy() {
        switch currentEnvironment {
        case .development:
            maxRetryAttempts = 5 // More retries for development
        case .staging:
            maxRetryAttempts = 4 // Medium retries for staging
        case .production:
            maxRetryAttempts = MAX_RETRY_ATTEMPTS // Standard retries for production
        }
    }
    
    private func getAuthToken() -> String? {
        // Implementation would retrieve token from secure storage
        // This is a placeholder for the actual secure token retrieval
        return nil
    }
    
    private func updateSessionConfiguration() {
        // Implementation would update URLSession configuration
        // with new timeout interval and other settings
    }
}