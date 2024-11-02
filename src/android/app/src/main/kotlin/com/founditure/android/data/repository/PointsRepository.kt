/*
 * Human Tasks:
 * 1. Configure ProGuard rules for Kotlin coroutines if using code obfuscation
 * 2. Set up proper error tracking for network failures
 * 3. Configure offline sync work manager for background synchronization
 * 4. Set up proper database backup strategy
 */

package com.founditure.android.data.repository

import com.founditure.android.data.local.dao.PointsDao
import com.founditure.android.data.remote.api.PointsService
import com.founditure.android.domain.model.Points
import javax.inject.Inject
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Repository implementation for managing points and achievements data with offline-first architecture.
 * Implements caching strategy with remote synchronization for the gamification system.
 *
 * Addresses requirements:
 * - Points System (1.2 Scope/Core System Components/Backend Services)
 * - Offline-first architecture (1.2 Scope/Core System Components/Mobile Applications)
 */
class PointsRepository @Inject constructor(
    private val pointsDao: PointsDao,
    private val pointsService: PointsService
) {
    /**
     * Retrieves points data for a specific user with offline support.
     * Implements offline-first strategy by emitting local data first and then
     * attempting to fetch fresh data from the remote API.
     *
     * @param userId Unique identifier of the user
     * @return Flow of user's points data or null if not found
     */
    fun getUserPoints(userId: String): Flow<Points?> = flow {
        // Emit local data first
        val localPoints = pointsDao.getPointsByUserId(userId)
        emitAll(localPoints.map { it?.toDomainModel() })

        try {
            // Attempt to fetch fresh data from remote
            withContext(Dispatchers.IO) {
                val response = pointsService.getUserPoints(userId)
                if (response.isSuccessful) {
                    response.body()?.let { pointsDto ->
                        // Update local database with fresh data
                        pointsDao.insertPoints(pointsDto.toEntity())
                    }
                }
            }
        } catch (e: Exception) {
            // Log error but don't throw - we already emitted local data
            e.printStackTrace()
        }
    }

    /**
     * Adds points for a specific activity with offline support.
     * Updates local database immediately and attempts to sync with remote.
     *
     * @param userId Unique identifier of the user
     * @param activityType Type of activity for which points are being awarded
     * @param points Number of points to add
     * @return Updated points data
     */
    suspend fun addPoints(userId: String, activityType: String, points: Int): Points {
        // Get current points data
        val currentPoints = pointsDao.getPointsByUserId(userId).first()
            ?: throw IllegalStateException("User points not found")

        // Update points locally
        val updatedPoints = currentPoints.toDomainModel().addPoints(activityType, points)
        pointsDao.insertPoints(updatedPoints.toEntity())

        try {
            // Attempt to sync with remote
            withContext(Dispatchers.IO) {
                val response = pointsService.addPoints(userId, updatedPoints.toDto())
                if (response.isSuccessful) {
                    response.body()?.let { pointsDto ->
                        pointsDao.insertPoints(pointsDto.toEntity())
                        return@withContext pointsDto.toDomainModel()
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            // Return locally updated points if remote sync fails
        }

        return updatedPoints
    }

    /**
     * Retrieves points leaderboard data with caching.
     * Implements cache-then-network strategy for leaderboard data.
     *
     * @param timeframe Time period for leaderboard data
     * @param limit Maximum number of entries to return
     * @return Flow of leaderboard data
     */
    fun getLeaderboard(timeframe: String, limit: Int): Flow<List<Points>> = flow {
        // Emit cached leaderboard first
        val cachedLeaderboard = pointsDao.getTopPointsHolders(limit)
        emitAll(cachedLeaderboard.map { list -> list.map { it.toDomainModel() } })

        try {
            // Fetch fresh leaderboard data
            withContext(Dispatchers.IO) {
                val response = pointsService.getLeaderboard(timeframe)
                if (response.isSuccessful) {
                    response.body()?.let { pointsDtos ->
                        // Update local cache
                        pointsDtos.forEach { pointsDto ->
                            pointsDao.insertPoints(pointsDto.toEntity())
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Synchronizes local points data with remote server.
     * Handles conflict resolution between local and remote data.
     *
     * @param userId Unique identifier of the user
     * @return Result of synchronization attempt
     */
    suspend fun syncPoints(userId: String): Result<Points> = runCatching {
        val localPoints = pointsDao.getPointsByUserId(userId).first()
            ?: throw IllegalStateException("User points not found")

        withContext(Dispatchers.IO) {
            val response = pointsService.getUserPoints(userId)
            if (response.isSuccessful) {
                response.body()?.let { remotePoints ->
                    // Resolve conflicts - remote wins for total points
                    val mergedPoints = mergePointsData(localPoints.toDomainModel(), remotePoints.toDomainModel())
                    pointsDao.insertPoints(mergedPoints.toEntity())
                    return@withContext mergedPoints
                }
            }
            throw Exception("Sync failed: ${response.code()}")
        }
    }

    /**
     * Resets weekly points counter with remote synchronization.
     *
     * @param userId Unique identifier of the user
     * @return Updated points data
     */
    suspend fun resetWeeklyPoints(userId: String): Points {
        // Reset locally first
        val currentPoints = pointsDao.getPointsByUserId(userId).first()
            ?: throw IllegalStateException("User points not found")
        
        val resetPoints = currentPoints.toDomainModel().resetWeeklyPoints()
        pointsDao.insertPoints(resetPoints.toEntity())

        try {
            // Sync with remote
            withContext(Dispatchers.IO) {
                val response = pointsService.resetWeeklyPoints(userId)
                if (response.isSuccessful) {
                    response.body()?.let { pointsDto ->
                        pointsDao.insertPoints(pointsDto.toEntity())
                        return@withContext pointsDto.toDomainModel()
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return resetPoints
    }

    /**
     * Resets monthly points counter with remote synchronization.
     *
     * @param userId Unique identifier of the user
     * @return Updated points data
     */
    suspend fun resetMonthlyPoints(userId: String): Points {
        // Reset locally first
        val currentPoints = pointsDao.getPointsByUserId(userId).first()
            ?: throw IllegalStateException("User points not found")
        
        val resetPoints = currentPoints.toDomainModel().resetMonthlyPoints()
        pointsDao.insertPoints(resetPoints.toEntity())

        try {
            // Sync with remote
            withContext(Dispatchers.IO) {
                val response = pointsService.resetMonthlyPoints(userId)
                if (response.isSuccessful) {
                    response.body()?.let { pointsDto ->
                        pointsDao.insertPoints(pointsDto.toEntity())
                        return@withContext pointsDto.toDomainModel()
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return resetPoints
    }

    /**
     * Merges local and remote points data, resolving conflicts.
     * Remote data takes precedence for total points, while preserving local activity history.
     */
    private fun mergePointsData(local: Points, remote: Points): Points {
        return Points(
            id = local.id,
            userId = local.userId,
            totalPoints = maxOf(local.totalPoints, remote.totalPoints),
            weeklyPoints = remote.weeklyPoints,
            monthlyPoints = remote.monthlyPoints,
            achievements = (local.achievements + remote.achievements).distinct(),
            activityPoints = local.activityPoints + remote.activityPoints,
            lastUpdated = maxOf(local.lastUpdated, remote.lastUpdated)
        )
    }
}