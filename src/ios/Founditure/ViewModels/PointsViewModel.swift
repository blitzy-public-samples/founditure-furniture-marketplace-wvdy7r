//
// PointsViewModel.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure offline points sync thresholds
// 2. Set up points multiplier rules with product team
// 3. Configure streak calculation timezone settings
// 4. Set up analytics events for point transactions
// 5. Configure points expiration rules if applicable

import Foundation // iOS 14.0+
import Combine // iOS 14.0+

/// ViewModel responsible for managing points-related business logic and state
/// Requirement: Points system and leaderboards - Implements points system business logic and state management
@available(iOS 14.0, *)
@MainActor
final class PointsViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    
    /// Current points list
    /// Requirement: Points system and leaderboards - Tracks point transactions
    @Published private(set) var points: [Point] = []
    
    /// Total points accumulated
    /// Requirement: Points system and leaderboards - Maintains total points count
    @Published private(set) var totalPoints: Int = 0
    
    /// Current user streak
    /// Requirement: Points system and leaderboards - Tracks user engagement streaks
    @Published private(set) var currentStreak: Int = 0
    
    /// Loading state indicator
    /// Requirement: Mobile Client Architecture - Provides loading state feedback
    @Published var isLoading: Bool = false
    
    /// Current error state
    /// Requirement: Mobile Client Architecture - Handles error states
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    /// API service for network requests
    private let apiService: APIService
    
    /// Set of cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Global app state reference
    let appState: AppState
    
    // MARK: - Initialization
    
    /// Initializes the PointsViewModel with required dependencies
    /// Requirement: Mobile Client Architecture - Implements MVVM pattern
    /// - Parameters:
    ///   - apiService: API service for network communication
    ///   - appState: Global application state
    init(apiService: APIService, appState: AppState) {
        self.apiService = apiService
        self.appState = appState
        setupSubscriptions()
    }
    
    /// Required ViewModelProtocol initializer
    /// - Parameter appState: Global application state
    required init(appState: AppState) {
        self.apiService = APIService()
        self.appState = appState
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Sets up Combine publishers for points updates
    /// Requirement: Real-time capabilities - Handles points synchronization
    func setupSubscriptions() {
        // Monitor network connectivity changes
        NotificationCenter.default.publisher(for: .connectivityStatusChanged)
            .sink { [weak self] _ in
                Task {
                    await self?.syncOfflinePoints()
                }
            }
            .store(in: &cancellables)
        
        // Monitor app state changes
        appState.$isOnline
            .sink { [weak self] isOnline in
                if isOnline {
                    Task {
                        await self?.syncOfflinePoints()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Setup points update monitoring
        $points
            .sink { [weak self] points in
                self?.totalPoints = points.reduce(0) { $0 + $1.value }
                Task {
                    await self?.calculateStreak()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Retrieves user points from backend
    /// Requirement: Points system and leaderboards - Fetches point transactions
    /// - Returns: Publisher with points array
    func fetchPoints() -> AnyPublisher<[Point], Error> {
        isLoading = true
        
        return apiService.request(
            route: APIRouter.points,
            responseType: [Point].self
        )
        .receive(on: DispatchQueue.main)
        .handleEvents(
            receiveOutput: { [weak self] points in
                self?.points = points
                self?.isLoading = false
            },
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    /// Adds new points for a specific action
    /// Requirement: Points system and leaderboards - Handles point transactions
    /// - Parameters:
    ///   - value: Point value to add
    ///   - type: Type of point transaction
    ///   - description: Description of the transaction
    /// - Returns: Publisher with new point transaction
    func addPoints(value: Int, type: PointType, description: String) -> AnyPublisher<Point, Error> {
        guard let userId = appState.currentUser?.id else {
            return Fail(error: ServiceError.unauthorized).eraseToAnyPublisher()
        }
        
        let point = Point(
            value: value,
            type: type.rawValue,
            description: description,
            userId: userId
        )
        
        // Apply multipliers
        let finalValue = Int(Double(value) * point.calculateMultiplier())
        
        if appState.isOnline {
            return apiService.request(
                route: APIRouter.addPoints(point),
                responseType: Point.self
            )
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { [weak self] point in
                    self?.points.append(point)
                },
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                }
            )
            .eraseToAnyPublisher()
        } else {
            // Store offline point transaction
            point.isProcessed = false
            points.append(point)
            
            // Return successful result
            return Just(point)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    /// Calculates current user streak
    /// Requirement: Points system and leaderboards - Manages user streaks
    /// - Returns: Current streak count
    private func calculateStreak() async -> Int {
        let calendar = Calendar.current
        var currentStreak = 0
        var lastDate: Date?
        
        // Sort points by date
        let sortedPoints = points.sorted { $0.timestamp > $1.timestamp }
        
        // Calculate consecutive days
        for point in sortedPoints {
            if let last = lastDate {
                let daysDifference = calendar.dateComponents([.day], from: point.timestamp, to: last).day ?? 0
                
                if daysDifference == 1 {
                    currentStreak += 1
                } else if daysDifference > 1 {
                    break
                }
            } else {
                // First point
                if calendar.isDateInToday(point.timestamp) {
                    currentStreak = 1
                }
            }
            lastDate = point.timestamp
        }
        
        await MainActor.run {
            self.currentStreak = currentStreak
        }
        
        return currentStreak
    }
    
    /// Synchronizes offline point transactions
    /// Requirement: Offline-first architecture - Handles offline points synchronization
    private func syncOfflinePoints() async {
        guard appState.isOnline else { return }
        
        let unprocessedPoints = points.filter { !$0.isProcessed }
        
        for point in unprocessedPoints {
            do {
                _ = try await apiService.request(
                    route: APIRouter.addPoints(point),
                    responseType: Point.self
                )
                .async()
                
                if let index = points.firstIndex(where: { $0.id == point.id }) {
                    points[index].isProcessed = true
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Error Handling
    
    /// Handles errors in a standardized way
    /// Requirement: Mobile Client Architecture - Provides error handling
    func handleError(_ error: Error) {
        self.error = error
        isLoading = false
        
        // Log error
        Logger.error("PointsViewModel error: \(error.localizedDescription)")
        
        // Handle specific error cases
        if let serviceError = error as? ServiceError {
            switch serviceError {
            case .unauthorized:
                Task { @MainActor in
                    await appState.logout()
                }
            case .networkError:
                // Handle offline mode
                appState.isOnline = false
            default:
                break
            }
        }
    }
}

// MARK: - Publisher Extensions

extension Publisher {
    /// Converts publisher to async/await
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = first()
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    continuation.resume(returning: value)
                }
        }
    }
}