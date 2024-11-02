// HUMAN TASKS:
// 1. Configure edge-to-edge display in themes.xml
// 2. Add necessary permissions in AndroidManifest.xml
// 3. Verify Hilt dependencies in build.gradle
// 4. Test deep linking configuration
// 5. Validate navigation animations

// androidx.activity:activity-compose:1.7.0
// androidx.compose.material3:material3:1.1.0
// androidx.navigation.compose:2.7.0
// com.google.dagger:hilt-android:2.48

package com.founditure.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.core.view.WindowCompat
import androidx.navigation.compose.rememberNavController
import com.founditure.android.presentation.navigation.FounditureNavGraph
import com.founditure.android.presentation.theme.FounditureTheme
import dagger.hilt.android.AndroidEntryPoint

/**
 * Main activity class that serves as the entry point for the Founditure Android application.
 * 
 * Requirements addressed:
 * - Mobile Applications (1.2): Native Android application with offline-first architecture
 * - Mobile Client Architecture (3.2.1): Implements core UI and navigation structure
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Configure edge-to-edge display
        WindowCompat.setDecorFitsSystemWindows(window, false)

        setContent {
            // Initialize the navigation controller
            val navController = rememberNavController()

            FounditureTheme {
                // Main surface container using Material3 background color
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    // Set up the main navigation graph
                    FounditureNavGraph(
                        navController = navController,
                        startDestination = savedInstanceState == null
                    )
                }
            }
        }
    }

    /**
     * Handles system back button press with proper navigation handling.
     * Allows the navigation component to handle back press when possible,
     * otherwise delegates to the system default behavior.
     */
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Get the current navigation controller fragment
        val navHostFragment = supportFragmentManager.findFragmentById(android.R.id.content)
        val currentFragment = navHostFragment?.childFragmentManager?.fragments?.get(0)

        // Check if the current fragment can handle back press
        if (currentFragment?.childFragmentManager?.backStackEntryCount ?: 0 > 0) {
            currentFragment?.childFragmentManager?.popBackStack()
        } else {
            @Suppress("DEPRECATION")
            super.onBackPressed()
        }
    }
}