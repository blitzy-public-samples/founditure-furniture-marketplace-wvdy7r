//
// AppConfig.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify environment configuration in build settings
// 2. Set up appropriate provisioning profiles for each environment
// 3. Configure cache storage permissions in entitlements
// 4. Update Info.plist with required privacy descriptions
// 5. Set up keychain access groups if needed

// Foundation framework - iOS 14.0+
import Foundation

// Internal dependencies
import AppConstants

/// Environment enumeration for different application environments
/// Requirement: System Architecture - Manages client-side configuration for distributed cloud-based infrastructure
enum Environment {
    case development
    case staging
    case production
}

/// Configuration structure for application caching
/// Requirement: Mobile Applications - Implements native iOS application configuration with offline-first architecture
struct CacheConfiguration {
    let expirationInterval: TimeInterval
    let maxCacheSize: Int
    let clearOnLogout: Bool
}

/// Core configuration class managing application-wide settings and environment configurations
/// Requirement: Security Architecture - Implements security configuration and environment-specific settings
final class AppConfig {
    // MARK: - Properties
    
    /// Singleton instance
    static let shared = AppConfig()
    
    /// Current environment setting
    private(set) var environment: Environment
    
    /// Application version
    private(set) var appVersion: String
    
    /// Build number
    private(set) var buildNumber: String
    
    /// Dictionary of enabled features
    private(set) var enabledFeatures: [String: Bool]
    
    /// Cache configuration settings
    private(set) var cacheConfig: CacheConfiguration
    
    // MARK: - Initialization
    
    private init() {
        // Initialize with default development environment
        self.environment = .development
        
        // Load app version and build number from bundle
        let bundle = Bundle.main
        self.appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        self.buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        
        // Initialize feature flags from AppConstants
        self.enabledFeatures = [
            "offlineMode": Features.offlineMode,
            "imageRecognition": Features.imageRecognition,
            "locationSharing": Features.locationSharing,
            "pushNotifications": Features.pushNotifications,
            "chatEncryption": Features.chatEncryption,
            "biometricAuth": Features.biometricAuth
        ]
        
        // Setup default cache configuration
        self.cacheConfig = CacheConfiguration(
            expirationInterval: TimeInterval(App.cacheExpirationDays * 24 * 60 * 60),
            maxCacheSize: App.maxImageSize * App.maxImageCount,
            clearOnLogout: true
        )
    }
    
    // MARK: - Configuration Methods
    
    /// Configures application settings based on current environment
    /// - Parameter environment: The target environment to configure
    func configure(environment: Environment) {
        self.environment = environment
        
        // Load environment-specific configurations
        switch environment {
        case .development:
            configureDevelopment()
        case .staging:
            configureStaging()
        case .production:
            configureProduction()
        }
        
        // Initialize feature flags based on environment
        initializeFeatureFlags()
        
        // Setup cache settings
        setupCacheConfiguration()
        
        // Configure logging level
        configureLogging()
    }
    
    /// Checks if a specific feature is enabled
    /// - Parameter featureKey: The key of the feature to check
    /// - Returns: Boolean indicating if the feature is enabled
    func isFeatureEnabled(_ featureKey: String) -> Bool {
        return enabledFeatures[featureKey] ?? false
    }
    
    /// Updates cache configuration settings
    /// - Parameter config: New cache configuration to apply
    func updateCacheConfig(_ config: CacheConfiguration) {
        // Validate cache configuration
        guard config.expirationInterval > 0 && config.maxCacheSize > 0 else {
            return
        }
        
        // Update cache settings
        self.cacheConfig = config
        
        // Clear invalid cache if needed
        if config.clearOnLogout {
            clearInvalidCache()
        }
    }
    
    // MARK: - Private Methods
    
    private func configureDevelopment() {
        enabledFeatures["debugMode"] = true
        enabledFeatures["testFeatures"] = true
    }
    
    private func configureStaging() {
        enabledFeatures["debugMode"] = true
        enabledFeatures["testFeatures"] = false
    }
    
    private func configureProduction() {
        enabledFeatures["debugMode"] = false
        enabledFeatures["testFeatures"] = false
    }
    
    private func initializeFeatureFlags() {
        // Update feature flags based on environment
        switch environment {
        case .development:
            // Enable all features in development
            enabledFeatures.keys.forEach { enabledFeatures[$0] = true }
        case .staging:
            // Enable core features in staging
            enabledFeatures["offlineMode"] = true
            enabledFeatures["imageRecognition"] = true
        case .production:
            // Production features based on AppConstants
            enabledFeatures = [
                "offlineMode": Features.offlineMode,
                "imageRecognition": Features.imageRecognition,
                "locationSharing": Features.locationSharing,
                "pushNotifications": Features.pushNotifications,
                "chatEncryption": Features.chatEncryption,
                "biometricAuth": Features.biometricAuth
            ]
        }
    }
    
    private func setupCacheConfiguration() {
        let config = CacheConfiguration(
            expirationInterval: TimeInterval(App.cacheExpirationDays * 24 * 60 * 60),
            maxCacheSize: environment == .production ? App.maxImageSize * 2 : App.maxImageSize * App.maxImageCount,
            clearOnLogout: environment != .development
        )
        updateCacheConfig(config)
    }
    
    private func configureLogging() {
        // Set logging level based on environment
        switch environment {
        case .development:
            // Verbose logging for development
            print("Debug logging enabled")
        case .staging:
            // Warning and error logging for staging
            print("Warning logging enabled")
        case .production:
            // Error-only logging for production
            print("Error-only logging enabled")
        }
    }
    
    private func clearInvalidCache() {
        // Implementation for clearing invalid cache
        // This would typically involve clearing expired items and ensuring
        // cache size remains within configured limits
    }
}