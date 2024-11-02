/*
 * Human Tasks:
 * 1. Ensure Room database version is incremented in build.gradle when modifying DAO queries
 * 2. Verify indexes are created for frequently queried columns in the database
 */

package com.founditure.android.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.founditure.android.data.local.entity.FurnitureEntity
import kotlinx.coroutines.flow.Flow

/**
 * Room DAO interface for furniture-related database operations.
 * Provides methods for CRUD operations and complex queries on furniture data.
 * 
 * Addresses requirements:
 * - Local Data Persistence (1.2 Scope/Core System Components/1. Mobile Applications)
 * - Location-based Search (1.2 Scope/Included Features)
 */
@Dao
interface FurnitureDao {
    /**
     * Retrieves a furniture entity by its ID.
     * Returns a Flow to observe changes in the furniture data.
     *
     * @param id The unique identifier of the furniture item
     * @return Flow emitting the furniture entity or null if not found
     */
    @Query("SELECT * FROM furniture WHERE id = :id")
    fun getFurnitureById(id: String): Flow<FurnitureEntity?>

    /**
     * Retrieves all furniture entities ordered by creation date.
     * Returns a Flow to observe changes in the furniture list.
     *
     * @return Flow emitting list of all furniture entities
     */
    @Query("SELECT * FROM furniture ORDER BY created_at DESC")
    fun getAllFurniture(): Flow<List<FurnitureEntity>>

    /**
     * Retrieves all furniture entities for a specific user.
     * Returns a Flow to observe changes in the user's furniture list.
     *
     * @param userId The unique identifier of the user
     * @return Flow emitting list of user's furniture entities
     */
    @Query("SELECT * FROM furniture WHERE user_id = :userId ORDER BY created_at DESC")
    fun getFurnitureByUserId(userId: String): Flow<List<FurnitureEntity>>

    /**
     * Retrieves furniture entities within a specified radius of coordinates.
     * Uses Euclidean distance calculation for location-based search.
     * Only returns available furniture items.
     *
     * @param lat The latitude coordinate of the center point
     * @param lng The longitude coordinate of the center point
     * @param radiusSquared The square of the search radius (for optimization)
     * @return Flow emitting list of nearby furniture entities
     */
    @Query("""
        SELECT *, ((latitude - :lat) * (latitude - :lat) + (longitude - :lng) * (longitude - :lng)) AS distance 
        FROM furniture 
        WHERE distance <= :radiusSquared AND is_available = 1 
        ORDER BY distance
    """)
    fun getFurnitureNearLocation(lat: Double, lng: Double, radiusSquared: Double): Flow<List<FurnitureEntity>>

    /**
     * Inserts a new furniture entity into the database.
     * Returns the row ID of the inserted entity.
     *
     * @param furniture The furniture entity to insert
     * @return ID of inserted entity
     */
    @Insert
    suspend fun insertFurniture(furniture: FurnitureEntity): Long

    /**
     * Updates an existing furniture entity in the database.
     * Returns the number of rows updated.
     *
     * @param furniture The furniture entity to update
     * @return Number of rows updated
     */
    @Update
    suspend fun updateFurniture(furniture: FurnitureEntity): Int

    /**
     * Deletes a furniture entity from the database.
     * Returns the number of rows deleted.
     *
     * @param furniture The furniture entity to delete
     * @return Number of rows deleted
     */
    @Delete
    suspend fun deleteFurniture(furniture: FurnitureEntity): Int

    /**
     * Deletes all expired furniture listings from the database.
     * Returns the number of rows deleted.
     *
     * @param currentTime The current timestamp for comparison
     * @return Number of rows deleted
     */
    @Query("DELETE FROM furniture WHERE expires_at < :currentTime")
    suspend fun deleteExpiredFurniture(currentTime: Long): Int
}