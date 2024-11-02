//
// ValidationHelper.swift
// Founditure
//
// HUMAN TASKS:
// 1. Review validation rules with security team
// 2. Verify error messages are properly localized
// 3. Ensure validation thresholds align with business requirements
// 4. Configure appropriate logging for validation failures

// Foundation - iOS 14.0+
import Foundation
import CoreLocation

/// ValidationHelper provides centralized validation logic for user inputs, data formats, and business rules
/// Requirement: 7.2 Data Security/7.2.2 Data Protection Measures - Input validation
final class ValidationHelper {
    
    // MARK: - Constants
    
    /// Maximum allowed size for furniture images (10MB)
    /// Requirement: 7.2 Data Security/7.2.2 Data Protection Measures - File size validation
    static let maxImageSize: Int = 10 * 1024 * 1024
    
    /// Maximum number of images allowed per furniture listing
    /// Requirement: 7.2 Data Security/7.2.2 Data Protection Measures - Content limits
    static let maxImagesPerFurniture: Int = 5
    
    /// Maximum length for chat messages
    /// Requirement: 7.2 Data Security/7.2.2 Data Protection Measures - Message length validation
    static let maxMessageLength: Int = 1000
    
    /// Maximum search radius in kilometers
    /// Requirement: 7.2 Data Security/7.2.2 Data Protection Measures - Location bounds validation
    static let maxSearchRadius: Double = 50.0
    
    // MARK: - User Credentials Validation
    
    /// Validates user login credentials
    /// Requirement: 7.2 Data Security/7.2.1 Encryption Standards - Credential validation
    static func validateUserCredentials(email: String, password: String) -> Result<Void, ValidationError> {
        // Check if email is not empty
        guard !email.isEmpty else {
            return .failure(.init(ValidationError.emptyField))
        }
        
        // Validate email format using String extension
        guard email.isValidEmail else {
            return .failure(.init(ValidationError.invalidEmail))
        }
        
        // Check if password is not empty
        guard !password.isEmpty else {
            return .failure(.init(ValidationError.emptyField))
        }
        
        // Password requirements are checked in String+Extension
        guard password.count >= 8 else {
            return .failure(.init(FurnitureError.invalidDescription))
        }
        
        return .success(())
    }
    
    // MARK: - Furniture Listing Validation
    
    /// Validates furniture listing data
    /// Requirement: 7.2 Data Security/7.2.2 Data Protection Measures - Content validation
    static func validateFurnitureListing(title: String, description: String, images: [UIImage], location: CLLocation?) -> Result<Void, ValidationError> {
        // Validate title
        guard !title.isEmpty else {
            return .failure(.init(ValidationError.emptyField))
        }
        
        guard title.count <= 100 else {
            return .failure(.init(FurnitureError.invalidDescription))
        }
        
        // Validate description
        guard !description.isEmpty else {
            return .failure(.init(ValidationError.emptyField))
        }
        
        guard description.count <= 1000 else {
            return .failure(.init(FurnitureError.invalidDescription))
        }
        
        // Validate number of images
        guard images.count <= maxImagesPerFurniture else {
            return .failure(.init(FurnitureError.tooManyImages))
        }
        
        // Validate image sizes
        for image in images {
            guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                return .failure(.init(FurnitureError.imageUploadFailed))
            }
            
            guard imageData.count <= maxImageSize else {
                return .failure(.init(FurnitureError.imageSizeTooLarge))
            }
        }
        
        // Verify location is provided
        guard location != nil else {
            return .failure(.init(FurnitureError.locationRequired))
        }
        
        return .success(())
    }
    
    // MARK: - Message Validation
    
    /// Validates chat message content
    /// Requirement: 7.2 Data Security/7.2.2 Data Protection Measures - Message validation
    static func validateMessage(content: String) -> Result<Void, ValidationError> {
        // Check if message is not empty
        guard !content.isEmpty else {
            return .failure(.init(MessageError.messageEmpty))
        }
        
        // Validate message length against maximum
        guard content.count <= maxMessageLength else {
            return .failure(.init(MessageError.messageTooLong))
        }
        
        // Check for inappropriate content (basic sanitization)
        let sanitizedContent = content.sanitized
        guard !sanitizedContent.isEmpty else {
            return .failure(.init(MessageError.messageEmpty))
        }
        
        return .success(())
    }
    
    // MARK: - Search Parameters Validation
    
    /// Validates search parameters for furniture discovery
    /// Requirement: 7.2 Data Security/7.2.2 Data Protection Measures - Search parameter validation
    static func validateSearchParameters(center: CLLocation?, radius: Double) -> Result<Void, ValidationError> {
        // Verify location is provided
        guard center != nil else {
            return .failure(.init(LocationError.locationUnavailable))
        }
        
        // Validate radius is within acceptable range
        guard radius > 0 && radius <= maxSearchRadius else {
            return .failure(.init(LocationError.invalidRadius))
        }
        
        return .success(())
    }
}