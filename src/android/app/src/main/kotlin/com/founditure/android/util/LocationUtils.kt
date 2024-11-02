/*
 * Human Tasks:
 * 1. Ensure Google Play Services Location dependency is added to build.gradle
 * 2. Verify location permissions are properly declared in AndroidManifest.xml
 * 3. Configure privacy zone settings in app configuration
 */

package com.founditure.android.util

import android.location.Location as AndroidLocation
import com.founditure.android.domain.model.Location
import com.google.android.gms.location.LocationServices
import kotlin.math.*
import java.util.*

/**
 * Utility class providing location-related helper functions.
 * Implements requirements:
 * - Location Services (1.2 Scope/Core System Components/2. Backend Services/Location services)
 * - Privacy Controls (7.2.3 Privacy Controls)
 */
object LocationUtils {

    // Global constants
    const val DEFAULT_SEARCH_RADIUS_KM = 5.0
    const val MAX_LOCATION_AGE_MS = 300000L // 5 minutes
    const val EARTH_RADIUS_KM = 6371.0
    const val MAX_PRIVACY_ZONE_RADIUS_KM = 1.0

    /**
     * Data class representing a geographical bounding box for location queries
     */
    data class LocationBounds(
        val minLatitude: Double,
        val maxLatitude: Double,
        val minLongitude: Double,
        val maxLongitude: Double
    ) {
        init {
            require(minLatitude >= -90.0 && maxLatitude <= 90.0) {
                "Latitude values must be between -90 and 90 degrees"
            }
            require(minLongitude >= -180.0 && maxLongitude <= 180.0) {
                "Longitude values must be between -180 and 180 degrees"
            }
            require(minLatitude <= maxLatitude) {
                "minLatitude must be less than or equal to maxLatitude"
            }
            require(minLongitude <= maxLongitude) {
                "minLongitude must be less than or equal to maxLongitude"
            }
        }
    }

    /**
     * Data class containing privacy zone configuration for location fuzzing
     */
    data class PrivacyZoneSettings(
        val enabled: Boolean = true,
        val fuzzingRadiusKm: Double = 0.5,
        val privacyLevel: String = "APPROXIMATE"
    ) {
        init {
            require(fuzzingRadiusKm in 0.0..MAX_PRIVACY_ZONE_RADIUS_KM) {
                "Fuzzing radius must be between 0 and $MAX_PRIVACY_ZONE_RADIUS_KM km"
            }
            require(privacyLevel in listOf("EXACT", "APPROXIMATE", "AREA_ONLY", "HIDDEN")) {
                "Invalid privacy level: $privacyLevel"
            }
        }
    }

    /**
     * Calculates the distance between two locations using the Haversine formula
     */
    fun calculateDistance(location1: Location, location2: Location): Double {
        val lat1 = Math.toRadians(location1.latitude)
        val lon1 = Math.toRadians(location1.longitude)
        val lat2 = Math.toRadians(location2.latitude)
        val lon2 = Math.toRadians(location2.longitude)

        val dLat = lat2 - lat1
        val dLon = lon2 - lon1

        val a = sin(dLat / 2).pow(2) + cos(lat1) * cos(lat2) * sin(dLon / 2).pow(2)
        val c = 2 * asin(sqrt(a))

        return EARTH_RADIUS_KM * c
    }

    /**
     * Creates a bounding box around a center point with given radius
     */
    fun createBoundingBox(center: Location, radiusKm: Double): LocationBounds {
        val latRadian = Math.toRadians(center.latitude)
        
        // Calculate lat/lon offsets
        val latOffset = (radiusKm / EARTH_RADIUS_KM) * (180.0 / Math.PI)
        val lonOffset = (radiusKm / EARTH_RADIUS_KM) * (180.0 / Math.PI) / cos(latRadian)

        return LocationBounds(
            minLatitude = (center.latitude - latOffset).coerceIn(-90.0, 90.0),
            maxLatitude = (center.latitude + latOffset).coerceIn(-90.0, 90.0),
            minLongitude = (center.longitude - lonOffset).coerceIn(-180.0, 180.0),
            maxLongitude = (center.longitude + lonOffset).coerceIn(-180.0, 180.0)
        )
    }

    /**
     * Applies privacy zone fuzzing to a location based on privacy settings
     */
    fun applyPrivacyZone(location: Location, settings: PrivacyZoneSettings): Location {
        if (!settings.enabled) return location

        // Generate random offset within fuzzing radius
        val randomAngle = Random().nextDouble() * 2 * Math.PI
        val randomDistance = Random().nextDouble() * settings.fuzzingRadiusKm

        val latOffset = (randomDistance / EARTH_RADIUS_KM) * 
            (180.0 / Math.PI) * cos(randomAngle)
        val lonOffset = (randomDistance / EARTH_RADIUS_KM) * 
            (180.0 / Math.PI) * sin(randomAngle) / 
            cos(Math.toRadians(location.latitude))

        return Location(
            id = location.id,
            furnitureId = location.furnitureId,
            latitude = (location.latitude + latOffset).coerceIn(-90.0, 90.0),
            longitude = (location.longitude + lonOffset).coerceIn(-180.0, 180.0),
            address = location.address,
            privacyLevel = Location.PrivacyLevel.valueOf(settings.privacyLevel),
            recordedAt = location.recordedAt
        )
    }

    /**
     * Validates if a location is within acceptable bounds and recent enough
     */
    fun isLocationValid(location: Location): Boolean {
        return location.latitude in -90.0..90.0 &&
               location.longitude in -180.0..180.0 &&
               (System.currentTimeMillis() - location.recordedAt) <= MAX_LOCATION_AGE_MS
    }
}