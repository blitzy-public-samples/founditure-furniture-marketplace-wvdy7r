//
// APIRouter.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify SSL certificate pinning configuration for production environment
// 2. Configure any environment-specific request timeouts
// 3. Set up error tracking and monitoring for network requests
// 4. Review and update parameter encoding strategies if needed
// 5. Configure any required proxy settings for development environment

import Foundation // version: iOS 14.0+

// MARK: - HTTP Method Enumeration
/// Defines supported HTTP methods for API requests
/// Requirement: RESTful API Communication - Implements standardized HTTP methods
public enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
    case PATCH
}

// MARK: - Parameter Encoding Enumeration
/// Defines supported parameter encoding types
/// Requirement: RESTful API Communication - Implements request parameter encoding
public enum ParameterEncoding {
    case URLEncoding
    case JSONEncoding
    case MultipartFormData
}

// MARK: - Router Error Enumeration
/// Defines possible routing errors
/// Requirement: Mobile Client Architecture - Implements error handling for network requests
enum RouterError: Error {
    case invalidURL
    case encodingFailed
    case missingRequiredParameter
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .encodingFailed:
            return "Failed to encode request parameters"
        case .missingRequiredParameter:
            return "Required parameter is missing"
        }
    }
}

// MARK: - API Routable Protocol
/// Protocol defining requirements for API route configuration
/// Requirement: Mobile Client Architecture - Implements type-safe routing system
public protocol APIRoutable {
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: [String: Any]? { get }
    var encoding: ParameterEncoding { get }
    var requiresAuth: Bool { get }
}

// MARK: - Request Builder
/// Utility class for building URLRequests from route configurations
/// Requirement: Mobile Client Architecture - Implements request configuration
/// Requirement: Security Architecture - Implements secure request configuration
@available(iOS 14.0, *)
class RequestBuilder {
    /// JSON encoder for parameter encoding
    private static let jsonEncoder = JSONEncoder()
    
    /// Builds URLRequest from APIRoutable configuration
    /// - Parameter route: Route configuration
    /// - Returns: Configured URLRequest
    /// - Throws: RouterError if configuration fails
    static func buildRequest(from route: APIRoutable) throws -> URLRequest {
        // Create base URL from APIConfig
        let baseURL = APIConfig.shared.getBaseURL()
        guard let url = URL(string: baseURL)?.appendingPathComponent(route.path) else {
            throw RouterError.invalidURL
        }
        
        // Create request with URL
        var request = URLRequest(url: url)
        
        // Set HTTP method
        request.httpMethod = route.method.rawValue
        
        // Add headers from APIConfig
        let headers = APIConfig.shared.getHeaders(requiresAuth: route.requiresAuth)
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // Encode parameters if present
        if let parameters = route.parameters {
            request.httpBody = try encodeParameters(parameters, encoding: route.encoding)
            
            // Set content type header based on encoding
            switch route.encoding {
            case .JSONEncoding:
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            case .URLEncoding:
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            case .MultipartFormData:
                let boundary = "Boundary-\(UUID().uuidString)"
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            }
        }
        
        return request
    }
    
    /// Encodes parameters according to specified encoding type
    /// - Parameters:
    ///   - parameters: Parameters to encode
    ///   - encoding: Encoding type to use
    /// - Returns: Encoded parameter data
    /// - Throws: RouterError if encoding fails
    private static func encodeParameters(_ parameters: [String: Any], encoding: ParameterEncoding) throws -> Data {
        switch encoding {
        case .JSONEncoding:
            return try JSONSerialization.data(withJSONObject: parameters, options: [])
            
        case .URLEncoding:
            let parameterArray = parameters.map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(value)"
                return "\(encodedKey)=\(encodedValue)"
            }
            let parameterString = parameterArray.joined(separator: "&")
            return parameterString.data(using: .utf8) ?? Data()
            
        case .MultipartFormData:
            var data = Data()
            let boundary = "Boundary-\(UUID().uuidString)"
            
            for (key, value) in parameters {
                data.append("--\(boundary)\r\n".data(using: .utf8)!)
                
                if let fileURL = value as? URL {
                    // Handle file upload
                    let filename = fileURL.lastPathComponent
                    let mimeType = "application/octet-stream"
                    
                    data.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                    data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                    data.append(try Data(contentsOf: fileURL))
                    data.append("\r\n".data(using: .utf8)!)
                } else {
                    // Handle regular form data
                    data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                    data.append("\(value)\r\n".data(using: .utf8)!)
                }
            }
            
            data.append("--\(boundary)--\r\n".data(using: .utf8)!)
            return data
        }
    }
}

// MARK: - APIRoutable Extension
/// Default implementation for APIRoutable protocol
extension APIRoutable {
    /// Default implementation of URLRequest creation
    /// Requirement: Mobile Client Architecture - Implements request building
    /// Requirement: Security Architecture - Implements secure request building
    public func asURLRequest() throws -> URLRequest {
        return try RequestBuilder.buildRequest(from: self)
    }
}