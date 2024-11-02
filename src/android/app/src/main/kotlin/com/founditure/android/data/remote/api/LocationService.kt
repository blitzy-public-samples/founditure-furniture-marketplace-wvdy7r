/*
 * Human Tasks:
 * 1. Ensure retrofit2 dependency is included in app/build.gradle with version 2.9.0
 * 2. Verify that the app has proper internet permissions in AndroidManifest.xml
 * 3. Configure proper base URL in the Retrofit client configuration
 */

package com.founditure.android.data.remote.api

import com.founditure.android.data.remote.dto.LocationDto
import retrofit2.Response // version: 2.9.0
import retrofit2.http.* // version: 2.9.0
import java.util.UUID

/**
 * Retrofit service interface for handling location-related API endpoints.
 * 
 * Addresses requirements:
 * - Location Services (1.1 System Overview/Core System Components/2. Backend Services)
 * - Location-based Search (1.2 Scope/Included Features)
 * - Privacy Controls (7.2.3 Privacy Controls)
 */
interface LocationService {

    /**
     * Updates the location information for a furniture item.
     * Implements location services requirement by providing location update capability.
     *
     * @param furnitureId Unique identifier of the furniture item
     * @param location Updated location information
     * @return Response containing the updated location data
     */
    @PUT("furniture/{furnitureId}/location")
    suspend fun updateLocation(
        @Path("furnitureId") furnitureId: UUID,
        @Body location: LocationDto
    ): Response<LocationDto>

    /**
     * Retrieves location information for a specific furniture item.
     * Implements location services requirement by providing location query capability.
     *
     * @param furnitureId Unique identifier of the furniture item
     * @return Response containing the location information
     */
    @GET("furniture/{furnitureId}/location")
    suspend fun getLocation(
        @Path("furnitureId") furnitureId: UUID
    ): Response<LocationDto>

    /**
     * Searches for furniture items within a specified radius of given coordinates.
     * Implements location-based search requirement by enabling proximity-based queries.
     *
     * @param latitude Center point latitude
     * @param longitude Center point longitude
     * @param radiusKm Search radius in kilometers
     * @return Response containing list of nearby furniture locations
     */
    @GET("locations/search")
    suspend fun searchNearby(
        @Query("latitude") latitude: Double,
        @Query("longitude") longitude: Double,
        @Query("radius_km") radiusKm: Double
    ): Response<List<LocationDto>>

    /**
     * Updates the privacy level for a specific location.
     * Implements privacy controls requirement by allowing privacy level adjustments.
     *
     * @param locationId Unique identifier of the location
     * @param privacyLevel New privacy level setting
     * @return Response containing the updated location with new privacy settings
     */
    @PATCH("locations/{locationId}/privacy")
    suspend fun updatePrivacyLevel(
        @Path("locationId") locationId: UUID,
        @Query("privacy_level") privacyLevel: String
    ): Response<LocationDto>
}