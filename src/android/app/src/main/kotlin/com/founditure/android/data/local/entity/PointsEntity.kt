/*
 * Human Tasks:
 * 1. Verify Room database schema version and migration strategy
 * 2. Ensure Moshi is added to the project dependencies for JSON serialization
 * 3. Configure ProGuard rules if needed for Room and Moshi
 */

package com.founditure.android.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverter
import com.founditure.android.domain.model.Points
import com.squareup.moshi.Moshi
import com.squareup.moshi.Types
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory

/**
 * Room database entity class for storing points and achievements data.
 * Maps to the points table in the Room database.
 * 
 * Addresses requirements:
 * - Points System (1.2 Scope/Core System Components/Backend Services)
 * - Offline-first architecture (1.2 Scope/Core System Components/Mobile Applications)
 */
@Entity(tableName = "points")
data class PointsEntity(
    @PrimaryKey
    val id: String,

    @ColumnInfo(name = "user_id")
    val userId: String,

    @ColumnInfo(name = "total_points")
    val totalPoints: Int,

    @ColumnInfo(name = "weekly_points")
    val weeklyPoints: Int,

    @ColumnInfo(name = "monthly_points")
    val monthlyPoints: Int,

    @ColumnInfo(name = "achievements")
    val achievements: List<String>,

    @ColumnInfo(name = "activity_points")
    val activityPoints: Map<String, Int>,

    @ColumnInfo(name = "last_updated")
    val lastUpdated: Long
) {
    /**
     * Converts the entity to its corresponding domain model.
     * Used when retrieving data from the database to present to the UI layer.
     *
     * @return Points domain model instance
     */
    fun toDomainModel(): Points {
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
         * Creates a PointsEntity from a domain model instance.
         * Used when storing domain model data in the local database.
         *
         * @param points Domain model instance to convert
         * @return PointsEntity instance
         */
        fun fromDomainModel(points: Points): PointsEntity {
            return PointsEntity(
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

/**
 * Type converters for complex data types in PointsEntity.
 * Handles conversion between complex types and their string representations for Room storage.
 */
class PointsTypeConverters {
    private val moshi = Moshi.Builder()
        .add(KotlinJsonAdapterFactory())
        .build()

    @TypeConverter
    fun achievementsToString(achievements: List<String>): String {
        val type = Types.newParameterizedType(List::class.java, String::class.java)
        val adapter = moshi.adapter<List<String>>(type)
        return adapter.toJson(achievements)
    }

    @TypeConverter
    fun stringToAchievements(value: String): List<String> {
        val type = Types.newParameterizedType(List::class.java, String::class.java)
        val adapter = moshi.adapter<List<String>>(type)
        return adapter.fromJson(value) ?: emptyList()
    }

    @TypeConverter
    fun activityPointsToString(activityPoints: Map<String, Int>): String {
        val type = Types.newParameterizedType(Map::class.java, String::class.java, Integer::class.java)
        val adapter = moshi.adapter<Map<String, Int>>(type)
        return adapter.toJson(activityPoints)
    }

    @TypeConverter
    fun stringToActivityPoints(value: String): Map<String, Int> {
        val type = Types.newParameterizedType(Map::class.java, String::class.java, Integer::class.java)
        val adapter = moshi.adapter<Map<String, Int>>(type)
        return adapter.fromJson(value) ?: emptyMap()
    }
}