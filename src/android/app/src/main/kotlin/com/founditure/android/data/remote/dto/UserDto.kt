/*
 * Human Tasks:
 * 1. Ensure Moshi dependencies are added to app-level build.gradle:
 *    implementation 'com.squareup.moshi:moshi-kotlin:1.14.0'
 *    kapt 'com.squareup.moshi:moshi-kotlin-codegen:1.14.0'
 * 2. Ensure GSON dependencies are added to app-level build.gradle:
 *    implementation 'com.google.code.gson:gson:2.9.0'
 */

package com.founditure.android.data.remote.dto

import com.founditure.android.domain.model.User
import com.google.gson.annotations.SerializedName // version: 2.9.0
import com.squareup.moshi.JsonAdapter // version: 1.14.0
import com.squareup.moshi.JsonClass
import com.squareup.moshi.Moshi

/**
 * Data Transfer Object for user data in API communications.
 * 
 * Addresses requirements:
 * - User management functionality requiring network data transfer (1.1 System Overview/Core System Components/Backend Services)
 * - Data synchronization between local and remote storage (1.2 Scope/Core System Components/Mobile Applications)
 */
@JsonClass(generateAdapter = true)
data class UserDto(
    @SerializedName("id")
    val id: String,
    
    @SerializedName("email")
    val email: String,
    
    @SerializedName("full_name")
    val fullName: String,
    
    @SerializedName("phone_number")
    val phoneNumber: String?,
    
    @SerializedName("points")
    val points: Int,
    
    @SerializedName("profile_image_url")
    val profileImageUrl: String?,
    
    @SerializedName("created_at")
    val createdAt: Long,
    
    @SerializedName("updated_at")
    val updatedAt: Long,
    
    @SerializedName("is_verified")
    val isVerified: Boolean,
    
    @SerializedName("preferences")
    val preferences: Map<String, Any>
) {
    /**
     * Converts the DTO to domain model.
     * Maps all DTO properties to corresponding User model properties.
     */
    fun toDomainModel(): User = User(
        id = id,
        email = email,
        fullName = fullName,
        phoneNumber = phoneNumber,
        points = points,
        profileImageUrl = profileImageUrl,
        createdAt = createdAt,
        updatedAt = updatedAt,
        isVerified = isVerified,
        preferences = preferences
    )

    /**
     * Converts the DTO to JSON string using Moshi adapter.
     */
    fun toJson(): String {
        return moshiAdapter.toJson(this)
    }

    companion object {
        private val moshi = Moshi.Builder().build()
        private val moshiAdapter: JsonAdapter<UserDto> = moshi.adapter(UserDto::class.java)

        /**
         * Creates DTO from domain model.
         * Maps all User model properties to corresponding DTO properties.
         */
        fun fromDomainModel(user: User): UserDto = UserDto(
            id = user.id,
            email = user.email,
            fullName = user.fullName,
            phoneNumber = user.phoneNumber,
            points = user.points,
            profileImageUrl = user.profileImageUrl,
            createdAt = user.createdAt,
            updatedAt = user.updatedAt,
            isVerified = user.isVerified,
            preferences = user.preferences
        )

        /**
         * Creates DTO from JSON string using Moshi adapter.
         */
        fun fromJson(json: String): UserDto {
            return moshiAdapter.fromJson(json)
                ?: throw IllegalArgumentException("Invalid JSON format for UserDto")
        }
    }
}