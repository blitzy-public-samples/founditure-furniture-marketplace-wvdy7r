//
// ProfileViewModel.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure analytics tracking for profile events
// 2. Set up proper error tracking integration
// 3. Configure user data backup strategy
// 4. Set up proper privacy compliance monitoring
// 5. Configure user data export functionality

import Foundation // iOS 14.0+
import Combine // iOS 14.0+
import SwiftUI // iOS 14.0+

/// ViewModel responsible for managing user profile data and interactions
/// Requirement: User registration and authentication - Manages user profile data and authentication state
@MainActor
final class ProfileViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    
    /// Current user data
    /// Requirement: User registration and authentication - Manages user profile data
    @Published private(set) var user: User?
    
    /// User's points history
    /// Requirement: Points system and leaderboards - Handles user points display and history
    @Published private(set) var pointsHistory: [Point] = []
    
    /// Profile edit mode state
    /// Requirement: User registration and authentication - Manages profile editing state
    @Published var isEditMode: Bool = false
    
    /// Loading state indicator
    /// Requirement: Mobile Client Architecture - Provides standardized loading state management
    @Published private(set) var isLoading: Bool = false
    
    /// Current error state
    /// Requirement: Mobile Client Architecture - Provides standardized error handling
    @Published private(set) var error: Error?
    
    // MARK: - Private Properties
    
    /// Authentication service reference
    private let authService: AuthService
    
    /// Global app state reference
    let appState: AppState
    
    /// Subscription storage
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the profile view model with required dependencies
    /// Requirement: Mobile Client Architecture - Implements MVVM architecture pattern
    /// - Parameters:
    ///   - authService: Authentication service instance
    ///   - appState: Global application state
    init(authService: AuthService, appState: AppState) {
        self.authService = authService
        self.appState = appState
        
        super.init(appState: appState)
        
        setupSubscriptions()
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// Updates user profile information
    /// Requirement: User registration and authentication - Manages user profile data
    /// - Parameters:
    ///   - fullName: User's full name
    ///   - phoneNumber: Optional phone number
    ///   - profileImageUrl: Optional profile image URL
    /// - Returns: Publisher that emits updated user or error
    func updateProfile(
        fullName: String,
        phoneNumber: String? = nil,
        profileImageUrl: URL? = nil
    ) -> AnyPublisher<User, Error> {
        isLoading = true
        
        // Validate input
        guard !fullName.isEmpty else {
            return Fail(error: ValidationError.invalidName).eraseToAnyPublisher()
        }
        
        // Create update request
        return Future<User, Error> { [weak self] promise in
            guard let self = self, let currentUser = self.user else {
                promise(.failure(ValidationError.userNotFound))
                return
            }
            
            // Update user properties
            let updatedUser = currentUser
            updatedUser.fullName = fullName
            updatedUser.phoneNumber = phoneNumber
            if let imageUrl = profileImageUrl {
                updatedUser.profileImageUrl = imageUrl.absoluteString
            }
            
            // Update app state
            Task {
                await self.appState.updateUser(updatedUser)
                self.user = updatedUser
                self.isLoading = false
                promise(.success(updatedUser))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Updates user privacy preferences
    /// Requirement: Privacy controls - Manages user privacy settings and preferences
    /// - Parameter settings: New privacy settings
    /// - Returns: Publisher that completes or emits error
    func updatePrivacySettings(settings: PrivacySettings) -> AnyPublisher<Void, Error> {
        isLoading = true
        
        return Future<Void, Error> { [weak self] promise in
            guard let self = self, let currentUser = self.user else {
                promise(.failure(ValidationError.userNotFound))
                return
            }
            
            // Update privacy settings
            currentUser.updatePrivacySettings(settings: settings)
            
            // Update app state
            Task {
                await self.appState.updateUser(currentUser)
                self.user = currentUser
                self.isLoading = false
                promise(.success(()))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Loads user points history
    /// Requirement: Points system and leaderboards - Handles user points display and history
    /// - Returns: Publisher that emits points history or error
    func loadPointsHistory() -> AnyPublisher<[Point], Error> {
        isLoading = true
        
        return Future<[Point], Error> { [weak self] promise in
            guard let self = self, let currentUser = self.user else {
                promise(.failure(ValidationError.userNotFound))
                return
            }
            
            // Fetch points history from app state
            Task {
                let points = await self.appState.getPointsHistory(for: currentUser.id)
                self.pointsHistory = points.sorted { $0.timestamp > $1.timestamp }
                self.isLoading = false
                promise(.success(self.pointsHistory))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Signs out the current user
    /// Requirement: User registration and authentication - Manages authentication state
    /// - Returns: Publisher that completes or emits error
    func signOut() -> AnyPublisher<Void, Error> {
        isLoading = true
        
        return authService.logout()
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                case .finished:
                    // Clear local user data
                    self.user = nil
                    self.pointsHistory = []
                    
                    // Reset view state
                    self.isEditMode = false
                    
                case .failure:
                    break
                }
                
                self.isLoading = false
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - ViewModelProtocol Implementation
    
    /// Sets up data subscriptions
    /// Requirement: Real-time capabilities - Supports real-time state updates
    func setupSubscriptions() {
        // Observe user changes
        appState.userPublisher
            .sink { [weak self] user in
                self?.user = user
            }
            .store(in: &cancellables)
        
        // Observe points updates
        appState.pointsPublisher
            .sink { [weak self] points in
                guard let self = self, let user = self.user else { return }
                self.pointsHistory = points.filter { $0.userId == user.id }
                    .sorted { $0.timestamp > $1.timestamp }
            }
            .store(in: &cancellables)
    }
    
    /// Handles errors in a standardized way
    /// Requirement: Mobile Client Architecture - Provides standardized error handling
    func handleError(_ error: Error) {
        self.error = error
        self.isLoading = false
    }
    
    /// Performs cleanup when ViewModel is deallocated
    /// Requirement: Mobile Client Architecture - Ensures proper resource management
    func cleanUp() {
        cancellables.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Loads initial user data
    private func loadInitialData() {
        Task {
            isLoading = true
            
            // Load user data from app state
            if let currentUser = await appState.currentUser {
                self.user = currentUser
                
                // Load points history
                _ = await loadPointsHistory()
                    .sink(
                        receiveCompletion: { [weak self] completion in
                            if case .failure(let error) = completion {
                                self?.handleError(error)
                            }
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables)
            }
            
            isLoading = false
        }
    }
}

// MARK: - Error Types

/// Validation errors for profile operations
private enum ValidationError: LocalizedError {
    case invalidName
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Please enter a valid name"
        case .userNotFound:
            return "User data not found"
        }
    }
}