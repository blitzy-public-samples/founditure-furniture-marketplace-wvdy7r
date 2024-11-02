/*
 * Human Tasks:
 * 1. Ensure Retrofit and Coroutines dependencies are included in app/build.gradle
 * 2. Configure proper base URL for LocationService in the network module
 * 3. Verify location permissions are properly declared in AndroidManifest.xml
 * 4. Configure privacy zone settings in app configuration
 */

package com.founditure.android.data.repository

import com.founditure.android.data.remote.api.LocationService
import com.founditure.android.data.remote.dto.LocationDto
import com.founditure.android.domain.model.Location
import com.founditure.android.domain.model.PrivacyLevel
import com.founditure.android.util.LocationUtils
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository implementation for managing location data in the Founditure Android application.
 * Implements requirements:
 * - Location Services (1.1 System Overview/Core System Components/2. Backend Services)
 * - Location-based Search (1.2 Scope/Included Features)
 * - Privacy Controls (7.2.3 Privacy Controls)
 */
@Singleton
class LocationRepositoryImpl @Inject constructor(
    private val locationService: LocationService,
    private val dispatcher: CoroutineDispatcher
) : LocationRepository {

    /**
     * Updates location information for a furniture item.
     * Implements location services requirement by providing location update capability.
     */
    override fun updateLocation(
        furnitureId: UUID,
        location: Location
    ): Flow<Result<Location>> = flow {
        try {
            // Validate location data
            if (!LocationUtils.isLocationValid(location)) {
                emit(Result.failure(IllegalArgumentException("Invalid location data")))
                return@flow
            }

            // Apply privacy controls before sending to server
            val privacySettings = LocationUtils.PrivacyZoneSettings(
                enabled = true,
                fuzzingRadiusKm = 0.5,
                privacyLevel = location.privacyLevel.name
            )
            val fuzzedLocation = LocationUtils.applyPrivacyZone(location, privacySettings)

            // Convert to DTO and make API call
            val locationDto = LocationDto.fromDomainModel(fuzzedLocation)
            val response = locationService.updateLocation(furnitureId, locationDto)

            if (response.isSuccessful) {
                response.body()?.let { dto ->
                    emit(Result.success(dto.toDomainModel()))
                } ?: emit(Result.failure(IllegalStateException("Empty response body")))
            } else {
                emit(Result.failure(Exception("Failed to update location: ${response.code()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }.flowOn(dispatcher)

    /**
     * Retrieves location information for a furniture item.
     * Implements location services requirement by providing location query capability.
     */
    override fun getLocation(furnitureId: UUID): Flow<Result<Location>> = flow {
        try {
            val response = locationService.getLocation(furnitureId)

            if (response.isSuccessful) {
                response.body()?.let { dto ->
                    val location = dto.toDomainModel()
                    // Apply privacy controls to retrieved location
                    val privacySettings = LocationUtils.PrivacyZoneSettings(
                        enabled = true,
                        fuzzingRadiusKm = 0.5,
                        privacyLevel = location.privacyLevel.name
                    )
                    val fuzzedLocation = LocationUtils.applyPrivacyZone(location, privacySettings)
                    emit(Result.success(fuzzedLocation))
                } ?: emit(Result.failure(IllegalStateException("Empty response body")))
            } else {
                emit(Result.failure(Exception("Failed to get location: ${response.code()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }.flowOn(dispatcher)

    /**
     * Searches for furniture items within specified radius.
     * Implements location-based search requirement by enabling proximity-based queries.
     */
    override fun searchNearby(
        latitude: Double,
        longitude: Double,
        radiusKm: Double
    ): Flow<Result<List<Location>>> = flow {
        try {
            // Validate input parameters
            if (latitude !in -90.0..90.0 || longitude !in -180.0..180.0 || radiusKm <= 0) {
                emit(Result.failure(IllegalArgumentException("Invalid search parameters")))
                return@flow
            }

            val response = locationService.searchNearby(latitude, longitude, radiusKm)

            if (response.isSuccessful) {
                response.body()?.let { dtoList ->
                    val locations = dtoList.map { dto ->
                        val location = dto.toDomainModel()
                        // Apply privacy controls to each location
                        val privacySettings = LocationUtils.PrivacyZoneSettings(
                            enabled = true,
                            fuzzingRadiusKm = 0.5,
                            privacyLevel = location.privacyLevel.name
                        )
                        LocationUtils.applyPrivacyZone(location, privacySettings)
                    }
                    emit(Result.success(locations))
                } ?: emit(Result.failure(IllegalStateException("Empty response body")))
            } else {
                emit(Result.failure(Exception("Failed to search nearby: ${response.code()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }.flowOn(dispatcher)

    /**
     * Updates privacy level for a location.
     * Implements privacy controls requirement by allowing privacy level adjustments.
     */
    override fun updatePrivacyLevel(
        locationId: UUID,
        privacyLevel: PrivacyLevel
    ): Flow<Result<Location>> = flow {
        try {
            val response = locationService.updatePrivacyLevel(
                locationId,
                privacyLevel.name
            )

            if (response.isSuccessful) {
                response.body()?.let { dto ->
                    val location = dto.toDomainModel()
                    // Apply updated privacy settings
                    val privacySettings = LocationUtils.PrivacyZoneSettings(
                        enabled = true,
                        fuzzingRadiusKm = when (privacyLevel) {
                            PrivacyLevel.EXACT -> 0.0
                            PrivacyLevel.APPROXIMATE -> 0.5
                            PrivacyLevel.AREA_ONLY -> 1.0
                            PrivacyLevel.HIDDEN -> 2.0
                        },
                        privacyLevel = privacyLevel.name
                    )
                    val fuzzedLocation = LocationUtils.applyPrivacyZone(location, privacySettings)
                    emit(Result.success(fuzzedLocation))
                } ?: emit(Result.failure(IllegalStateException("Empty response body")))
            } else {
                emit(Result.failure(Exception("Failed to update privacy level: ${response.code()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }.flowOn(dispatcher)
}

/**
 * Interface defining location repository operations.
 * Defines contract for location-related data operations.
 */
interface LocationRepository {
    fun updateLocation(furnitureId: UUID, location: Location): Flow<Result<Location>>
    fun getLocation(furnitureId: UUID): Flow<Result<Location>>
    fun searchNearby(latitude: Double, longitude: Double, radiusKm: Double): Flow<Result<List<Location>>>
    fun updatePrivacyLevel(locationId: UUID, privacyLevel: PrivacyLevel): Flow<Result<Location>>
}