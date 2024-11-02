package com.founditure.android.data.remote.dto

import com.founditure.android.domain.model.Points
import com.google.gson.annotations.SerializedName // version: 2.9.0

/**
 * Data Transfer Object representing points and achievements data for network communication.
 * 
 * Addresses requirements:
 * - Points System (1.2 Scope/Core System Components/Backend Services)
 * - Points-based gamification engine (1.1 System Overview)
 */
data class PointsDto(
    @SerializedName("id")
    val id: String,
    
    @SerializedName("userId")
    val userId: String,
    
    @SerializedName("totalPoints")
    val totalPoints: Int,
    
    @SerializedName("weeklyPoints")
    val weeklyPoints: Int,
    
    @SerializedName("monthlyPoints")
    val monthlyPoints: Int,
    
    @SerializedName("achievements")
    val achievements: List<String>,
    
    @SerializedName("activityPoints")
    val activityPoints: Map<String, Int>,
    
    @SerializedName("lastUpdated")
    val lastUpdated: Long
) {
    /**
     * Converts DTO to domain model Points object
     * @return Domain model Points instance
     */
    fun toPoints(): Points {
        return Points(
            id = id,
            userId = userId,
            totalPoints = totalPoints,
            weeklyPoints = weeklyPoints,
            monthlyPoints = monthlyPoints,
            achievements = achievements,
            activityPoints = activityPoints,
            lastUpdated = lastUpdated
        )
    }

    companion object {
        /**
         * Creates DTO from domain model Points object
         * @param points Domain model Points instance
         * @return DTO instance
         */
        fun fromPoints(points: Points): PointsDto {
            return PointsDto(
                id = points.id,
                userId = points.userId,
                totalPoints = points.totalPoints,
                weeklyPoints = points.weeklyPoints,
                monthlyPoints = points.monthlyPoints,
                achievements = points.achievements,
                activityPoints = points.activityPoints,
                lastUpdated = points.lastUpdated
            )
        }
    }
}