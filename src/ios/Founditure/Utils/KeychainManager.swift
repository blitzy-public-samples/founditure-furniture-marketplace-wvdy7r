//
// KeychainManager.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure Keychain Sharing entitlement if needed for app groups
// 2. Verify proper keychain access groups in project capabilities
// 3. Set up proper keychain accessibility in production environment
// 4. Configure keychain item protection level based on security requirements
// 5. Ensure proper error handling for keychain access failures

// Foundation framework - iOS 14.0+
import Foundation
// Security framework - iOS 14.0+
import Security

// MARK: - Internal Dependencies
import Utils.Logger
import Utils.Constants.AppConstants

// MARK: - KeychainError Enum
/// Custom error types for keychain operations
/// Requirement: Security Architecture - Defines error types for secure storage operations
public enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unhandledError(status: OSStatus)
}

// MARK: - KeychainManager Class
/// Manages secure storage and retrieval of sensitive data using iOS Keychain Services
/// Requirement: Security Architecture - Implements secure storage using iOS Keychain for sensitive data
public final class KeychainManager {
    // MARK: - Properties
    private static let serviceName = "\(APP_BUNDLE_ID).keychain"
    private static let accessGroup = Features.biometricAuth ? "\(APP_BUNDLE_ID).keychain-group" : nil
    
    // MARK: - Initialization
    private init() {
        // Private initialization to enforce singleton pattern
    }
    
    // MARK: - Public Methods
    /// Saves data securely to the keychain
    /// Requirement: Data Security - Ensures encryption of sensitive data at rest using iOS Keychain Services
    public static func save(data: Data, key: String) -> Result<Void, KeychainError> {
        // Create query dictionary with service and account
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Add access group if available
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Set accessibility and protection level
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        
        // Attempt to save to keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            Logger.debug("Successfully saved data to keychain for key: \(key)", category: .security)
            return .success(())
            
        case errSecDuplicateItem:
            // Item already exists, attempt to update
            let updateQuery: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)
            
            if updateStatus == errSecSuccess {
                Logger.debug("Successfully updated existing keychain item for key: \(key)", category: .security)
                return .success(())
            } else {
                Logger.error("Failed to update existing keychain item for key: \(key)", category: .security)
                return .failure(.unhandledError(status: updateStatus))
            }
            
        default:
            Logger.error("Failed to save data to keychain for key: \(key)", category: .security)
            return .failure(.unhandledError(status: status))
        }
    }
    
    /// Retrieves data from the keychain
    /// Requirement: Authentication - Manages secure storage of authentication tokens and credentials
    public static func retrieve(key: String) -> Result<Data, KeychainError> {
        // Create query dictionary with service and account
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        // Add access group if available
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Attempt to fetch from keychain
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                Logger.error("Retrieved keychain item is not of type Data for key: \(key)", category: .security)
                return .failure(.invalidData)
            }
            Logger.debug("Successfully retrieved data from keychain for key: \(key)", category: .security)
            return .success(data)
            
        case errSecItemNotFound:
            Logger.debug("No keychain item found for key: \(key)", category: .security)
            return .failure(.itemNotFound)
            
        default:
            Logger.error("Failed to retrieve data from keychain for key: \(key)", category: .security)
            return .failure(.unhandledError(status: status))
        }
    }
    
    /// Deletes data from the keychain
    /// Requirement: Data Security - Ensures secure deletion of sensitive data
    public static func delete(key: String) -> Result<Void, KeychainError> {
        // Create query dictionary with service and account
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        // Add access group if available
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Attempt to delete from keychain
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess:
            Logger.debug("Successfully deleted keychain item for key: \(key)", category: .security)
            return .success(())
            
        case errSecItemNotFound:
            Logger.debug("No keychain item found to delete for key: \(key)", category: .security)
            return .failure(.itemNotFound)
            
        default:
            Logger.error("Failed to delete keychain item for key: \(key)", category: .security)
            return .failure(.unhandledError(status: status))
        }
    }
    
    /// Removes all keychain items for the app
    /// Requirement: Data Security - Provides complete data cleanup capability
    public static func clear() -> Result<Void, KeychainError> {
        // Create query dictionary with service
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        // Add access group if available
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Attempt to delete all items
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess:
            Logger.debug("Successfully cleared all keychain items", category: .security)
            return .success(())
            
        case errSecItemNotFound:
            Logger.debug("No keychain items found to clear", category: .security)
            return .success(())
            
        default:
            Logger.error("Failed to clear keychain items", category: .security)
            return .failure(.unhandledError(status: status))
        }
    }
}