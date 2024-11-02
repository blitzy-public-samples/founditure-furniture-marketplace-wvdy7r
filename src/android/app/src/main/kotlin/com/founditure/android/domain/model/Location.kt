/*
 * Human Tasks:
 * 1. Ensure kotlinx.parcelize plugin is enabled in the app-level build.gradle
 * 2. Verify that the app has the required location permissions in AndroidManifest.xml
 */

import android.os.Parcelable
import kotlinx.parcelize.Parcelize
import java.util.UUID
import kotlin.math.acos
import kotlin.math.cos
import kotlin.math.sin

/**
 * Domain model class representing location information for furniture items.
 * Implements Parcelable for efficient data passing between Android components.
 * 
 * Addresses requirements:
 * - Location Services (1.1 System Overview/Core System Components/2. Backend Services)
 * - Privacy Controls (1.2 Scope/Included Features)
 * - Location-based Search (1.2 Scope/Included Features)
 */
@Parcelize
data class Location(
    val id: UUID,
    val furnitureId: UUID,
    val latitude: Double,
    val longitude: Double,
    val address: String,
    val privacyLevel: PrivacyLevel,
    val recordedAt: Long
) : Parcelable {

    init {
        // Validate latitude range (-90 to 90)
        require(latitude in -90.0..90.0) {
            "Latitude must be between -90 and 90 degrees, got $latitude"
        }
        
        // Validate longitude range (-180 to 180)
        require(longitude in -180.0..180.0) {
            "Longitude must be between -180 and 180 degrees, got $longitude"
        }
    }

    /**
     * Returns privacy-adjusted coordinates based on privacy level setting.
     * Implements privacy controls requirement by fuzzing coordinates based on privacy level.
     */
    fun getDisplayCoordinates(): Pair<Double, Double> {
        return when (privacyLevel) {
            PrivacyLevel.EXACT -> Pair(latitude, longitude)
            PrivacyLevel.APPROXIMATE -> {
                // Round to 2 decimal places (approximately 1.1km accuracy)
                Pair(
                    String.format("%.2f", latitude).toDouble(),
                    String.format("%.2f", longitude).toDouble()
                )
            }
            PrivacyLevel.AREA_ONLY -> {
                // Round to 1 decimal place (approximately 11km accuracy)
                Pair(
                    String.format("%.1f", latitude).toDouble(),
                    String.format("%.1f", longitude).toDouble()
                )
            }
            PrivacyLevel.HIDDEN -> Pair(0.0, 0.0)
        }
    }

    /**
     * Returns privacy-aware address string based on privacy level setting.
     * Implements privacy controls by masking address details according to privacy level.
     */
    fun getDisplayAddress(): String {
        return when (privacyLevel) {
            PrivacyLevel.EXACT -> address
            PrivacyLevel.APPROXIMATE -> {
                // Remove house number and return only street name and area
                address.split(",")
                    .drop(1)
                    .joinToString(",")
                    .trim()
            }
            PrivacyLevel.AREA_ONLY -> {
                // Return only area/city name
                address.split(",")
                    .last()
                    .trim()
            }
            PrivacyLevel.HIDDEN -> "Location hidden"
        }
    }

    /**
     * Calculates the distance to another location in meters using the Haversine formula.
     * Implements location-based search requirement by enabling distance calculations.
     */
    fun distanceTo(other: Location): Double {
        val earthRadius = 6371000.0 // Earth's radius in meters

        val lat1Rad = Math.toRadians(latitude)
        val lat2Rad = Math.toRadians(other.latitude)
        val lon1Rad = Math.toRadians(longitude)
        val lon2Rad = Math.toRadians(other.longitude)

        val sinLat = sin((lat2Rad - lat1Rad) / 2)
        val sinLon = sin((lon2Rad - lon1Rad) / 2)

        val a = sinLat * sinLat +
                cos(lat1Rad) * cos(lat2Rad) * sinLon * sinLon
        val c = 2 * acos(kotlin.math.min(1.0, kotlin.math.sqrt(a)))

        return earthRadius * c
    }
}

/**
 * Enum class defining location privacy levels for the application.
 * Implements privacy controls requirement by providing granular privacy options.
 */
enum class PrivacyLevel {
    EXACT,          // Show exact location
    APPROXIMATE,    // Show approximate area
    AREA_ONLY,      // Show only general area
    HIDDEN          // Hide location completely
}