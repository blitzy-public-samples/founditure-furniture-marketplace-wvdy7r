//
// FurnitureViewModel.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure CoreML model integration for furniture recognition
// 2. Set up S3 bucket permissions for furniture image storage
// 3. Configure location services permissions in Info.plist
// 4. Set up appropriate image compression settings
// 5. Configure furniture listing expiration notifications

import Foundation // iOS 14.0+
import Combine // iOS 14.0+
import CoreLocation // iOS 14.0+

/// ViewModel responsible for managing furniture listing data and business logic
/// Requirement: Furniture documentation and discovery - Manages furniture listing data and discovery features
@available(iOS 14.0, *)
final class FurnitureViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    
    /// List of all furniture items
    /// Requirement: Furniture documentation and discovery - Manages furniture listing data
    @Published private(set) var furnitureItems: [Furniture] = []
    
    /// Filtered list of furniture items based on current filters
    /// Requirement: Furniture documentation and discovery - Handles furniture filtering
    @Published private(set) var filteredItems: [Furniture] = []
    
    /// Currently selected furniture category filter
    /// Requirement: Furniture documentation and discovery - Manages category-based filtering
    @Published var selectedCategory: FurnitureCategory?
    
    /// Current search query for furniture filtering
    /// Requirement: Furniture documentation and discovery - Manages search functionality
    @Published var searchQuery: String = ""
    
    /// Radius in kilometers for location-based filtering
    /// Requirement: Location-based search - Handles location-based furniture filtering
    @Published var locationRadius: Double = 5.0
    
    // MARK: - ViewModelProtocol Properties
    
    /// Loading state indicator
    @Published private(set) var isLoading: Bool = false
    
    /// Current error state
    @Published private(set) var error: Error?
    
    /// Reference to global application state
    let appState: AppState
    
    // MARK: - Private Properties
    
    /// API service for network requests
    private let apiService: APIService
    
    /// Set of cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the furniture view model
    /// - Parameters:
    ///   - apiService: Service for API communication
    ///   - appState: Global application state
    required init(apiService: APIService, appState: AppState) {
        self.apiService = apiService
        self.appState = appState
        
        setupSubscriptions()
        loadInitialData()
    }
    
    /// Required initializer from ViewModelProtocol
    required init(appState: AppState) {
        self.appState = appState
        self.apiService = APIService()
        
        setupSubscriptions()
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// Fetches furniture items from the backend
    /// Requirement: Furniture documentation and discovery - Manages furniture data retrieval
    func fetchFurnitureItems() -> AnyPublisher<[Furniture], Error> {
        isLoading = true
        
        return apiService.request(
            route: APIRouter.getFurniture,
            responseType: [Furniture].self
        )
        .receive(on: DispatchQueue.main)
        .handleEvents(
            receiveOutput: { [weak self] items in
                self?.furnitureItems = items
                self?.applyFilters()
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
    
    /// Creates a new furniture listing
    /// Requirement: Furniture documentation and discovery - Handles furniture listing creation
    func createFurnitureListing(furniture: Furniture, images: [Data]) -> AnyPublisher<Furniture, Error> {
        isLoading = true
        
        // First upload images
        let imageUploads = images.map { imageData in
            apiService.upload(
                data: imageData,
                endpoint: "furniture/images",
                metadata: ["furnitureId": furniture.id.uuidString]
            )
        }
        
        // Wait for all image uploads to complete
        return Publishers.MergeMany(imageUploads)
            .collect()
            .flatMap { [weak self] _ -> AnyPublisher<Furniture, Error> in
                guard let self = self else {
                    return Fail(error: ServiceError.unknownError).eraseToAnyPublisher()
                }
                
                // Create furniture listing with uploaded image URLs
                return self.apiService.request(
                    route: APIRouter.createFurniture(furniture),
                    responseType: Furniture.self
                )
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { [weak self] newFurniture in
                    self?.furnitureItems.append(newFurniture)
                    self?.applyFilters()
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
    
    /// Updates the status of a furniture listing
    /// Requirement: Furniture documentation and discovery - Manages furniture status updates
    func updateFurnitureStatus(furnitureId: UUID, newStatus: FurnitureStatus) -> AnyPublisher<Furniture, Error> {
        isLoading = true
        
        return apiService.request(
            route: APIRouter.updateFurnitureStatus(id: furnitureId, status: newStatus),
            responseType: Furniture.self
        )
        .receive(on: DispatchQueue.main)
        .handleEvents(
            receiveOutput: { [weak self] updatedFurniture in
                if let index = self?.furnitureItems.firstIndex(where: { $0.id == updatedFurniture.id }) {
                    self?.furnitureItems[index] = updatedFurniture
                    self?.applyFilters()
                }
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
    
    // MARK: - Private Methods
    
    /// Applies current filters to furniture items
    /// Requirement: Furniture documentation and discovery - Implements filtering logic
    private func applyFilters() {
        var filtered = furnitureItems
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply search query filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { furniture in
                furniture.title.localizedCaseInsensitiveContains(searchQuery) ||
                furniture.description.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        // Apply location radius filter
        if let userLocation = appState.userLocation {
            filtered = filtered.filter { furniture in
                let furnitureLocation = CLLocation(
                    latitude: furniture.location.latitude,
                    longitude: furniture.location.longitude
                )
                let distance = userLocation.distance(from: furnitureLocation) / 1000 // Convert to km
                return distance <= locationRadius
            }
        }
        
        // Sort by distance if user location available
        if let userLocation = appState.userLocation {
            filtered.sort { furniture1, furniture2 in
                let location1 = CLLocation(
                    latitude: furniture1.location.latitude,
                    longitude: furniture1.location.longitude
                )
                let location2 = CLLocation(
                    latitude: furniture2.location.latitude,
                    longitude: furniture2.location.longitude
                )
                return userLocation.distance(from: location1) < userLocation.distance(from: location2)
            }
        }
        
        filteredItems = filtered
    }
    
    /// Loads initial furniture data
    private func loadInitialData() {
        fetchFurnitureItems()
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
    
    // MARK: - ViewModelProtocol Methods
    
    func setupSubscriptions() {
        // Observe category changes
        $selectedCategory
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Observe search query changes
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Observe location radius changes
        $locationRadius
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Observe user location changes
        appState.$userLocation
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    func handleError(_ error: Error) {
        self.error = error
        isLoading = false
    }
    
    func cleanUp() {
        cancellables.removeAll()
    }
}

// MARK: - FurnitureViewModel Extension
extension FurnitureViewModel {
    /// Enum defining possible furniture-related errors
    enum FurnitureError: LocalizedError {
        case invalidFurnitureData
        case imageUploadFailed
        case statusUpdateFailed
        case locationAccessDenied
        
        var errorDescription: String? {
            switch self {
            case .invalidFurnitureData:
                return "Invalid furniture data provided"
            case .imageUploadFailed:
                return "Failed to upload furniture images"
            case .statusUpdateFailed:
                return "Failed to update furniture status"
            case .locationAccessDenied:
                return "Location access is required for this feature"
            }
        }
    }
}