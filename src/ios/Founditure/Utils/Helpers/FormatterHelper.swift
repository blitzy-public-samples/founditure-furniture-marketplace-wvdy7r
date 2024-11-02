//
// FormatterHelper.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify locale settings in device simulator for testing
// 2. Test with various regional formats to ensure proper localization
// 3. Verify points formatting matches design specifications
// 4. Ensure measurement units comply with regional standards

// Foundation framework - iOS 14.0+
import Foundation

/// Utility class providing centralized formatting functionality
/// Requirement: Mobile Applications - Provides consistent formatting across the native iOS application
final class FormatterHelper {
    
    // MARK: - Private Static Properties
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        return formatter
    }()
    
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .currency
        return formatter
    }()
    
    private static let pointsFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    // MARK: - Public Static Methods
    
    /// Formats a date according to the specified style and locale
    /// Requirement: Data Management - Ensures consistent data presentation formats
    /// - Parameters:
    ///   - date: The date to format
    ///   - style: The desired date format style
    /// - Returns: A formatted date string
    static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        dateFormatter.dateStyle = style
        return dateFormatter.string(from: date)
    }
    
    /// Formats a date as a relative time string
    /// Requirement: Data Management - Ensures consistent data presentation formats
    /// - Parameter date: The date to format
    /// - Returns: A relative time string (e.g., "2 hours ago")
    static func formatTimeAgo(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date, to: now)
        
        if let years = components.year, years > 0 {
            return "\(years) year\(years == 1 ? "" : "s") ago"
        } else if let months = components.month, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s") ago"
        } else if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
    
    /// Formats a points value with appropriate styling
    /// Requirement: Points System - Handles points and achievement score formatting
    /// - Parameter points: The points value to format
    /// - Returns: A formatted points string
    static func formatPoints(_ points: Int) -> String {
        guard let formattedPoints = pointsFormatter.string(from: NSNumber(value: points)) else {
            return String(points)
        }
        
        // Apply different formatting based on points thresholds from AppConstants
        if points >= Points.referralPoints {
            return "🏆 \(formattedPoints) pts"
        } else if points >= Points.baseRecoveryPoints {
            return "⭐️ \(formattedPoints) pts"
        } else {
            return "\(formattedPoints) pts"
        }
    }
    
    /// Formats a distance value in meters to appropriate unit
    /// Requirement: Mobile Applications - Provides consistent formatting across the native iOS application
    /// - Parameter meters: The distance in meters
    /// - Returns: A formatted distance string with appropriate unit
    static func formatDistance(_ meters: Double) -> String {
        let kilometers = meters / 1000
        
        if kilometers >= 1.0 {
            guard let formatted = numberFormatter.string(from: NSNumber(value: kilometers)) else {
                return String(format: "%.1f km", kilometers)
            }
            return "\(formatted) km"
        } else {
            guard let formatted = numberFormatter.string(from: NSNumber(value: meters)) else {
                return String(format: "%.0f m", meters)
            }
            return "\(formatted) m"
        }
    }
    
    /// Formats furniture dimensions with appropriate units
    /// Requirement: Data Management - Ensures consistent data presentation formats
    /// - Parameters:
    ///   - width: Width in centimeters
    ///   - height: Height in centimeters
    ///   - depth: Depth in centimeters
    /// - Returns: A formatted dimensions string
    static func formatDimensions(width: Double, height: Double, depth: Double) -> String {
        guard let formattedWidth = numberFormatter.string(from: NSNumber(value: width)),
              let formattedHeight = numberFormatter.string(from: NSNumber(value: height)),
              let formattedDepth = numberFormatter.string(from: NSNumber(value: depth)) else {
            return String(format: "%.1f × %.1f × %.1f cm", width, height, depth)
        }
        
        return "\(formattedWidth) × \(formattedHeight) × \(formattedDepth) cm"
    }
}