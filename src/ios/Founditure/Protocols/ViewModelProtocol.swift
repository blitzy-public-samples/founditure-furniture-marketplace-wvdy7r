//
// ViewModelProtocol.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure error tracking integration
// 2. Set up analytics for state changes
// 3. Configure memory leak detection
// 4. Set up performance monitoring
// 5. Configure state persistence encryption

// External dependencies
import Combine // iOS 14.0+
import Foundation // iOS 14.0+

/// Core protocol that all ViewModels in the Founditure iOS app must conform to
/// Requirement: Mobile Client Architecture - Implements MVVM architecture pattern with SwiftUI
protocol ViewModelProtocol: ObservableObject {
    // MARK: - Required Properties
    
    /// Loading state indicator
    /// Requirement: Mobile Client Architecture - Provides standardized loading state management
    var isLoading: Bool { get }
    
    /// Current error state
    /// Requirement: Mobile Client Architecture - Provides standardized error handling
    var error: Error? { get }
    
    /// Reference to global application state
    /// Requirement: Offline-first architecture - Handles state persistence and offline data management
    var appState: AppState { get }
    
    // MARK: - Required Methods
    
    /// Initializes the ViewModel with required dependencies
    /// Requirement: Mobile Client Architecture - Implements MVVM architecture pattern with SwiftUI
    /// - Parameter appState: Global application state instance
    init(appState: AppState)
    
    /// Handles errors in a standardized way across ViewModels
    /// Requirement: Mobile Client Architecture - Provides standardized error handling
    /// - Parameter error: The error to handle
    func handleError(_ error: Error)
    
    /// Sets up Combine publishers and subscribers
    /// Requirement: Real-time capabilities - Supports real-time state updates and data synchronization
    func setupSubscriptions()
    
    /// Performs cleanup when ViewModel is deallocated
    /// Requirement: Mobile Client Architecture - Ensures proper resource management
    func cleanUp()
}

// MARK: - Default Implementation

extension ViewModelProtocol {
    /// Default error handling implementation
    /// Requirement: Mobile Client Architecture - Provides standardized error handling
    func handleError(_ error: Error) {
        // Log error details
        print("ViewModel Error: \(error.localizedDescription)")
        
        // Update loading state
        if let loadingPublisher = self as? any Publisher
            where Self.Output == Bool, Self.Failure == Never {
            (loadingPublisher as? Published<Bool>)?.wrappedValue = false
        }
        
        // Handle offline scenarios
        if let networkError = error as? URLError,
           networkError.code == .notConnectedToInternet {
            // Notify app state of offline mode
            Task {
                await appState.syncState()
            }
        }
        
        // Notify observers of error state
        NotificationCenter.default.post(
            name: NSNotification.Name("ViewModelError"),
            object: self,
            userInfo: ["error": error]
        )
    }
    
    /// Default subscription setup implementation
    /// Requirement: Real-time capabilities - Supports real-time state updates and data synchronization
    func setupSubscriptions() {
        // Create state observers
        if let statePublisher = self as? any Publisher {
            // Setup data bindings for state changes
            statePublisher
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    // Handle state updates
                }
                .store(in: &(self as? any Cancellable as? Set<AnyCancellable> ?? []))
        }
        
        // Configure error handlers
        NotificationCenter.default.publisher(for: NSNotification.Name("ViewModelError"))
            .sink { [weak self] notification in
                if let error = notification.userInfo?["error"] as? Error {
                    self?.handleError(error)
                }
            }
            .store(in: &(self as? any Cancellable as? Set<AnyCancellable> ?? []))
        
        // Initialize reactive streams
        setupDataStreams()
        
        // Store subscription references
        storeSubscriptions()
    }
    
    /// Default cleanup implementation
    /// Requirement: Mobile Client Architecture - Ensures proper resource management
    func cleanUp() {
        // Cancel subscriptions
        if var cancellable = self as? any Cancellable {
            cancellable = Set<AnyCancellable>()
        }
        
        // Clear cached data if needed
        clearCache()
        
        // Remove observers
        NotificationCenter.default.removeObserver(self)
        
        // Release resources
        releaseResources()
    }
    
    // MARK: - Private Helper Methods
    
    /// Sets up data streams for real-time updates
    private func setupDataStreams() {
        // Configure Combine publishers for real-time data
        if let publisher = self as? any Publisher {
            publisher
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.handleError(error)
                    }
                } receiveValue: { _ in
                    // Handle data updates
                }
                .store(in: &(self as? any Cancellable as? Set<AnyCancellable> ?? []))
        }
    }
    
    /// Stores subscription references
    private func storeSubscriptions() {
        // Store subscription references for cleanup
        if var cancellable = self as? any Cancellable {
            cancellable = Set<AnyCancellable>()
        }
    }
    
    /// Clears cached data
    private func clearCache() {
        // Clear any cached data specific to this ViewModel
        // Implementation depends on specific ViewModel needs
    }
    
    /// Releases resources
    private func releaseResources() {
        // Release any additional resources
        // Implementation depends on specific ViewModel needs
    }
}