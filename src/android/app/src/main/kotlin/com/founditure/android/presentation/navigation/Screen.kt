// Human Tasks:
// 1. Ensure the navigation graph (NavGraph.kt) is properly configured to use these routes
// 2. Update the app's theme and styles to match the navigation transitions
// 3. Configure deep linking in the Android Manifest to support these routes

package com.founditure.android.presentation.navigation

/**
 * Defines all navigation routes in the Founditure application using sealed class pattern
 * for type-safe navigation.
 * 
 * Requirement: Mobile Client Architecture - Navigation (3.2.1)
 * Implements the navigation structure and route definitions for the mobile client
 * 
 * Requirement: Mobile Applications - Native Android (1.2)
 * Provides native Android navigation route definitions using Kotlin sealed classes
 */
sealed class Screen(val route: String) {
    // Authentication Flow
    object Auth : Screen(AUTH_ROUTE)
    object Login : Screen("$AUTH_ROUTE/login")
    object Register : Screen("$AUTH_ROUTE/register")
    object ForgotPassword : Screen("$AUTH_ROUTE/forgot-password")

    // Main Flow
    object Home : Screen("$MAIN_ROUTE/home")
    object Map : Screen("$MAIN_ROUTE/map")
    object Camera : Screen("$MAIN_ROUTE/camera")
    object Messages : Screen("$MAIN_ROUTE/messages")
    object Profile : Screen("$MAIN_ROUTE/profile")

    // Settings and Achievements
    object Settings : Screen("$MAIN_ROUTE/settings")
    object Achievements : Screen("$MAIN_ROUTE/achievements")

    // Furniture Flow
    object FurnitureList : Screen("$MAIN_ROUTE/furniture/list")
    object FurnitureDetail : Screen("$MAIN_ROUTE/furniture/detail/{furnitureId}") {
        fun createRoute(furnitureId: String) = "$MAIN_ROUTE/furniture/detail/$furnitureId"
    }
    object FurnitureCreate : Screen("$MAIN_ROUTE/furniture/create")

    // Chat Flow
    object ChatList : Screen("$MAIN_ROUTE/chat/list")
    object Chat : Screen("$MAIN_ROUTE/chat/{userId}") {
        fun createRoute(userId: String) = "$MAIN_ROUTE/chat/$userId"
    }

    companion object {
        // Global route constants
        const val AUTH_ROUTE = "auth"
        const val MAIN_ROUTE = "main"
    }
}