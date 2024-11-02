//
// View+Extension.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify SwiftUI animations are enabled in Xcode project settings
// 2. Ensure accessibility labels are properly configured for UI components
// 3. Test loading overlay with VoiceOver enabled
// 4. Verify error banner contrast meets WCAG guidelines

// SwiftUI framework - iOS 14.0+
import SwiftUI

// Import required extensions and constants
import "../Constants/AppConstants"
import "./Color+Extension"

/// Extension on SwiftUI View for common UI modifications and styling
/// Requirement: Mobile Applications - Implements native iOS UI components and styling through SwiftUI View extensions
/// Requirement: Mobile Client Architecture - Provides reusable view modifiers and styling for consistent UI appearance
extension View {
    /// Applies standard card styling with shadow and corner radius
    /// - Returns: Modified view with card styling
    func cardStyle() -> some View {
        self
            .background(Color.background)
            .cornerRadius(12)
            .shadow(
                color: Color.primary.opacity(0.1),
                radius: 8,
                x: 0,
                y: 2
            )
            .padding(16)
    }
    
    /// Applies primary button styling with brand colors
    /// - Returns: Modified view with primary button styling
    func primaryButton() -> some View {
        self
            .background(Color.primary)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .animation(.easeInOut(duration: DEFAULT_ANIMATION_DURATION))
    }
    
    /// Adds a loading spinner overlay when loading state is true
    /// - Parameter isLoading: Boolean flag to control loading state
    /// - Returns: View with conditional loading overlay
    /// Requirement: Offline-first architecture - Implements loading state handling for offline-first functionality
    func loadingOverlay(isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    }
                    .transition(.opacity.animation(.easeInOut(duration: DEFAULT_ANIMATION_DURATION)))
                }
            }
        )
    }
    
    /// Displays an error message banner when error is present
    /// - Parameter errorMessage: Optional error message to display
    /// - Returns: View with conditional error banner
    /// Requirement: Offline-first architecture - Implements error state handling for offline-first functionality
    func errorBanner(errorMessage: String?) -> some View {
        self.overlay(
            Group {
                if let message = errorMessage {
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                            
                            Text(message)
                                .foregroundColor(.white)
                                .font(.subheadline)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.error)
                        .cornerRadius(8)
                        .padding()
                        
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: DEFAULT_ANIMATION_DURATION))
                }
            },
            alignment: .top
        )
    }
    
    /// Applies a rounded border with specified color and width
    /// - Parameters:
    ///   - color: Border color
    ///   - lineWidth: Border width
    /// - Returns: View with rounded border
    func roundedBorder(color: Color, lineWidth: CGFloat) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color, lineWidth: lineWidth)
        )
    }
}