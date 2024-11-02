package com.founditure.android.data.remote.api

import com.founditure.android.data.remote.dto.FurnitureDto
import io.reactivex.rxjava3.core.Completable
import io.reactivex.rxjava3.core.Single
import okhttp3.MultipartBody
import retrofit2.http.*

/**
 * Retrofit service interface for furniture-related API endpoints.
 * 
 * Implements requirements:
 * - Furniture Listing Management (1.2 Scope/Core System Components/2. Backend Services)
 * - AI/ML Infrastructure (1.2 Scope/Core System Components/3. AI/ML Infrastructure)
 * - Location Services (1.2 Scope/Core System Components/2. Backend Services)
 */
interface FurnitureService {

    /**
     * Retrieves paginated list of furniture items with optional filters.
     * Implements requirement: Furniture Listing Management - Core furniture listing functionality
     * 
     * @param filters Map of filter parameters (e.g., category, condition, material)
     * @param page Page number for pagination
     * @param limit Number of items per page
     * @return Observable list of furniture items
     */
    @GET("api/v1/furniture")
    fun getFurnitureList(
        @QueryMap filters: Map<String, String>,
        @Query("page") page: Int,
        @Query("limit") limit: Int
    ): Single<List<FurnitureDto>>

    /**
     * Retrieves details of a specific furniture item.
     * Implements requirement: Furniture Listing Management - Core furniture listing functionality
     * 
     * @param id Unique identifier of the furniture item
     * @return Observable furniture item data
     */
    @GET("api/v1/furniture/{id}")
    fun getFurnitureById(
        @Path("id") id: String
    ): Single<FurnitureDto>

    /**
     * Creates a new furniture listing.
     * Implements requirement: Furniture Listing Management - Core furniture listing functionality
     * 
     * @param furniture Furniture data transfer object containing listing details
     * @return Observable created furniture data
     */
    @POST("api/v1/furniture")
    fun createFurniture(
        @Body furniture: FurnitureDto
    ): Single<FurnitureDto>

    /**
     * Updates an existing furniture listing.
     * Implements requirement: Furniture Listing Management - Core furniture listing functionality
     * 
     * @param id Unique identifier of the furniture item
     * @param furniture Updated furniture data
     * @return Observable updated furniture data
     */
    @PUT("api/v1/furniture/{id}")
    fun updateFurniture(
        @Path("id") id: String,
        @Body furniture: FurnitureDto
    ): Single<FurnitureDto>

    /**
     * Deletes a furniture listing.
     * Implements requirement: Furniture Listing Management - Core furniture listing functionality
     * 
     * @param id Unique identifier of the furniture item to delete
     * @return Completion status
     */
    @DELETE("api/v1/furniture/{id}")
    fun deleteFurniture(
        @Path("id") id: String
    ): Completable

    /**
     * Uploads an image for a furniture listing.
     * Implements requirements:
     * - Furniture Listing Management - Core furniture listing functionality
     * - AI/ML Infrastructure - Support for furniture image processing
     * 
     * @param id Unique identifier of the furniture item
     * @param image Multipart image file
     * @return Observable uploaded image URL
     */
    @Multipart
    @POST("api/v1/furniture/{id}/image")
    fun uploadFurnitureImage(
        @Path("id") id: String,
        @Part image: MultipartBody.Part
    ): Single<String>

    /**
     * Searches for furniture items within a geographic radius.
     * Implements requirements:
     * - Furniture Listing Management - Core furniture listing functionality
     * - Location Services - Location-based furniture search and filtering
     * 
     * @param latitude Geographic latitude
     * @param longitude Geographic longitude
     * @param radius Search radius in kilometers
     * @param filters Additional filter parameters
     * @return Observable list of nearby furniture items
     */
    @GET("api/v1/furniture/search")
    fun searchFurnitureByLocation(
        @Query("latitude") latitude: Double,
        @Query("longitude") longitude: Double,
        @Query("radius") radius: Double,
        @QueryMap filters: Map<String, String>
    ): Single<List<FurnitureDto>>
}