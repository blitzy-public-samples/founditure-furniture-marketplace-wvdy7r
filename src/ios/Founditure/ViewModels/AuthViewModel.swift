//
// AuthViewModel.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure analytics tracking for authentication events
// 2. Set up proper error tracking integration
// 3. Configure biometric authentication if required
// 4. Set up proper token refresh monitoring
// 5. Configure proper session timeout handling

import Foundation // iOS 14.0+
import Combine // iOS 14.0+

/// Represents possible authentication states
/// Requirement: Authentication Flow - Manages complete authentication flow including token refresh and error handling
enum AuthState {
    case unauthenticated
    case authenticated(User)
    case error(Error)
}

/// ViewModel responsible for managing authentication state and operations
/// Requirement: User registration and authentication - Implements user authentication and registration functionality for iOS client
@MainActor
final class AuthViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    
    @Published private(set) var authState: AuthState = .unauthenticated
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let appState: AppState
    
    // MARK: - Initialization
    
    /// Initializes the auth view model with required dependencies
    /// Requirement: Authentication Flow - Manages complete authentication flow including token refresh and error handling
    init(authService: AuthServiceProtocol, appState: AppState = AppState.shared) {
        self.authService = authService
        self.appState = appState
        
        // Setup state observers and check for existing session
        setupSubscriptions()
        checkExistingSession()
    }
    
    // MARK: - Public Methods
    
    /// Authenticates user with email and password
    /// Requirement: User registration and authentication - Implements user authentication functionality
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Publisher that emits authenticated user or error
    func login(email: String, password: String) -> AnyPublisher<User, Error> {
        isLoading = true
        error = nil
        
        return authService.login(email: email, password: password)
            .map { response -> User in
                // Create user instance from auth response
                let user = User(
                    email: email,
                    fullName: response.fullName ?? "",
                    phoneNumber: nil
                )
                user.id = UUID(uuidString: response.userId) ?? UUID()
                return user
            }
            .handleEvents(
                receiveOutput: { [weak self] user in
                    self?.authState = .authenticated(user)
                    self?.isLoading = false
                },
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                    self?.isLoading = false
                }
            )
            .eraseToAnyPublisher()
    }
    
    /// Registers new user account
    /// Requirement: User registration and authentication - Implements user registration functionality
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - fullName: User's full name
    /// - Returns: Publisher that emits registered user or error
    func register(email: String, password: String, fullName: String) -> AnyPublisher<User, Error> {
        isLoading = true
        error = nil
        
        return authService.register(email: email, password: password, fullName: fullName)
            .map { response -> User in
                // Create new user instance
                let user = User(
                    email: email,
                    fullName: fullName,
                    phoneNumber: nil
                )
                user.id = UUID(uuidString: response.userId) ?? UUID()
                return user
            }
            .handleEvents(
                receiveOutput: { [weak self] user in
                    self?.authState = .authenticated(user)
                    self?.isLoading = false
                },
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                    self?.isLoading = false
                }
            )
            .eraseToAnyPublisher()
    }
    
    /// Logs out current user
    /// Requirement: Authentication Flow - Manages complete authentication flow including token refresh and error handling
    /// - Returns: Publisher that completes or emits error
    func logout() -> AnyPublisher<Void, Error> {
        isLoading = true
        error = nil
        
        return authService.logout()
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.authState = .unauthenticated
                    case .failure(let error):
                        self?.handleError(error)
                    }
                    self?.isLoading = false
                }
            )
            .eraseToAnyPublisher()
    }
    
    // MARK: - ViewModelProtocol Implementation
    
    /// Handles authentication errors
    /// Requirement: Authentication Flow - Manages complete authentication flow including token refresh and error handling
    func handleError(_ error: Error) {
        self.error = error
        self.authState = .error(error)
        self.isLoading = false
        
        // Log error details
        print("Authentication Error: \(error.localizedDescription)")
        
        // Handle specific error cases
        if let authError = error as? AuthenticationError {
            switch authError {
            case .invalidCredentials:
                // Clear sensitive data
                authState = .unauthenticated
            case .sessionExpired:
                // Trigger re-authentication
                authState = .unauthenticated
            case .networkError:
                // Handle offline scenario
                Task {
                    await appState.syncState()
                }
            }
        }
        
        // Notify observers
        NotificationCenter.default.post(
            name: NSNotification.Name("AuthenticationError"),
            object: self,
            userInfo: ["error": error]
        )
    }
    
    /// Sets up Combine publishers and subscribers
    /// Requirement: Authentication Flow - Manages complete authentication flow including token refresh and error handling
    func setupSubscriptions() {
        // Observe auth state changes
        $authState
            .sink { [weak self] state in
                switch state {
                case .authenticated(let user):
                    // Update app state with authenticated user
                    self?.appState.currentUser = user
                case .unauthenticated:
                    // Clear user data
                    self?.appState.currentUser = nil
                case .error:
                    // Handle error state
                    break
                }
            }
            .store(in: &cancellables)
        
        // Monitor network connectivity
        NotificationCenter.default.publisher(for: .connectivityStatusChanged)
            .sink { [weak self] notification in
                if let isConnected = notification.object as? Bool, !isConnected {
                    // Handle offline mode
                    self?.handleOfflineMode()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Performs cleanup when ViewModel is deallocated
    /// Requirement: Authentication Flow - Manages complete authentication flow including token refresh and error handling
    func cleanUp() {
        cancellables.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Methods
    
    /// Checks for existing authentication session
    /// Requirement: Authentication Flow - Manages complete authentication flow including token refresh and error handling
    private func checkExistingSession() {
        // Check if user is already authenticated
        if let currentUser = appState.currentUser {
            authState = .authenticated(currentUser)
        }
    }
    
    /// Handles offline mode operations
    /// Requirement: Authentication Flow - Manages complete authentication flow including token refresh and error handling
    private func handleOfflineMode() {
        // Check if offline auth is possible
        if case .authenticated = authState {
            // Allow limited offline operations
            Task {
                await appState.enableOfflineMode()
            }
        }
    }
}

// MARK: - Authentication Errors

/// Custom authentication error types
/// Requirement: Authentication Flow - Manages complete authentication flow including token refresh and error handling
enum AuthenticationError: LocalizedError {
    case invalidCredentials
    case sessionExpired
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .sessionExpired:
            return "Your session has expired. Please log in again"
        case .networkError:
            return "Network connection error. Please try again"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}