/**
 * Human Tasks:
 * 1. Ensure BuildConfig.BUILD_TYPE is properly configured in build.gradle for each environment
 * 2. Configure proper Settings.Secure permissions in AndroidManifest.xml
 * 3. Verify environment-specific API endpoints in Constants.kt
 * 4. Set up proper security configurations for each environment
 * 5. Configure logging levels in build.gradle for different build variants
 */

package com.founditure.android.config

import android.provider.Settings
import com.founditure.android.BuildConfig
import com.founditure.android.util.API
import com.founditure.android.util.Database
import com.founditure.android.util.Security

/**
 * Primary configuration object for the Founditure Android application.
 * Implements requirements from:
 * - Mobile Applications (1.2 Scope/Core System Components/1. Mobile Applications)
 * - System Architecture (3.1 High-Level Architecture Overview)
 * - Security Architecture (3.6 Security Architecture)
 */

/**
 * Environment enumeration for different deployment environments
 * Implements requirements from System Architecture section 3.1
 */
enum class Environment {
    DEVELOPMENT,
    STAGING,
    PRODUCTION
}

/**
 * Log level enumeration for application logging
 * Implements requirements from System Architecture section 3.1
 */
enum class LogLevel {
    DEBUG,
    INFO,
    WARNING,
    ERROR
}

/**
 * Singleton object containing global application configuration
 * Implements requirements from Mobile Applications section 1.2 and Security Architecture section 3.6
 */
object AppConfig {
    // Build configuration properties
    val isProduction: Boolean = BuildConfig.BUILD_TYPE == "release"
    val isDebugMode: Boolean = BuildConfig.DEBUG
    val appVersion: String = BuildConfig.VERSION_NAME
    val appVersionCode: Int = BuildConfig.VERSION_CODE
    val deviceId: String = Settings.Secure.ANDROID_ID

    /**
     * Determines the current application environment based on build configuration
     * Implements requirements from System Architecture section 3.1
     */
    fun getCurrentEnvironment(): Environment {
        return when {
            isProduction -> Environment.PRODUCTION
            BuildConfig.BUILD_TYPE == "staging" -> Environment.STAGING
            else -> Environment.DEVELOPMENT
        }
    }

    /**
     * Returns the appropriate log level based on the current environment
     * Implements requirements from System Architecture section 3.1
     */
    fun getLogLevel(): LogLevel {
        return when (getCurrentEnvironment()) {
            Environment.DEVELOPMENT -> LogLevel.DEBUG
            Environment.STAGING -> LogLevel.INFO
            Environment.PRODUCTION -> LogLevel.WARNING
        }
    }

    /**
     * Checks if a specific feature flag is enabled for the current environment
     * Implements requirements from System Architecture section 3.1
     */
    fun isFeatureEnabled(featureKey: String): Boolean {
        // Feature flags configuration based on environment
        val featureFlags = mapOf(
            "offline_mode" to true,
            "real_time_chat" to (getCurrentEnvironment() != Environment.DEVELOPMENT),
            "ai_recognition" to (getCurrentEnvironment() != Environment.DEVELOPMENT),
            "location_fuzzing" to isProduction,
            "advanced_analytics" to isProduction
        )

        return featureFlags[featureKey] ?: false
    }

    /**
     * Get API configuration based on current environment
     * Implements requirements from System Architecture section 3.1
     */
    fun getApiConfig(): Map<String, String> {
        return mapOf(
            "baseUrl" to API.BASE_URL,
            "version" to API.API_VERSION,
            "timeout" to "${API.TIMEOUT_CONNECT}",
            "maxRetries" to "${API.MAX_RETRIES}"
        )
    }

    /**
     * Get database configuration based on current environment
     * Implements requirements from Mobile Applications section 1.2
     */
    fun getDatabaseConfig(): Map<String, Any> {
        return mapOf(
            "name" to Database.DATABASE_NAME,
            "version" to Database.DATABASE_VERSION,
            "maxCacheSize" to Database.MAX_CACHE_SIZE_MB,
            "cacheExpiry" to Database.CACHE_EXPIRY_MS
        )
    }

    /**
     * Get security configuration based on current environment
     * Implements requirements from Security Architecture section 3.6
     */
    fun getSecurityConfig(): Map<String, Any> {
        return mapOf(
            "algorithm" to Security.ENCRYPTION_ALGORITHM,
            "keySize" to Security.KEY_SIZE,
            "keystoreAlias" to Security.KEYSTORE_ALIAS,
            "tokenExpiry" to Security.TOKEN_EXPIRY
        )
    }
}