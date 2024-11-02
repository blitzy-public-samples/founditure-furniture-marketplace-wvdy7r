//
// StorageProtocol.swift
// Founditure
//
// Human Tasks:
// 1. Ensure proper error handling is implemented in conforming types
// 2. Configure appropriate storage permissions in Info.plist
// 3. Set up keychain access groups if using secure storage
// 4. Implement proper data migration strategies in conforming types

// Third-party imports
import Foundation  // iOS 14.0+
import Combine     // iOS 14.0+

/// Protocol defining the contract for data persistence operations in the application.
/// Addresses requirements:
/// - Local data persistence (1.2 Scope/Core System Components/Mobile Applications)
/// - Data Management (1.2 Scope/Core System Components/Data Management)
/// - Privacy controls (1.2 Scope/Included Features)
protocol StorageProtocol {
    /// Generic type that must conform to Codable for data storage and retrieval
    associatedtype T: Codable
    
    /// Saves data to persistent storage.
    /// - Parameters:
    ///   - data: The data to be stored, must conform to Codable
    ///   - key: Unique identifier for the stored data
    /// - Returns: A publisher that emits a boolean indicating success or failure
    func save(_ data: T, key: String) -> AnyPublisher<Bool, Error>
    
    /// Retrieves data from storage with type safety.
    /// - Parameters:
    ///   - key: Unique identifier for the stored data
    ///   - type: The expected type of the stored data
    /// - Returns: A publisher that emits the retrieved data or an error
    func retrieve(key: String, type: T.Type) -> AnyPublisher<T, Error>
    
    /// Removes data from storage.
    /// - Parameter key: Unique identifier for the data to be deleted
    /// - Returns: A publisher that emits a boolean indicating success or failure
    func delete(key: String) -> AnyPublisher<Bool, Error>
    
    /// Clears all stored data.
    /// - Returns: A publisher that emits a boolean indicating success or failure
    func clear() -> AnyPublisher<Bool, Error>
}