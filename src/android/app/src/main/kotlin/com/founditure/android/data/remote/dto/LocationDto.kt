/*
 * Human Tasks:
 * 1. Ensure gson dependency is included in app/build.gradle with version 2.9.0
 * 2. Verify that the app has proper internet permissions in AndroidManifest.xml
 */

package com.founditure.android.data.remote.dto

import com.google.gson.annotations.SerializedName // version: 2.9.0
import com.founditure.android.domain.model.Location
import com.founditure.android.domain.model.PrivacyLevel
import java.util.UUID

/**
 * Data Transfer Object for serializing location information in API communications.
 * 
 * Addresses requirements:
 * - Location Services (1.1 System Overview/Core System Components/2. Backend Services)
 * - Privacy Controls (7.2.3 Privacy Controls)
 * - Location-based Search (1.2 Scope/Included Features)
 */
data class LocationDto(
    @SerializedName("id")
    val id: UUID,
    
    @SerializedName("furniture_id")
    val furnitureId: UUID,
    
    @SerializedName("latitude")
    val latitude: Double,
    
    @SerializedName("longitude")
    val longitude: Double,
    
    @SerializedName("address")
    val address: String,
    
    @SerializedName("privacy_level")
    val privacyLevel: String,
    
    @SerializedName("recorded_at")
    val recordedAt: Long
) {
    /**
     * Converts DTO to domain model Location instance.
     * Implements privacy controls by properly mapping privacy levels.
     */
    fun toDomainModel(): Location {
        return Location(
            id = id,
            furnitureId = furnitureId,
            latitude = latitude,
            longitude = longitude,
            address = address,
            privacyLevel = when (privacyLevel.uppercase()) {
                "EXACT" -> PrivacyLevel.EXACT
                "APPROXIMATE" -> PrivacyLevel.APPROXIMATE
                "AREA_ONLY" -> PrivacyLevel.AREA_ONLY
                "HIDDEN" -> PrivacyLevel.HIDDEN
                else -> PrivacyLevel.APPROXIMATE // Default to APPROXIMATE for unknown values
            },
            recordedAt = recordedAt
        )
    }

    companion object {
        /**
         * Creates DTO from domain model Location instance.
         * Implements location services requirement by properly serializing location data.
         */
        fun fromDomainModel(location: Location): LocationDto {
            return LocationDto(
                id = location.id,
                furnitureId = location.furnitureId,
                latitude = location.latitude,
                longitude = location.longitude,
                address = location.address,
                privacyLevel = location.privacyLevel.name,
                recordedAt = location.recordedAt
            )
        }
    }
}