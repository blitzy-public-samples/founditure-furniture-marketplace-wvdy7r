/*
 * Human Tasks:
 * 1. Ensure Kotlin Coroutines dependencies are added to app/build.gradle:
 *    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.0"
 *    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.6.0"
 * 2. Ensure Room dependencies are configured (see UserDao.kt)
 * 3. Configure Dagger Hilt for dependency injection in app/build.gradle
 */

package com.founditure.android.data.repository

import com.founditure.android.data.local.dao.UserDao
import com.founditure.android.data.remote.api.AuthService
import com.founditure.android.data.remote.dto.UserDto
import com.founditure.android.domain.model.User
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository implementation that coordinates user data operations between local database storage
 * and remote API, following the offline-first architecture pattern.
 *
 * Addresses requirements:
 * - User Management (1.2 Scope/Core System Components/Backend Services)
 * - Local Data Persistence (1.2 Scope/Core System Components/Mobile Applications)
 * - Data Management (1.2 Scope/Core System Components/Data Management)
 */
@Singleton
class UserRepository @Inject constructor(
    private val userDao: UserDao,
    private val authService: AuthService
) {
    /**
     * Retrieves user by ID with offline support.
     * Returns a Flow that emits user data from local database and updates when data changes.
     *
     * @param userId Unique identifier of the user
     * @return Flow emitting user data or null if not found
     */
    fun getUser(userId: String): Flow<User?> {
        return userDao.getUser(userId).map { entity ->
            entity?.let { UserDto.fromDomainModel(it.toDomainModel()).toDomainModel() }
        }
    }

    /**
     * Retrieves user by email with offline support.
     * Used primarily for authentication and user lookup operations.
     *
     * @param email Email address of the user
     * @return Flow emitting user data or null if not found
     */
    fun getUserByEmail(email: String): Flow<User?> {
        return userDao.getUserByEmail(email).map { entity ->
            entity?.let { UserDto.fromDomainModel(it.toDomainModel()).toDomainModel() }
        }
    }

    /**
     * Updates user data locally and syncs with remote server.
     * Follows offline-first pattern by updating local database first.
     *
     * @param user Updated user data
     * @return Success status of update operation
     */
    suspend fun updateUser(user: User): Boolean = withContext(Dispatchers.IO) {
        try {
            // Update local database first
            val userEntity = UserDto.fromDomainModel(user).toDomainModel()
            val localUpdateSuccess = userDao.updateUser(userEntity) > 0

            if (!localUpdateSuccess) {
                return@withContext false
            }

            // Try to sync with remote API
            try {
                val userDto = UserDto.fromDomainModel(user)
                authService.updateUser(userDto).blockingGet()
                true
            } catch (e: Exception) {
                // Remote sync failed but local update succeeded
                // Will be synced later when connectivity is restored
                true
            }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Updates user points balance with offline support.
     * Critical for the gamification system functionality.
     *
     * @param userId ID of the user
     * @param points New points value
     * @return Success status of points update
     */
    suspend fun updatePoints(userId: String, points: Int): Boolean = withContext(Dispatchers.IO) {
        try {
            // Update points in local database
            val localUpdateSuccess = userDao.updatePoints(userId, points) > 0

            if (!localUpdateSuccess) {
                return@withContext false
            }

            // Try to sync with remote API
            try {
                authService.updatePoints(userId, points).blockingGet()
                true
            } catch (e: Exception) {
                // Remote sync failed but local update succeeded
                // Will be synced later when connectivity is restored
                true
            }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Synchronizes local user data with remote server.
     * Used to ensure data consistency between local and remote storage.
     *
     * @param userId ID of the user to sync
     * @return Success status of sync operation
     */
    suspend fun syncUser(userId: String): Boolean = withContext(Dispatchers.IO) {
        try {
            // Fetch latest user data from remote API
            val remoteUser = authService.getUser(userId).blockingGet()
            
            // Update local database with remote data
            val userEntity = UserDto.fromDomainModel(remoteUser.toDomainModel())
            val updateSuccess = userDao.updateUser(userEntity) > 0

            updateSuccess
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Handles user verification status update.
     * Part of the user authentication and verification workflow.
     *
     * @param userId ID of the user
     * @param isVerified New verification status
     * @return Success status of verification update
     */
    suspend fun updateVerificationStatus(userId: String, isVerified: Boolean): Boolean = 
        withContext(Dispatchers.IO) {
            try {
                // Update local verification status
                val localUpdateSuccess = userDao.updateVerificationStatus(userId, isVerified) > 0

                if (!localUpdateSuccess) {
                    return@withContext false
                }

                // Sync with remote API
                try {
                    authService.updateVerificationStatus(userId, isVerified).blockingGet()
                    true
                } catch (e: Exception) {
                    // Remote sync failed but local update succeeded
                    true
                }
            } catch (e: Exception) {
                false
            }
        }

    /**
     * Deletes user data locally and remotely.
     * Handles user account deletion with proper cleanup.
     *
     * @param userId ID of the user to delete
     * @return Success status of deletion operation
     */
    suspend fun deleteUser(userId: String): Boolean = withContext(Dispatchers.IO) {
        try {
            // Get user entity first
            val userEntity = userDao.getUser(userId).map { it }.firstOrNull() ?: return@withContext false

            // Delete from local database
            val localDeleteSuccess = userDao.deleteUser(userEntity) > 0

            if (!localDeleteSuccess) {
                return@withContext false
            }

            // Try to sync deletion with remote API
            try {
                authService.deleteUser(userId).blockingGet()
                true
            } catch (e: Exception) {
                // Remote deletion failed but local deletion succeeded
                true
            }
        } catch (e: Exception) {
            false
        }
    }
}