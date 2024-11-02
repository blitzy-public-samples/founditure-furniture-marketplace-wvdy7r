/*
 * Human Tasks:
 * 1. Verify Room database schema version and migration strategy
 * 2. Configure Room database testing with in-memory database
 * 3. Set up database backup and recovery strategy
 */

package com.founditure.android.data.local.dao

// Room DAO annotations - version 2.5.0
import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update

// Kotlin Flow - version 1.6.4
import kotlinx.coroutines.flow.Flow

import com.founditure.android.data.local.entity.PointsEntity

/**
 * Room Database Data Access Object (DAO) interface for points and achievements data.
 * Provides methods for CRUD operations on points data with reactive Flow return types.
 *
 * Addresses requirements:
 * - Points System (1.2 Scope/Core System Components/Backend Services)
 * - Offline-first architecture (1.2 Scope/Core System Components/Mobile Applications)
 */
@Dao
interface PointsDao {
    /**
     * Retrieves points data by ID.
     * Returns a Flow to observe changes in the points data.
     *
     * @param id Unique identifier of the points record
     * @return Flow emitting the points entity or null if not found
     */
    @Query("SELECT * FROM points WHERE id = :id")
    fun getPointsById(id: String): Flow<PointsEntity?>

    /**
     * Retrieves points data by user ID.
     * Returns a Flow to observe changes in the user's points data.
     *
     * @param userId Unique identifier of the user
     * @return Flow emitting the points entity or null if not found
     */
    @Query("SELECT * FROM points WHERE user_id = :userId")
    fun getPointsByUserId(userId: String): Flow<PointsEntity?>

    /**
     * Retrieves top users by total points.
     * Used for leaderboard functionality.
     *
     * @param limit Maximum number of records to return
     * @return Flow emitting list of top points holders
     */
    @Query("SELECT * FROM points ORDER BY total_points DESC LIMIT :limit")
    fun getTopPointsHolders(limit: Int): Flow<List<PointsEntity>>

    /**
     * Inserts new points data.
     * Uses REPLACE strategy for conflict resolution to ensure upsert behavior.
     *
     * @param points Points entity to insert
     * @return ID of the inserted record
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPoints(points: PointsEntity): Long

    /**
     * Updates existing points data.
     * Used for modifying points and achievements.
     *
     * @param points Points entity to update
     * @return Number of records updated
     */
    @Update
    suspend fun updatePoints(points: PointsEntity): Int

    /**
     * Deletes points data.
     * Used for removing points records when needed.
     *
     * @param points Points entity to delete
     * @return Number of records deleted
     */
    @Delete
    suspend fun deletePoints(points: PointsEntity): Int

    /**
     * Resets weekly points for all users.
     * Called at the end of each week for weekly leaderboard reset.
     */
    @Query("UPDATE points SET weekly_points = 0")
    suspend fun resetWeeklyPoints()

    /**
     * Resets monthly points for all users.
     * Called at the end of each month for monthly leaderboard reset.
     */
    @Query("UPDATE points SET monthly_points = 0")
    suspend fun resetMonthlyPoints()
}