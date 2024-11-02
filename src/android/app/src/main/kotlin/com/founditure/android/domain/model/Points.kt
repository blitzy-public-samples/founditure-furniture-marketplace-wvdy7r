/*
 * Human Tasks:
 * 1. Ensure Kotlin Android Extensions plugin is enabled in the app-level build.gradle
 * 2. Verify Parcelable implementation is working correctly across process boundaries
 * 3. Configure ProGuard rules if needed for Parcelable serialization
 */

package com.founditure.android.domain.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize
import java.util.concurrent.TimeUnit

/**
 * Domain model representing user points and achievements in the gamification system.
 * Implements Parcelable for efficient data transfer between Android components.
 * 
 * Addresses requirements:
 * - Points System (1.2 Scope/Core System Components/Backend Services)
 * - Points-based gamification engine (1.1 System Overview)
 */
@Parcelize
data class Points(
    val id: String,
    val userId: String,
    val totalPoints: Int,
    val weeklyPoints: Int,
    val monthlyPoints: Int,
    val achievements: List<String>,
    val activityPoints: Map<String, Int>,
    val lastUpdated: Long
) : Parcelable {

    /**
     * Adds points for a specific activity and updates all relevant point counters.
     * Updates the lastUpdated timestamp to track the most recent activity.
     *
     * @param activityType The type of activity for which points are being awarded
     * @param points The number of points to award
     * @return A new Points instance with updated point values
     */
    fun addPoints(activityType: String, points: Int): Points {
        val updatedActivityPoints = activityPoints.toMutableMap().apply {
            put(activityType, (getOrDefault(activityType, 0) + points))
        }

        return copy(
            totalPoints = totalPoints + points,
            weeklyPoints = weeklyPoints + points,
            monthlyPoints = monthlyPoints + points,
            activityPoints = updatedActivityPoints,
            lastUpdated = System.currentTimeMillis()
        )
    }

    /**
     * Adds a new achievement to the user's collection if it's not already present.
     * Updates the lastUpdated timestamp to track the achievement addition.
     *
     * @param achievementId The unique identifier of the achievement to add
     * @return A new Points instance with the updated achievements list
     */
    fun addAchievement(achievementId: String): Points {
        if (achievements.contains(achievementId)) {
            return this
        }

        return copy(
            achievements = achievements + achievementId,
            lastUpdated = System.currentTimeMillis()
        )
    }

    /**
     * Resets the weekly points counter while preserving all other data.
     * Updates the lastUpdated timestamp to track the reset operation.
     *
     * @return A new Points instance with reset weekly points
     */
    fun resetWeeklyPoints(): Points {
        return copy(
            weeklyPoints = 0,
            lastUpdated = System.currentTimeMillis()
        )
    }

    /**
     * Resets the monthly points counter while preserving all other data.
     * Updates the lastUpdated timestamp to track the reset operation.
     *
     * @return A new Points instance with reset monthly points
     */
    fun resetMonthlyPoints(): Points {
        return copy(
            monthlyPoints = 0,
            lastUpdated = System.currentTimeMillis()
        )
    }

    companion object {
        // Time constants for points management
        const val WEEK_IN_MILLIS = TimeUnit.DAYS.toMillis(7)
        const val MONTH_IN_MILLIS = TimeUnit.DAYS.toMillis(30)
    }
}