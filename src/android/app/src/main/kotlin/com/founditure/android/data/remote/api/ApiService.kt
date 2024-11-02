/*
 * Human Tasks:
 * 1. Add Retrofit dependencies to app/build.gradle:
 *    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
 *    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
 *    implementation 'com.squareup.retrofit2:adapter-rxjava3:2.9.0'
 * 2. Add OkHttp dependencies:
 *    implementation 'com.squareup.okhttp3:okhttp:4.9.0'
 *    implementation 'com.squareup.okhttp3:logging-interceptor:4.9.0'
 * 3. Add RxJava dependencies:
 *    implementation 'io.reactivex.rxjava3:rxjava:3.0.0'
 *    implementation 'io.reactivex.rxjava3:rxandroid:3.0.0'
 * 4. Configure internet permissions in AndroidManifest.xml
 */

package com.founditure.android.data.remote.api

import com.founditure.android.data.remote.dto.UserDto
import com.founditure.android.data.remote.dto.FurnitureDto
import com.founditure.android.data.remote.dto.MessageDto
import io.reactivex.rxjava3.core.Single // version: 3.0.0
import okhttp3.MultipartBody // version: 4.9.0
import retrofit2.http.* // version: 2.9.0

/**
 * Core API service interface defining all network endpoints for the Founditure Android application.
 * 
 * Addresses requirements:
 * - Mobile-first Platform (1.1 System Overview): Native Android API communication layer
 * - RESTful API Gateway (1.1 System Overview/System Architecture): Client-server communication interface
 * - Offline-first Architecture (1.2 Scope/Core System Components/Mobile Applications): Network API interface
 */
interface ApiService {

    /**
     * Authenticates user and returns user data with token.
     * 
     * @param credentials Map containing email and password
     * @return Observable user data response
     */
    @POST("auth/login")
    fun login(
        @Body credentials: Map<String, String>
    ): Single<UserDto>

    /**
     * Registers new user account.
     * 
     * @param userData Map containing registration information
     * @return Observable user data response
     */
    @POST("auth/register")
    fun register(
        @Body userData: Map<String, String>
    ): Single<UserDto>

    /**
     * Retrieves paginated list of furniture items.
     * 
     * @param filters Map containing filter parameters (category, condition, location, etc.)
     * @return Observable list of furniture items
     */
    @GET("furniture")
    fun getFurnitureList(
        @QueryMap filters: Map<String, String>
    ): Single<List<FurnitureDto>>

    /**
     * Retrieves specific furniture item details.
     * 
     * @param id Furniture item identifier
     * @return Observable furniture item data
     */
    @GET("furniture/{id}")
    fun getFurnitureById(
        @Path("id") id: String
    ): Single<FurnitureDto>

    /**
     * Creates new furniture listing.
     * 
     * @param furniture Furniture data transfer object
     * @return Observable created furniture data
     */
    @POST("furniture")
    fun createFurniture(
        @Body furniture: FurnitureDto
    ): Single<FurnitureDto>

    /**
     * Updates existing furniture listing.
     * 
     * @param id Furniture item identifier
     * @param furniture Updated furniture data
     * @return Observable updated furniture data
     */
    @PUT("furniture/{id}")
    fun updateFurniture(
        @Path("id") id: String,
        @Body furniture: FurnitureDto
    ): Single<FurnitureDto>

    /**
     * Retrieves chat messages for a conversation.
     * 
     * @param userId User identifier for the conversation
     * @param furnitureId Furniture item identifier
     * @return Observable list of messages
     */
    @GET("messages")
    fun getMessages(
        @Query("userId") userId: String,
        @Query("furnitureId") furnitureId: String
    ): Single<List<MessageDto>>

    /**
     * Sends a new chat message.
     * 
     * @param message Message data transfer object
     * @return Observable sent message data
     */
    @POST("messages")
    fun sendMessage(
        @Body message: MessageDto
    ): Single<MessageDto>

    /**
     * Uploads furniture or profile image.
     * 
     * @param image Multipart image file
     * @return Observable uploaded image URL
     */
    @Multipart
    @POST("upload")
    fun uploadImage(
        @Part image: MultipartBody.Part
    ): Single<String>
}