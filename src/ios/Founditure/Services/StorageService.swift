//
// StorageService.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure Keychain access groups in entitlements file
// 2. Add encryption key configuration in Info.plist
// 3. Set up proper data migration strategy for Core Data
// 4. Configure proper file protection levels for stored data
// 5. Verify proper backup settings for sensitive data

// Third-party imports
import Foundation  // iOS 14.0+
import Combine    // iOS 14.0+
import KeychainAccess  // v4.2.2

// Internal dependencies
import CoreData.CoreDataManager
import Utils.Logger

/// Defines different types of storage mechanisms available
/// Requirement: Data Management - Handles local database operations with multiple storage types
public enum StorageType {
    case coreData
    case userDefaults
    case keychain
}

/// A comprehensive storage service implementing StorageProtocol
/// Requirement: Local data persistence - Implements offline-first architecture
/// Requirement: Data Management - Handles local database operations
/// Requirement: Privacy Controls - Implements secure storage with encryption
public final class StorageService<T: Codable>: StorageProtocol {
    // MARK: - Properties
    
    private let coreDataManager: CoreDataManager
    private let userDefaults: UserDefaults
    private let keychain: KeychainAccess.Keychain
    
    // MARK: - Constants
    
    private let keychainService = "com.founditure.ios.secure-storage"
    private let keychainAccessGroup = "com.founditure.ios.shared"
    
    // MARK: - Initialization
    
    public init() {
        // Initialize CoreDataManager reference
        self.coreDataManager = CoreDataManager.shared
        
        // Set up UserDefaults instance
        self.userDefaults = UserDefaults.standard
        
        // Configure Keychain with service identifier and access group
        self.keychain = Keychain(service: keychainService, accessGroup: keychainAccessGroup)
            .accessibility(.afterFirstUnlock)
            .synchronizable(true)
        
        Logger.log(
            "StorageService initialized successfully",
            level: .info,
            category: .storage
        )
    }
    
    // MARK: - StorageProtocol Implementation
    
    /// Saves data to specified storage type with encryption for sensitive data
    /// Requirement: Privacy Controls - Implements secure storage with encryption
    public func save(_ data: T, key: String, storageType: StorageType = .userDefaults) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])))
                return
            }
            
            do {
                // Encode data to JSON
                let encoder = JSONEncoder()
                let encodedData = try encoder.encode(data)
                
                switch storageType {
                case .coreData:
                    // Save to Core Data
                    let success = self.saveToCoreData(encodedData, key: key)
                    promise(.success(success))
                    
                case .userDefaults:
                    // Save to UserDefaults
                    self.userDefaults.set(encodedData, forKey: key)
                    self.userDefaults.synchronize()
                    promise(.success(true))
                    
                case .keychain:
                    // Save to Keychain with encryption
                    try self.keychain
                        .accessibility(.afterFirstUnlock)
                        .set(encodedData, key: key)
                    promise(.success(true))
                }
                
                Logger.log(
                    "Data saved successfully for key: \(key)",
                    level: .info,
                    category: .storage
                )
            } catch {
                Logger.log(
                    "Failed to save data for key: \(key)",
                    level: .error,
                    category: .storage,
                    error: error
                )
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Retrieves and decodes data from specified storage
    /// Requirement: Local data persistence - Implements offline-first architecture
    public func retrieve(key: String, type: T.Type, storageType: StorageType = .userDefaults) -> AnyPublisher<T, Error> {
        return Future<T, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])))
                return
            }
            
            do {
                let data: Data?
                
                switch storageType {
                case .coreData:
                    // Retrieve from Core Data
                    data = self.retrieveFromCoreData(key: key)
                    
                case .userDefaults:
                    // Retrieve from UserDefaults
                    data = self.userDefaults.data(forKey: key)
                    
                case .keychain:
                    // Retrieve from Keychain
                    data = try self.keychain.getData(key)
                }
                
                guard let retrievedData = data else {
                    throw NSError(domain: "StorageService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data found for key: \(key)"])
                }
                
                // Decode data
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(T.self, from: retrievedData)
                
                Logger.log(
                    "Data retrieved successfully for key: \(key)",
                    level: .info,
                    category: .storage
                )
                
                promise(.success(decodedData))
            } catch {
                Logger.log(
                    "Failed to retrieve data for key: \(key)",
                    level: .error,
                    category: .storage,
                    error: error
                )
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Removes data from specified storage
    /// Requirement: Data Management - Handles local database operations
    public func delete(key: String, storageType: StorageType = .userDefaults) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])))
                return
            }
            
            do {
                switch storageType {
                case .coreData:
                    // Delete from Core Data
                    let success = self.deleteFromCoreData(key: key)
                    promise(.success(success))
                    
                case .userDefaults:
                    // Remove from UserDefaults
                    self.userDefaults.removeObject(forKey: key)
                    self.userDefaults.synchronize()
                    promise(.success(true))
                    
                case .keychain:
                    // Remove from Keychain
                    try self.keychain.remove(key)
                    promise(.success(true))
                }
                
                Logger.log(
                    "Data deleted successfully for key: \(key)",
                    level: .info,
                    category: .storage
                )
            } catch {
                Logger.log(
                    "Failed to delete data for key: \(key)",
                    level: .error,
                    category: .storage,
                    error: error
                )
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Clears all data from specified storage type
    /// Requirement: Data Management - Handles local database operations
    public func clear(storageType: StorageType = .userDefaults) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])))
                return
            }
            
            do {
                switch storageType {
                case .coreData:
                    // Clear Core Data storage
                    let success = self.coreDataManager.clearStorage()
                    promise(.success(success))
                    
                case .userDefaults:
                    // Clear UserDefaults
                    if let bundleId = Bundle.main.bundleIdentifier {
                        self.userDefaults.removePersistentDomain(forName: bundleId)
                    }
                    self.userDefaults.synchronize()
                    promise(.success(true))
                    
                case .keychain:
                    // Clear Keychain items
                    try self.keychain.removeAll()
                    promise(.success(true))
                }
                
                Logger.log(
                    "Storage cleared successfully for type: \(storageType)",
                    level: .info,
                    category: .storage
                )
            } catch {
                Logger.log(
                    "Failed to clear storage for type: \(storageType)",
                    level: .error,
                    category: .storage,
                    error: error
                )
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func saveToCoreData(_ data: Data, key: String) -> Bool {
        // Implementation would depend on Core Data model structure
        // This is a placeholder for the actual implementation
        return coreDataManager.saveContext()
    }
    
    private func retrieveFromCoreData(key: String) -> Data? {
        // Implementation would depend on Core Data model structure
        // This is a placeholder for the actual implementation
        return nil
    }
    
    private func deleteFromCoreData(key: String) -> Bool {
        // Implementation would depend on Core Data model structure
        // This is a placeholder for the actual implementation
        return coreDataManager.saveContext()
    }
}