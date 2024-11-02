/*
 * Human Tasks:
 * 1. Configure ProGuard rules for Kotlin coroutines if using code obfuscation
 * 2. Verify proper error handling and logging setup
 * 3. Set up proper monitoring for points retrieval performance
 */

package com.founditure.android.domain.usecase.points

import com.founditure.android.data.repository.PointsRepository
import com.founditure.android.domain.model.Points
import javax.inject.Inject
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map

/**
 * Use case implementation for retrieving user points and achievements data.
 * Implements clean architecture pattern for business logic separation.
 * 
 * Addresses requirements:
 * - Points System (1.2 Scope/Core System Components/Backend Services)
 * - Offline-first architecture (1.2 Scope/Core System Components/Mobile Applications)
 */
class GetPointsUseCase @Inject constructor(
    private val pointsRepository: PointsRepository
) {
    /**
     * Retrieves points data for a specific user with offline support.
     * Validates input parameters and delegates to repository layer.
     *
     * @param userId Unique identifier of the user
     * @return Flow of user's points data or null if not found
     * @throws IllegalArgumentException if userId is blank
     */
    fun execute(userId: String): Flow<Points?> {
        require(userId.isNotBlank()) { "User ID cannot be blank" }
        
        return pointsRepository.getUserPoints(userId)
            .catch { exception ->
                // Log error but don't throw - maintain offline-first behavior
                exception.printStackTrace()
                emit(null)
            }
    }

    /**
     * Retrieves points leaderboard data with specified timeframe and limit.
     * Validates input parameters and delegates to repository layer.
     *
     * @param timeframe Time period for leaderboard ("weekly", "monthly", "all-time")
     * @param limit Maximum number of entries to return (1-100)
     * @return Flow of leaderboard data sorted by points
     * @throws IllegalArgumentException if parameters are invalid
     */
    fun getLeaderboard(timeframe: String, limit: Int): Flow<List<Points>> {
        // Validate timeframe
        require(timeframe in setOf("weekly", "monthly", "all-time")) {
            "Invalid timeframe: $timeframe. Must be one of: weekly, monthly, all-time"
        }

        // Validate limit
        require(limit in 1..100) {
            "Invalid limit: $limit. Must be between 1 and 100"
        }

        return pointsRepository.getLeaderboard(timeframe, limit)
            .map { points ->
                // Sort by points based on timeframe
                when (timeframe) {
                    "weekly" -> points.sortedByDescending { it.weeklyPoints }
                    "monthly" -> points.sortedByDescending { it.monthlyPoints }
                    else -> points.sortedByDescending { it.totalPoints }
                }
            }
            .catch { exception ->
                // Log error but emit empty list to maintain offline-first behavior
                exception.printStackTrace()
                emit(emptyList())
            }
    }
}