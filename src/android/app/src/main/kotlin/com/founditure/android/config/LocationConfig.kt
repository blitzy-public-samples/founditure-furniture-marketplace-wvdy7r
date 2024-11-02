/*
 * Human Tasks:
 * 1. Add com.google.android.gms:play-services-location:21.0.1 to app/build.gradle
 * 2. Configure location permissions in AndroidManifest.xml:
 *    - android.permission.ACCESS_FINE_LOCATION
 *    - android.permission.ACCESS_COARSE_LOCATION
 * 3. Configure default privacy zones in app configuration
 */

package com.founditure.android.config

import android.location.LocationRequest
import com.google.android.gms.location.Priority
import com.founditure.android.util.LocationUtils.PrivacyZoneSettings

/**
 * Configuration object for location services in the Founditure Android application.
 * Implements requirements:
 * - Location Services (1.2 Scope/Core System Components/2. Backend Services/Location services)
 * - Privacy Controls (7.2.3 Privacy Controls)
 * - Security Architecture (3.6 Security Architecture)
 */
object LocationConfig {
    // Update intervals for location services
    const val UPDATE_INTERVAL_MS: Long = 60000 // 60 seconds
    const val FASTEST_UPDATE_INTERVAL_MS: Long = 30000 // 30 seconds
    const val MIN_DISPLACEMENT_METERS: Float = 100f // 100 meters
    const val LOCATION_PERMISSION_REQUEST_CODE: Int = 1001

    /**
     * Enum class defining location accuracy levels
     * Implements requirement: Location Services
     */
    enum class LocationAccuracy {
        HIGH,
        BALANCED,
        LOW_POWER
    }

    /**
     * Enum class defining privacy levels for location data
     * Implements requirements: Privacy Controls, Security Architecture
     */
    enum class PrivacyLevel {
        EXACT,      // Precise location
        APPROXIMATE, // Location with some fuzzing
        AREA_ONLY   // Only general area shown
    }

    /**
     * Creates a LocationRequest object with appropriate settings based on accuracy level
     * Implements requirement: Location Services
     */
    fun getLocationRequest(accuracy: LocationAccuracy): LocationRequest {
        return LocationRequest.create().apply {
            interval = UPDATE_INTERVAL_MS
            fastestInterval = FASTEST_UPDATE_INTERVAL_MS
            smallestDisplacement = MIN_DISPLACEMENT_METERS

            priority = when (accuracy) {
                LocationAccuracy.HIGH -> Priority.PRIORITY_HIGH_ACCURACY
                LocationAccuracy.BALANCED -> Priority.PRIORITY_BALANCED_POWER_ACCURACY
                LocationAccuracy.LOW_POWER -> Priority.PRIORITY_LOW_POWER
            }
        }
    }

    /**
     * Returns privacy zone settings based on environment and privacy level
     * Implements requirements: Privacy Controls, Security Architecture
     */
    fun getPrivacySettings(privacyLevel: PrivacyLevel): PrivacyZoneSettings {
        val currentEnvironment = AppConfig.getCurrentEnvironment()
        
        // Determine fuzzing radius based on privacy level and environment
        val fuzzingRadius = when (privacyLevel) {
            PrivacyLevel.EXACT -> 0.0
            PrivacyLevel.APPROXIMATE -> when (currentEnvironment) {
                Environment.PRODUCTION -> 0.5 // 500m in production
                Environment.STAGING -> 0.3    // 300m in staging
                Environment.DEVELOPMENT -> 0.1 // 100m in development
            }
            PrivacyLevel.AREA_ONLY -> when (currentEnvironment) {
                Environment.PRODUCTION -> 1.0  // 1km in production
                Environment.STAGING -> 0.8     // 800m in staging
                Environment.DEVELOPMENT -> 0.5  // 500m in development
            }
        }

        return PrivacyZoneSettings(
            enabled = privacyLevel != PrivacyLevel.EXACT,
            fuzzingRadiusKm = fuzzingRadius,
            privacyLevel = privacyLevel.name
        )
    }
}