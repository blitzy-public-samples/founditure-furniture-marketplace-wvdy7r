//
// PointsBadge.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify color assets are properly configured in Assets.xcassets
// 2. Test badge animations with VoiceOver enabled
// 3. Validate badge scaling on different device sizes
// 4. Ensure point type indicators meet accessibility guidelines

import SwiftUI

/// A reusable SwiftUI component that displays user points and achievements in a visually appealing badge format
/// Requirement: Points system and leaderboards - Visual representation of user points and achievements in the gamification system
/// Requirement: Mobile Client Architecture - Reusable UI component for consistent points display across the app
@available(iOS 14.0, *)
struct PointsBadge: View {
    // MARK: - Properties
    
    /// The number of points to display
    private let points: Int
    
    /// The type of points being displayed
    private let type: PointType
    
    /// Flag to enable/disable animation
    private let animate: Bool
    
    /// Scale factor for badge size
    private let scale: Double
    
    // MARK: - Initialization
    
    /// Initializes a new points badge with specified points and type
    /// - Parameters:
    ///   - points: The number of points to display
    ///   - type: The type of points being displayed
    ///   - animate: Flag to enable/disable animation (default: false)
    ///   - scale: Scale factor for badge size (default: 1.0)
    init(points: Int, type: PointType, animate: Bool = false, scale: Double = 1.0) {
        self.points = points
        self.type = type
        self.animate = animate
        self.scale = scale
    }
    
    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // Background circle with theme color
            Circle()
                .fill(backgroundColor)
                .frame(width: 60 * scale, height: 60 * scale)
                .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Points value display
            VStack(spacing: 2) {
                Text("\(points)")
                    .font(.system(size: 20 * scale, weight: .bold))
                    .foregroundColor(.white)
                
                // Point type indicator
                Text(type.rawValue.capitalized)
                    .font(.system(size: 10 * scale, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        // Apply scale animation when enabled
        .scaleEffect(animate ? 1.1 : 1.0)
        .animation(animate ? .spring(response: 0.3, dampingFraction: 0.6) : .none)
        // Apply card and border styling
        .cardStyle()
        .roundedBorder(color: backgroundColor.opacity(0.3), lineWidth: 2)
        // Accessibility
        .accessibilityLabel("\(points) \(type.rawValue) points")
        .accessibilityAddTraits(.isStaticText)
    }
    
    // MARK: - Computed Properties
    
    /// Returns appropriate background color based on point type
    private var backgroundColor: Color {
        switch type {
        case .posting:
            return .primary
        case .recovery:
            return .accent
        case .dailyBonus:
            return .success
        case .referral:
            return .secondary
        case .achievement:
            return .accent
        case .streak:
            return .primary
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct PointsBadge_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Regular badge
            PointsBadge(points: 100, type: .posting)
                .previewLayout(.sizeThatFits)
                .padding()
            
            // Animated badge
            PointsBadge(points: 50, type: .achievement, animate: true)
                .previewLayout(.sizeThatFits)
                .padding()
            
            // Scaled badge
            PointsBadge(points: 25, type: .dailyBonus, scale: 1.5)
                .previewLayout(.sizeThatFits)
                .padding()
            
            // Dark mode preview
            PointsBadge(points: 75, type: .streak)
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.dark)
        }
    }
}
#endif