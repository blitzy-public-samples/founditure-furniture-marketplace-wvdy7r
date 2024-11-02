//
// Color+Extension.swift
// Founditure
//
// HUMAN TASKS:
// 1. Add color assets to Assets.xcassets with names: Primary, Secondary, Accent, Background, Surface, Error, Success
// 2. Verify color assets are configured for both light and dark mode appearances
// 3. Ensure color assets match brand guidelines and accessibility standards (WCAG)

// SwiftUI framework - iOS 14.0+
import SwiftUI

// Import app constants for consistent theming
import "../Constants/AppConstants"

/// Extension on SwiftUI Color for app-specific colors and utility functions
/// Requirement: Mobile Applications - Implements native iOS UI theming and branding through SwiftUI Color extensions
/// Requirement: Mobile Client Architecture - Provides consistent color theming for UI components
extension Color {
    // MARK: - Brand Colors
    
    /// Primary brand color
    static let primary = Color("Primary")
    
    /// Secondary brand color
    static let secondary = Color("Secondary")
    
    /// Accent color for highlights and CTAs
    static let accent = Color("Accent")
    
    /// Main background color
    static let background = Color("Background")
    
    /// Surface/card background color
    static let surface = Color("Surface")
    
    /// Error and warning color
    static let error = Color("Error")
    
    /// Success and confirmation color
    static let success = Color("Success")
    
    // MARK: - Utility Functions
    
    /// Returns appropriate background color based on color scheme
    /// - Parameter colorScheme: Current color scheme (light/dark)
    /// - Returns: Dynamic background color based on scheme
    static func dynamicBackground(colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            return Color("Background")
        case .dark:
            return Color("Background").opacity(0.9)
        @unknown default:
            return Color("Background")
        }
    }
    
    /// Returns color with specified opacity
    /// - Parameter opacity: Desired opacity value between 0 and 1
    /// - Returns: Color with applied opacity
    func withOpacity(_ opacity: Double) -> Color {
        self.opacity(opacity)
    }
}