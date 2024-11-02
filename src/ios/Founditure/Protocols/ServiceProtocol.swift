// MARK: - Human Tasks
/*
 TODO: Human Configuration Required
 1. Configure URLSession certificates for SSL pinning
 2. Set up error tracking service integration (e.g., Sentry)
 3. Configure API rate limiting thresholds in APIConfig
 4. Set up monitoring for network request cancellations
 5. Verify error message localization strings are added
*/

import Foundation // v14.0+
import Combine // v14.0+

// MARK: - Service Error Definition
/// Standard error types for service operations
public enum ServiceError: LocalizedError {
    case networkError
    case decodingError
    case invalidResponse
    case unauthorized
    case serverError
    case validationError
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case .networkError:
            return NSLocalizedString("Network connection error occurred", comment: "Network error")
        case .decodingError:
            return NSLocalizedString("Failed to process server response", comment: "Decoding error")
        case .invalidResponse:
            return NSLocalizedString("Invalid server response received", comment: "Invalid response")
        case .unauthorized:
            return NSLocalizedString("Authentication required", comment: "Unauthorized error")
        case .serverError:
            return NSLocalizedString("Server error occurred", comment: "Server error")
        case .validationError:
            return NSLocalizedString("Invalid request parameters", comment: "Validation error")
        case .unknownError:
            return NSLocalizedString("An unknown error occurred", comment: "Unknown error")
        }
    }
}

// MARK: - Service Protocol Definition
/// Base protocol that all services must conform to, providing standard service functionality
@available(iOS 14.0, *)
public protocol ServiceProtocol {
    /// Base URL for the service endpoints
    var baseURL: String { get }
    
    /// URLSession instance for network requests
    var session: URLSession { get }
    
    /// Performs a type-safe network request
    /// - Parameters:
    ///   - request: URLRequest to be executed
    /// - Returns: Publisher that emits decoded response or error
    func performRequest<T: Decodable>(request: URLRequest) -> AnyPublisher<T, Error>
    
    /// Handles and standardizes error responses
    /// - Parameter error: Error to be processed
    /// - Returns: Standardized ServiceError
    func handleError(_ error: Error) -> ServiceError
    
    /// Cancels all pending network requests
    func cancelAllRequests()
}

// MARK: - Default Implementation
@available(iOS 14.0, *)
public extension ServiceProtocol {
    func performRequest<T: Decodable>(request: URLRequest) -> AnyPublisher<T, Error> {
        // Requirement: Mobile Client Architecture - Standardized service implementation
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // Validate HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ServiceError.invalidResponse
                }
                
                // Check status code
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw ServiceError.unauthorized
                case 500...599:
                    throw ServiceError.serverError
                default:
                    throw ServiceError.invalidResponse
                }
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                // Map errors to ServiceError type
                return self.handleError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func handleError(_ error: Error) -> ServiceError {
        // Requirement: System Components - Standardized error handling
        switch error {
        case is URLError:
            return .networkError
        case is DecodingError:
            return .decodingError
        case let serviceError as ServiceError:
            return serviceError
        case let nsError as NSError:
            // Map NSError domains to appropriate service errors
            switch nsError.domain {
            case NSURLErrorDomain:
                return .networkError
            case NSCocoaErrorDomain:
                return .decodingError
            default:
                return .unknownError
            }
        default:
            return .unknownError
        }
    }
    
    func cancelAllRequests() {
        // Requirement: Mobile Client Architecture - Request management
        session.getAllTasks { tasks in
            tasks.forEach { task in
                task.cancel()
            }
        }
    }
}