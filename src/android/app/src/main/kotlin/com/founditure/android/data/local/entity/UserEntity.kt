/*
 * Human Tasks:
 * 1. Ensure Room dependencies are added to app/build.gradle:
 *    implementation "androidx.room:room-runtime:2.5.0"
 *    kapt "androidx.room:room-compiler:2.5.0"
 * 2. Add Moshi or Gson dependency for JSON serialization:
 *    implementation "com.squareup.moshi:moshi-kotlin:1.14.0"
 */

package com.founditure.android.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.TypeConverters
import com.founditure.android.domain.model.User

/**
 * Room database entity representing a user in local storage.
 * 
 * Addresses requirements:
 * - Local Data Persistence (1.2 Scope/Core System Components/Mobile Applications)
 * - Data Management (1.2 Scope/Core System Components/Data Management)
 */
@Entity(tableName = "users")
@TypeConverters(PreferencesConverter::class)
data class UserEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,

    @ColumnInfo(name = "email")
    val email: String,

    @ColumnInfo(name = "full_name")
    val fullName: String,

    @ColumnInfo(name = "phone_number")
    val phoneNumber: String?,

    @ColumnInfo(name = "points")
    val points: Int,

    @ColumnInfo(name = "profile_image_url")
    val profileImageUrl: String?,

    @ColumnInfo(name = "created_at")
    val createdAt: Long,

    @ColumnInfo(name = "updated_at")
    val updatedAt: Long,

    @ColumnInfo(name = "is_verified")
    val isVerified: Boolean,

    @ColumnInfo(name = "preferences")
    val preferences: Map<String, Any>
) {
    /**
     * Converts the entity to domain model.
     * Implements mapping from local database representation to domain model.
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

    companion object {
        /**
         * Creates a UserEntity from a domain User model.
         * Facilitates conversion from domain model to database entity.
         */
        fun fromDomainModel(user: User) = UserEntity(
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
    }
}

/**
 * Room type converter for Map<String, Any> preferences.
 * Handles conversion between complex Map type and String for database storage.
 */
class PreferencesConverter {
    private val moshi = com.squareup.moshi.Moshi.Builder().build()
    private val mapAdapter = moshi.adapter<Map<String, Any>>(
        Types.newParameterizedType(Map::class.java, String::class.java, Any::class.java)
    )

    @androidx.room.TypeConverter
    fun fromMap(preferences: Map<String, Any>): String {
        return mapAdapter.toJson(preferences)
    }

    @androidx.room.TypeConverter
    fun toMap(value: String): Map<String, Any> {
        return mapAdapter.fromJson(value) ?: emptyMap()
    }
}