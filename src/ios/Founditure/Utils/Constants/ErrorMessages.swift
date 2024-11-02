//
// ErrorMessages.swift
// Founditure
//
// HUMAN TASKS:
// 1. Ensure all error messages are properly localized in Localizable.strings
// 2. Review error messages with UX team for clarity and user-friendliness
// 3. Verify error messages comply with accessibility guidelines

// Foundation - iOS 14.0+
import Foundation

// MARK: - Authentication Errors
enum AuthenticationError {
    static let invalidCredentials = "Invalid email or password"
    static let accountNotFound = "Account not found"
    static let emailAlreadyExists = "Email is already registered"
    static let weakPassword = "Password must be at least 8 characters long"
    static let sessionExpired = "Your session has expired. Please login again"
    static let biometricsFailed = "Biometric authentication failed"
}

// MARK: - Network Errors
enum NetworkError {
    static let noInternet = "No internet connection available"
    static let requestTimeout = "Request timed out. Please try again"
    static let serverError = "Server error. Please try again later"
    static let connectionLost = "Connection lost. Please check your internet"
    static let invalidResponse = "Invalid response from server"
}

// MARK: - Validation Errors
enum ValidationError {
    static let invalidEmail = "Please enter a valid email address"
    static let invalidName = "Name cannot be empty"
    static let invalidPhone = "Please enter a valid phone number"
    static let invalidLocation = "Location services are required"
    static let emptyField = "This field cannot be empty"
}

// MARK: - Furniture Errors
enum FurnitureError {
    static let imageUploadFailed = "Failed to upload furniture images"
    static let invalidDescription = "Please provide a valid description"
    static let locationRequired = "Location is required for furniture listing"
    static let tooManyImages = "Maximum 5 images allowed"
    static let imageSizeTooLarge = "Image size exceeds 10MB limit"
}

// MARK: - Message Errors
enum MessageError {
    static let messageFailed = "Failed to send message"
    static let userBlocked = "You cannot message this user"
    static let chatDisabled = "Chat has been disabled"
    static let messageEmpty = "Message cannot be empty"
    static let messageTooLong = "Message exceeds maximum length"
}

// MARK: - Location Errors
enum LocationError {
    static let locationDenied = "Location access denied"
    static let locationUnavailable = "Location services unavailable"
    static let geofencingFailed = "Failed to set up location monitoring"
    static let invalidRadius = "Search radius out of valid range"
    static let locationUpdateFailed = "Failed to update location"
}

// MARK: - Generic Error Messages
enum GenericError {
    static let unexpected = "An unexpected error occurred"
    static let retry = "Please try again"
    static let contactSupport = "Please contact support if the problem persists"
}