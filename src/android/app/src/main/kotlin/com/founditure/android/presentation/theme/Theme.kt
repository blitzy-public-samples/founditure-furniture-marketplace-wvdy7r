// androidx.compose.material3:material3:1.1.0
// androidx.compose.runtime:runtime:1.5.0
// androidx.compose.foundation:foundation:1.5.0

package com.founditure.android.presentation.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.foundation.isSystemInDarkTheme

/**
 * HUMAN TASKS:
 * 1. Verify color schemes meet WCAG 2.1 AA accessibility standards for contrast ratios
 * 2. Test theme appearance across different Android versions and device manufacturers
 * 3. Validate dynamic color adaptation on Android 12+ devices
 * 4. Ensure consistent theming across all app screens and components
 */

// Light theme color scheme
// Requirement: Mobile Applications - Native Android application with modern material design implementation
private val LightColorScheme = lightColorScheme(
    primary = Primary,
    secondary = Secondary,
    background = Background,
    surface = Surface,
    error = Error,
    onPrimary = OnPrimary,
    onSecondary = OnSecondary,
    onBackground = OnBackground,
    onSurface = OnSurface,
    onError = OnError
)

// Dark theme color scheme
// Requirement: Mobile Applications - Native Android application with modern material design implementation
private val DarkColorScheme = darkColorScheme(
    primary = PrimaryDark,
    secondary = Secondary,
    background = BackgroundDark,
    surface = SurfaceDark,
    error = Error,
    onPrimary = OnPrimary,
    onSecondary = OnSecondary,
    onBackground = OnBackgroundDark,
    onSurface = OnSurfaceDark,
    onError = OnError
)

/**
 * Founditure theme composable that provides Material Design 3 theming for the application.
 * 
 * Requirements addressed:
 * - Mobile Applications: Native Android application with modern material design implementation
 * - UI Components: Common UI components requiring consistent theming
 *
 * @param darkTheme Whether to use dark theme colors. Defaults to system setting.
 * @param dynamicColor Whether to use dynamic color on Android 12+. Defaults to true.
 * @param content The composable content to be themed.
 */
@Composable
fun FounditureTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    // Select color scheme based on theme mode
    val colorScheme = when {
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    // Apply Material Design 3 theme with selected color scheme and typography
    MaterialTheme(
        colorScheme = colorScheme,
        typography = FounditureTypography,
        content = content
    )
}