//
// Date+Extension.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify date formatting matches design specifications
// 2. Test with different time zones and locales
// 3. Ensure cache expiration logic aligns with backend requirements
// 4. Validate points history date formatting with product team

// Foundation framework - iOS 14.0+
import Foundation

/// Extension providing Founditure-specific date handling functionality
/// Requirement: Mobile Applications - Supports native iOS date handling and formatting requirements
extension Date {
    
    // MARK: - Computed Properties
    
    /// Checks if the date has exceeded the cache expiration period
    /// Requirement: Offline-first architecture - Enables consistent date handling in offline mode
    var isExpired: Bool {
        let calendar = Calendar.current
        let now = Date()
        let expirationDate = calendar.date(byAdding: .day, value: -App.cacheExpirationDays, to: now) ?? now
        return self < expirationDate
    }
    
    /// Returns a human-readable relative time string
    /// Requirement: Mobile Applications - Provides user-friendly time representations
    var timeAgo: String {
        return FormatterHelper.formatTimeAgo(self)
    }
    
    /// Checks if date is within today
    /// Requirement: Mobile Applications - Supports message timestamp formatting
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    // MARK: - Public Methods
    
    /// Formats date for furniture listing display
    /// Requirement: Mobile Applications - Provides consistent date formatting for listings
    /// - Parameter style: The desired date format style
    /// - Returns: A formatted date string for furniture listing
    func formatForListing(style: DateFormatter.Style = .medium) -> String {
        return FormatterHelper.formatDate(self, style: style)
    }
    
    /// Formats date for chat message timestamp
    /// Requirement: Mobile Applications - Supports message timestamp formatting
    /// - Returns: A formatted time string for messages
    func formatForMessage() -> String {
        if isToday {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: self)
        } else {
            return formatForListing(style: .short)
        }
    }
    
    /// Formats date for points history entries
    /// Requirement: Mobile Applications - Supports points history display
    /// - Returns: A formatted date string for points history
    func formatForPoints() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: self))"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            return formatForListing(style: .medium)
        }
    }
    
    /// Calculates days remaining until furniture listing expires
    /// Requirement: Mobile Applications - Supports listing expiration tracking
    /// - Returns: Number of days until expiry
    func daysUntilExpiry() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let expirationDate = calendar.date(byAdding: .day, value: App.cacheExpirationDays, to: self) ?? now
        
        let components = calendar.dateComponents([.day], from: now, to: expirationDate)
        let daysRemaining = components.day ?? 0
        
        return max(0, daysRemaining) // Ensure non-negative result
    }
}