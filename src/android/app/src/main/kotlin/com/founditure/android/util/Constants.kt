// BuildConfig version: 8.0.0

/**
 * Human Tasks:
 * 1. Ensure BuildConfig contains the correct environment-specific values for different build variants
 * 2. Verify API endpoints are correctly configured in each environment
 * 3. Configure keystore settings in build.gradle for security constants
 * 4. Set up proper SSL pinning for API endpoints
 * 5. Configure proper location permissions in AndroidManifest.xml
 */

package com.founditure.android.util

import com.founditure.android.BuildConfig

/**
 * Central constants file containing all static configuration values used throughout the Founditure Android application.
 * Addresses requirements from:
 * - Mobile Applications (1.2 Scope/Core System Components/1. Mobile Applications)
 * - System Architecture (3.1 High-Level Architecture Overview)
 * - Security Architecture (3.6 Security Architecture)
 */

/**
 * API-related constants for network communication
 * Implements requirements from System Architecture section 3.1
 */
object API {
    const val BASE_URL = "https://api.founditure.com"
    const val API_VERSION = "v1"
    const val TIMEOUT_CONNECT = 30L // Connection timeout in seconds
    const val TIMEOUT_READ = 30L // Read timeout in seconds
    const val MAX_RETRIES = 3 // Maximum number of API retry attempts
    const val RATE_LIMIT = 100 // Maximum requests per minute
}

/**
 * WebSocket configuration for real-time features
 * Implements requirements from System Architecture section 3.1
 */
object WebSocket {
    const val WS_URL = "wss://ws.founditure.com"
    const val RECONNECT_INTERVAL = 5000L // Reconnection attempt interval in milliseconds
    const val PING_INTERVAL = 30000L // WebSocket ping interval in milliseconds
    const val MAX_RECONNECT_ATTEMPTS = 5 // Maximum reconnection attempts before failure
}

/**
 * Local database configuration
 * Implements requirements from Mobile Applications section 1.2
 */
object Database {
    const val DATABASE_NAME = "founditure_db"
    const val DATABASE_VERSION = 1
    const val MAX_CACHE_SIZE_MB = 100 // Maximum local cache size in megabytes
    const val CACHE_EXPIRY_MS = 86400000L // Cache expiry duration (24 hours in milliseconds)
}

/**
 * Location service configuration
 * Implements requirements from Mobile Applications section 1.2
 */
object Location {
    const val UPDATE_INTERVAL = 10000L // Location update interval in milliseconds
    const val FASTEST_UPDATE_INTERVAL = 5000L // Fastest possible update interval
    const val DEFAULT_ZOOM = 15f // Default map zoom level
    const val DEFAULT_RADIUS_KM = 5.0 // Default search radius in kilometers
    const val LOCATION_PERMISSION_CODE = 1001 // Permission request code for location services
}

/**
 * Security-related constants
 * Implements requirements from Security Architecture section 3.6
 */
object Security {
    const val ENCRYPTION_ALGORITHM = "AES/GCM/NoPadding"
    const val KEY_SIZE = 256 // Encryption key size in bits
    const val KEYSTORE_ALIAS = "founditure_keystore"
    const val TOKEN_EXPIRY = 604800000L // Token expiry duration (7 days in milliseconds)
}

/**
 * Points and gamification system constants
 * Implements requirements from Mobile Applications section 1.2
 */
object Points {
    const val POINTS_FURNITURE_POST = 100 // Points awarded for posting furniture
    const val POINTS_FURNITURE_COLLECTED = 200 // Points awarded for collecting furniture
    const val POINTS_DAILY_LOGIN = 10 // Points awarded for daily login
    const val POINTS_VERIFICATION = 50 // Points awarded for account verification
}

/**
 * UI-related constants
 * Implements requirements from Mobile Applications section 1.2
 */
object UI {
    const val SPLASH_DELAY = 2000L // Splash screen display duration in milliseconds
    const val MAX_IMAGE_SIZE = 1024 // Maximum image dimension in pixels
    const val THUMBNAIL_SIZE = 300 // Thumbnail size in pixels
    const val LIST_PAGE_SIZE = 20 // Number of items per page in lists
}

/**
 * Error codes for standardized error handling
 * Implements requirements from System Architecture section 3.1
 */
enum class ErrorCodes {
    NETWORK_ERROR,
    AUTH_ERROR,
    VALIDATION_ERROR,
    SERVER_ERROR,
    LOCATION_ERROR,
    CAMERA_ERROR
}

/**
 * Content types for different data entities
 * Implements requirements from System Architecture section 3.1
 */
enum class ContentType {
    FURNITURE,
    MESSAGE,
    PROFILE,
    NOTIFICATION
}