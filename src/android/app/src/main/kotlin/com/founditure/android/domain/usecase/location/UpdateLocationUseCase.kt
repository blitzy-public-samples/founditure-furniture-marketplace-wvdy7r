/*
 * Human Tasks:
 * 1. Ensure location permissions are properly declared in AndroidManifest.xml
 * 2. Configure privacy zone settings in app configuration
 * 3. Verify Hilt dependency injection setup in the app module
 */

package com.founditure.android.domain.usecase.location

import com.founditure.android.data.repository.LocationRepository
import com.founditure.android.domain.model.Location
import com.founditure.android.util.LocationUtils
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.UUID
import javax.inject.Inject

/**
 * Use case implementation for updating location information of furniture items with privacy controls.
 * Implements requirements:
 * - Location Services (1.1 System Overview/Core System Components/2. Backend Services)
 * - Privacy Controls (7.2.3 Privacy Controls)
 */
class UpdateLocationUseCase @Inject constructor(
    private val locationRepository: LocationRepository
) {
    /**
     * Updates location information for a furniture item with validation and privacy controls.
     * 
     * @param furnitureId Unique identifier of the furniture item
     * @param location New location information to be updated
     * @return Flow emitting Result containing the updated location if successful, or error if failed
     */
    operator fun invoke(
        furnitureId: UUID,
        location: Location
    ): Flow<Result<Location>> {
        // Validate location data using LocationUtils
        if (!LocationUtils.isLocationValid(location)) {
            return kotlinx.coroutines.flow.flow {
                emit(Result.failure(IllegalArgumentException("Invalid location data: Location is invalid or too old")))
            }
        }

        // Create privacy settings based on location's privacy level
        val privacySettings = LocationUtils.PrivacyZoneSettings(
            enabled = true,
            fuzzingRadiusKm = when (location.privacyLevel) {
                Location.PrivacyLevel.EXACT -> 0.0
                Location.PrivacyLevel.APPROXIMATE -> 0.5
                Location.PrivacyLevel.AREA_ONLY -> 1.0
                Location.PrivacyLevel.HIDDEN -> LocationUtils.MAX_PRIVACY_ZONE_RADIUS_KM
            },
            privacyLevel = location.privacyLevel.name
        )

        // Apply privacy zone fuzzing before updating
        val fuzzedLocation = LocationUtils.applyPrivacyZone(location, privacySettings)

        // Forward valid location update to repository with privacy controls applied
        return locationRepository.updateLocation(furnitureId, fuzzedLocation)
            .map { result ->
                result.fold(
                    onSuccess = { updatedLocation ->
                        // Apply privacy controls to the returned location
                        val privacyAdjustedLocation = LocationUtils.applyPrivacyZone(
                            updatedLocation,
                            privacySettings
                        )
                        Result.success(privacyAdjustedLocation)
                    },
                    onFailure = { error ->
                        Result.failure(error)
                    }
                )
            }
    }
}