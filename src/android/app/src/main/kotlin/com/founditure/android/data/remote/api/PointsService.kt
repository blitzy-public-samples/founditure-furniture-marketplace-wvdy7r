package com.founditure.android.data.remote.api

import com.founditure.android.data.remote.dto.PointsDto
import retrofit2.Response // version: 2.9.0
import retrofit2.http.* // version: 2.9.0

/**
 * Remote API service interface for managing points and achievements in the Founditure Android application.
 * Handles network communication for the gamification system.
 *
 * Addresses requirements:
 * - Points System (1.2 Scope/Core System Components/Backend Services)
 * - Points-based gamification engine (1.1 System Overview)
 */
interface PointsService {

    /**
     * Retrieves points and achievements for a specific user
     * @param userId Unique identifier of the user
     * @return Network response containing user's points data
     */
    @GET("api/v1/points/{userId}")
    suspend fun getUserPoints(
        @Path("userId") userId: String
    ): Response<PointsDto>

    /**
     * Adds points for a specific activity to user's total
     * @param userId Unique identifier of the user
     * @param pointsDto Points data to be added
     * @return Network response containing updated points data
     */
    @POST("api/v1/points/{userId}/add")
    suspend fun addPoints(
        @Path("userId") userId: String,
        @Body pointsDto: PointsDto
    ): Response<PointsDto>

    /**
     * Updates user's achievements list
     * @param userId Unique identifier of the user
     * @param pointsDto Points data containing updated achievements
     * @return Network response containing updated achievements data
     */
    @PUT("api/v1/points/{userId}/achievements")
    suspend fun updateAchievements(
        @Path("userId") userId: String,
        @Body pointsDto: PointsDto
    ): Response<PointsDto>

    /**
     * Retrieves points leaderboard data
     * @param timeframe Time period for leaderboard ("daily", "weekly", "monthly", "all-time")
     * @return Network response containing leaderboard data
     */
    @GET("api/v1/points/leaderboard")
    suspend fun getLeaderboard(
        @Query("timeframe") timeframe: String
    ): Response<List<PointsDto>>

    /**
     * Resets weekly points counter for a user
     * @param userId Unique identifier of the user
     * @return Network response containing updated points data
     */
    @POST("api/v1/points/{userId}/reset/weekly")
    suspend fun resetWeeklyPoints(
        @Path("userId") userId: String
    ): Response<PointsDto>

    /**
     * Resets monthly points counter for a user
     * @param userId Unique identifier of the user
     * @return Network response containing updated points data
     */
    @POST("api/v1/points/{userId}/reset/monthly")
    suspend fun resetMonthlyPoints(
        @Path("userId") userId: String
    ): Response<PointsDto>
}