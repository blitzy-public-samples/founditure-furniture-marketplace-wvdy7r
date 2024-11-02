package com.founditure.android.presentation.theme

import androidx.compose.ui.graphics.Color // v1.5.0

/**
 * HUMAN TASKS:
 * 1. Ensure these colors are consistent with the design system documentation
 * 2. Verify color contrast ratios meet WCAG 2.1 AA accessibility standards
 * 3. Test colors in both light and dark themes across different device displays
 */

// Primary brand colors
// Requirement: Mobile Applications - Native Android application with modern material design implementation
val Primary = Color(0xFF4A90E2)  // Main brand color for light theme
val PrimaryDark = Color(0xFF2D5A8E)  // Main brand color for dark theme

// Secondary accent color
// Requirement: UI Components - Common UI components requiring consistent theming
val Secondary = Color(0xFF34C759)  // Accent color for both themes

// Background colors
// Requirement: UI Components - Common UI components requiring consistent theming
val Background = Color(0xFFF5F5F5)  // Light theme background
val BackgroundDark = Color(0xFF121212)  // Dark theme background

// Surface colors
// Requirement: UI Components - Common UI components requiring consistent theming
val Surface = Color(0xFFFFFFFF)  // Light theme surface
val SurfaceDark = Color(0xFF1E1E1E)  // Dark theme surface

// Error state color
// Requirement: UI Components - Common UI components requiring consistent theming
val Error = Color(0xFFFF3B30)  // Error color for both themes

// On-colors for contrast
// Requirement: UI Components - Common UI components requiring consistent theming
val OnPrimary = Color(0xFFFFFFFF)  // Text/icons on primary color
val OnSecondary = Color(0xFF000000)  // Text/icons on secondary color
val OnBackground = Color(0xFF000000)  // Text/icons on light background
val OnBackgroundDark = Color(0xFFFFFFFF)  // Text/icons on dark background
val OnSurface = Color(0xFF000000)  // Text/icons on light surface
val OnSurfaceDark = Color(0xFFFFFFFF)  // Text/icons on dark surface
val OnError = Color(0xFFFFFFFF)  // Text/icons on error color