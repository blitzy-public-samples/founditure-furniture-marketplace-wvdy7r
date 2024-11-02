/*
 * Human Tasks:
 * 1. Ensure Kotlin Parcelize plugin is enabled in the app-level build.gradle:
 *    id 'kotlin-parcelize'
 */

package com.founditure.android.domain.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

/**
 * Domain model representing a user in the Founditure application.
 * 
 * Addresses requirements:
 * - Core user management functionality (1.1 System Overview/Core System Components/Backend Services)
 * - Offline-first architecture for user data (1.2 Scope/Core System Components/Mobile Applications)
 */
@Parcelize
data class User(
    val id: String,
    val email: String,
    val fullName: String,
    val phoneNumber: String?,
    val points: Int,
    val profileImageUrl: String?,
    val createdAt: Long,
    val updatedAt: Long,
    val isVerified: Boolean,
    val preferences: Map<String, Any>
) : Parcelable {

    /**
     * Creates a copy of the User with optional property modifications.
     * Implements the copy function as specified in the requirements.
     */
    fun copy(
        id: String? = null,
        email: String? = null,
        fullName: String? = null,
        phoneNumber: String? = null,
        points: Int? = null,
        profileImageUrl: String? = null,
        createdAt: Long? = null,
        updatedAt: Long? = null,
        isVerified: Boolean? = null,
        preferences: Map<String, Any>? = null
    ): User = User(
        id = id ?: this.id,
        email = email ?: this.email,
        fullName = fullName ?: this.fullName,
        phoneNumber = phoneNumber ?: this.phoneNumber,
        points = points ?: this.points,
        profileImageUrl = profileImageUrl ?: this.profileImageUrl,
        createdAt = createdAt ?: this.createdAt,
        updatedAt = updatedAt ?: this.updatedAt,
        isVerified = isVerified ?: this.isVerified,
        preferences = preferences ?: this.preferences
    )

    /**
     * Checks equality between two User instances.
     * Implements deep comparison of all properties.
     */
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is User) return false

        return id == other.id &&
                email == other.email &&
                fullName == other.fullName &&
                phoneNumber == other.phoneNumber &&
                points == other.points &&
                profileImageUrl == other.profileImageUrl &&
                createdAt == other.createdAt &&
                updatedAt == other.updatedAt &&
                isVerified == other.isVerified &&
                preferences == other.preferences
    }

    /**
     * Generates hash code for User instance.
     * Implements consistent hash code generation using all properties.
     */
    override fun hashCode(): Int {
        var result = id.hashCode()
        result = 31 * result + email.hashCode()
        result = 31 * result + fullName.hashCode()
        result = 31 * result + (phoneNumber?.hashCode() ?: 0)
        result = 31 * result + points
        result = 31 * result + (profileImageUrl?.hashCode() ?: 0)
        result = 31 * result + createdAt.hashCode()
        result = 31 * result + updatedAt.hashCode()
        result = 31 * result + isVerified.hashCode()
        result = 31 * result + preferences.hashCode()
        return result
    }
}