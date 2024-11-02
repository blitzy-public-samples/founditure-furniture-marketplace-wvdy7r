/*
 * Human Tasks:
 * 1. Ensure Room dependencies are added to app/build.gradle:
 *    implementation "androidx.room:room-runtime:2.5.0"
 *    implementation "androidx.room:room-ktx:2.5.0"
 *    kapt "androidx.room:room-compiler:2.5.0"
 * 2. Add Kotlin Coroutines Flow dependency:
 *    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.0"
 */

package com.founditure.android.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.founditure.android.data.local.entity.UserEntity
import kotlinx.coroutines.flow.Flow

/**
 * Room DAO interface for User entity operations.
 * 
 * Addresses requirements:
 * - Local Data Persistence (1.2 Scope/Core System Components/Mobile Applications)
 * - Data Management (1.2 Scope/Core System Components/Data Management)
 */
@Dao
interface UserDao {
    /**
     * Retrieves a user by their ID.
     * Returns a Flow to observe user data changes reactively.
     * 
     * @param userId The unique identifier of the user
     * @return Flow emitting the user entity or null if not found
     */
    @Query("SELECT * FROM users WHERE id = :userId")
    fun getUser(userId: String): Flow<UserEntity?>

    /**
     * Retrieves a user by their email address.
     * Useful for login and user verification flows.
     * 
     * @param email The email address of the user
     * @return Flow emitting the user entity or null if not found
     */
    @Query("SELECT * FROM users WHERE email = :email")
    fun getUserByEmail(email: String): Flow<UserEntity?>

    /**
     * Retrieves all users from the database.
     * Used for administrative purposes and user listing features.
     * 
     * @return Flow emitting list of all user entities
     */
    @Query("SELECT * FROM users")
    fun getAllUsers(): Flow<List<UserEntity>>

    /**
     * Inserts a new user into the database.
     * Uses REPLACE strategy for conflict resolution to update existing users.
     * 
     * @param user The user entity to insert
     * @return ID of the inserted user
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: UserEntity): Long

    /**
     * Updates an existing user in the database.
     * 
     * @param user The user entity to update
     * @return Number of users updated (should be 1 if successful)
     */
    @Update
    suspend fun updateUser(user: UserEntity): Int

    /**
     * Deletes a user from the database.
     * 
     * @param user The user entity to delete
     * @return Number of users deleted (should be 1 if successful)
     */
    @Delete
    suspend fun deleteUser(user: UserEntity): Int

    /**
     * Updates user points balance.
     * Part of the gamification system for user engagement.
     * 
     * @param userId The ID of the user to update
     * @param points The new points value
     * @return Number of users updated (should be 1 if successful)
     */
    @Query("UPDATE users SET points = :points WHERE id = :userId")
    suspend fun updatePoints(userId: String, points: Int): Int

    /**
     * Updates user verification status.
     * Used in the user verification workflow.
     * 
     * @param userId The ID of the user to update
     * @param isVerified The new verification status
     * @return Number of users updated (should be 1 if successful)
     */
    @Query("UPDATE users SET isVerified = :isVerified WHERE id = :userId")
    suspend fun updateVerificationStatus(userId: String, isVerified: Boolean): Int
}