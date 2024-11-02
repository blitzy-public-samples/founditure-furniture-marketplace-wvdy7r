//
// String+Extension.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify that NSLocalizedString entries exist in Localizable.strings for all localized strings
// 2. Review regex patterns with security team for completeness
// 3. Ensure HTML sanitization rules meet security requirements

// Foundation - iOS 14.0+
import Foundation

// MARK: - String Extension
extension String {
    // MARK: - Private Constants
    private let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    private let phoneRegex = "^\\+?[1-9]\\d{1,14}$"
    private let passwordMinLength = 8
    
    // MARK: - Email Validation
    /// Validates if the string is a properly formatted email address
    /// Requirement: 7.1.3 Authentication Methods - Email validation for authentication
    var isValidEmail: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }
    
    // MARK: - Phone Validation
    /// Validates if the string is a properly formatted phone number
    /// Requirement: 7.1.3 Authentication Methods - Phone number validation
    var isValidPhone: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return predicate.evaluate(with: self)
    }
    
    // MARK: - Password Validation
    /// Validates if the string meets password requirements
    /// Requirement: 7.1.3 Authentication Methods - Password strength validation
    var isValidPassword: Bool {
        // Check minimum length
        guard count >= passwordMinLength else { return false }
        
        // Check for at least one uppercase letter
        guard self.range(of: "[A-Z]", options: .regularExpression) != nil else { return false }
        
        // Check for at least one lowercase letter
        guard self.range(of: "[a-z]", options: .regularExpression) != nil else { return false }
        
        // Check for at least one number
        guard self.range(of: "[0-9]", options: .regularExpression) != nil else { return false }
        
        // Check for at least one special character
        guard self.range(of: "[@$!%*?&#]", options: .regularExpression) != nil else { return false }
        
        return true
    }
    
    // MARK: - String Sanitization
    /// Returns a sanitized version of the string for safe storage and display
    /// Requirement: 7.2.2 Data Protection Measures - Input sanitization
    var sanitized: String {
        // Trim whitespace and newlines
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove HTML tags
        let htmlRemoved = trimmed.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        
        // Escape special characters for storage
        let escaped = htmlRemoved
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
        
        return escaped
    }
    
    // MARK: - String Truncation
    /// Returns truncated version of string with specified length and ellipsis
    /// Requirement: 1.2 Scope/Privacy Controls - Content display control
    func truncated(length: Int, withEllipsis: Bool = true) -> String {
        guard self.count > length else { return self }
        
        let truncated = String(self.prefix(length))
        return withEllipsis ? truncated + "..." : truncated
    }
    
    // MARK: - Localization
    /// Returns localized version of the string using app's localization
    /// Requirement: 1.2 Scope/Privacy Controls - Localization support
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}