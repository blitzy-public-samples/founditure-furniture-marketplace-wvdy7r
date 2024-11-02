// Human Tasks:
// 1. Configure deep linking in AndroidManifest.xml for the defined routes
// 2. Set up custom navigation animations in themes.xml
// 3. Verify Hilt dependencies are properly configured in build.gradle
// 4. Ensure all composable screens referenced in the navigation are implemented

package com.founditure.android.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.navigation
import androidx.navigation.navArgument
import com.founditure.android.presentation.auth.AuthViewModel
import com.founditure.android.presentation.auth.AuthViewModel.AuthState

/**
 * Main composable function that sets up the navigation graph for the entire application.
 * 
 * Requirement: Mobile Client Architecture - Navigation (3.2.1)
 * Implements the core navigation structure for the Android mobile client
 * 
 * Requirement: Mobile-first platform (1.1)
 * Provides native Android navigation implementation
 * 
 * Requirement: Offline-first architecture (1.2)
 * Handles navigation with offline support and state preservation
 */
@Composable
fun FounditureNavGraph(
    navController: NavHostController,
    startDestination: Boolean = false
) {
    val authViewModel: AuthViewModel = hiltViewModel()
    val authState by authViewModel.authState.collectAsState()

    NavHost(
        navController = navController,
        startDestination = when {
            startDestination -> Screen.Home.route
            else -> Screen.Auth.route
        }
    ) {
        // Authentication Navigation Graph
        authNavGraph(navController)

        // Main Application Navigation Graph
        mainNavGraph(navController)
    }
}

/**
 * Defines the authentication flow navigation.
 * Handles login, registration, and password recovery routes.
 */
private fun NavGraphBuilder.authNavGraph(navController: NavHostController) {
    navigation(
        startDestination = Screen.Login.route,
        route = Screen.Auth.route
    ) {
        composable(route = Screen.Login.route) {
            // Login screen composable
        }

        composable(route = Screen.Register.route) {
            // Registration screen composable
        }

        composable(route = Screen.ForgotPassword.route) {
            // Forgot password screen composable
        }
    }
}

/**
 * Defines the main application navigation flow.
 * Includes home, map, camera, messages, profile, and furniture-related routes.
 */
private fun NavGraphBuilder.mainNavGraph(navController: NavHostController) {
    navigation(
        startDestination = Screen.Home.route,
        route = Screen.MAIN_ROUTE
    ) {
        // Main tab navigation screens
        composable(route = Screen.Home.route) {
            // Home screen composable
        }

        composable(route = Screen.Map.route) {
            // Map screen composable
        }

        composable(route = Screen.Camera.route) {
            // Camera screen composable
        }

        composable(route = Screen.Messages.route) {
            // Messages screen composable
        }

        composable(route = Screen.Profile.route) {
            // Profile screen composable
        }

        // Settings and Achievements
        composable(route = Screen.Settings.route) {
            // Settings screen composable
        }

        composable(route = Screen.Achievements.route) {
            // Achievements screen composable
        }

        // Furniture flow
        composable(route = Screen.FurnitureList.route) {
            // Furniture list screen composable
        }

        composable(
            route = Screen.FurnitureDetail.route,
            arguments = listOf(
                navArgument("furnitureId") {
                    type = NavType.StringType
                }
            )
        ) {
            // Furniture detail screen composable
            val furnitureId = it.arguments?.getString("furnitureId")
            // Handle furniture detail view
        }

        composable(route = Screen.FurnitureCreate.route) {
            // Furniture creation screen composable
        }

        // Chat flow
        composable(route = Screen.ChatList.route) {
            // Chat list screen composable
        }

        composable(
            route = Screen.Chat.route,
            arguments = listOf(
                navArgument("userId") {
                    type = NavType.StringType
                }
            )
        ) {
            // Chat screen composable
            val userId = it.arguments?.getString("userId")
            // Handle chat view
        }
    }
}

/**
 * Extension function to handle navigation with proper back stack management
 */
fun NavHostController.navigateWithPopUp(route: String, popUpTo: String) {
    this.navigate(route) {
        popUpTo(popUpTo) {
            inclusive = true
        }
    }
}

/**
 * Extension function to handle nested navigation
 */
fun NavHostController.navigateNested(route: String) {
    this.navigate(route) {
        launchSingleTop = true
        restoreState = true
    }
}