//
// APIEndpoints.swift
// Founditure
//
// HUMAN TASKS:
// 1. Ensure BASE_URL is configured in APIConfig.swift for each environment (dev, staging, prod)
// 2. Update API_VERSION if version changes in backend
// 3. Verify all endpoint paths match backend routes configuration

import Foundation // version: iOS 14.0+

// MARK: - API Version and Base Path Constants
/// Current API version identifier
public let API_VERSION: String = "v1"

/// Base API path including version
public let BASE_API_PATH: String = "/api/v1"

/// Enumeration of all available API endpoints organized by feature domain
/// Requirement: RESTful API Communication - Defines standardized RESTful API endpoints
/// Requirement: Mobile Client Architecture - Provides endpoint definitions for network client
public enum APIEndpoints {
    
    // MARK: - Authentication Endpoints
    public enum auth {
        /// Endpoint for user login
        public static let login = "\(BASE_API_PATH)/auth/login"
        
        /// Endpoint for user registration
        public static let register = "\(BASE_API_PATH)/auth/register"
        
        /// Endpoint for password reset request
        public static let forgotPassword = "\(BASE_API_PATH)/auth/forgot-password"
        
        /// Endpoint for refreshing authentication token
        public static let refreshToken = "\(BASE_API_PATH)/auth/refresh"
    }
    
    // MARK: - Furniture Endpoints
    public enum furniture {
        /// Endpoint for creating new furniture listing
        public static let create = "\(BASE_API_PATH)/furniture"
        
        /// Endpoint for retrieving furniture listings
        public static let list = "\(BASE_API_PATH)/furniture"
        
        /// Endpoint for getting specific furniture details
        /// - Parameter id: Unique identifier of the furniture item
        public static func detail(_ id: String) -> String {
            return "\(BASE_API_PATH)/furniture/\(id)"
        }
        
        /// Endpoint for updating furniture listing
        /// - Parameter id: Unique identifier of the furniture item
        public static func update(_ id: String) -> String {
            return "\(BASE_API_PATH)/furniture/\(id)"
        }
        
        /// Endpoint for deleting furniture listing
        /// - Parameter id: Unique identifier of the furniture item
        public static func delete(_ id: String) -> String {
            return "\(BASE_API_PATH)/furniture/\(id)"
        }
        
        /// Endpoint for searching furniture listings
        public static let search = "\(BASE_API_PATH)/furniture/search"
    }
    
    // MARK: - Messages Endpoints
    public enum messages {
        /// Endpoint for retrieving message list
        public static let list = "\(BASE_API_PATH)/messages"
        
        /// Endpoint for sending new message
        public static let send = "\(BASE_API_PATH)/messages"
        
        /// Endpoint for retrieving conversation messages
        /// - Parameter conversationId: Unique identifier of the conversation
        public static func conversation(_ conversationId: String) -> String {
            return "\(BASE_API_PATH)/messages/\(conversationId)"
        }
        
        /// Endpoint for marking message as read
        /// - Parameter messageId: Unique identifier of the message
        public static func markRead(_ messageId: String) -> String {
            return "\(BASE_API_PATH)/messages/\(messageId)/read"
        }
    }
    
    // MARK: - Points Endpoints
    public enum points {
        /// Endpoint for retrieving user points
        /// - Parameter userId: Unique identifier of the user
        public static func get(_ userId: String) -> String {
            return "\(BASE_API_PATH)/points/\(userId)"
        }
        
        /// Endpoint for retrieving points history
        /// - Parameter userId: Unique identifier of the user
        public static func history(_ userId: String) -> String {
            return "\(BASE_API_PATH)/points/\(userId)/history"
        }
        
        /// Endpoint for retrieving points leaderboard
        public static let leaderboard = "\(BASE_API_PATH)/points/leaderboard"
    }
    
    // MARK: - Location Endpoints
    public enum location {
        /// Endpoint for updating user location
        public static let update = "\(BASE_API_PATH)/location"
        
        /// Endpoint for finding nearby items/users
        public static let nearby = "\(BASE_API_PATH)/location/nearby"
        
        /// Endpoint for geocoding addresses
        public static let geocode = "\(BASE_API_PATH)/location/geocode"
    }
    
    // MARK: - User Endpoints
    public enum user {
        /// Endpoint for retrieving user profile
        /// - Parameter userId: Unique identifier of the user
        public static func profile(_ userId: String) -> String {
            return "\(BASE_API_PATH)/users/\(userId)"
        }
        
        /// Endpoint for updating user profile
        /// - Parameter userId: Unique identifier of the user
        public static func update(_ userId: String) -> String {
            return "\(BASE_API_PATH)/users/\(userId)"
        }
        
        /// Endpoint for managing user preferences
        /// - Parameter userId: Unique identifier of the user
        public static func preferences(_ userId: String) -> String {
            return "\(BASE_API_PATH)/users/\(userId)/preferences"
        }
    }
    
    // MARK: - Media Endpoints
    public enum media {
        /// Endpoint for uploading media files
        public static let upload = "\(BASE_API_PATH)/media/upload"
        
        /// Endpoint for deleting media files
        /// - Parameter mediaId: Unique identifier of the media file
        public static func delete(_ mediaId: String) -> String {
            return "\(BASE_API_PATH)/media/\(mediaId)"
        }
    }
}