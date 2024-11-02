/*
 * Human Tasks:
 * 1. Ensure Room schema version is properly incremented in build.gradle when modifying entity
 * 2. Verify Room type converters are registered in the database class
 */

package com.founditure.android.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.TypeConverters
import com.founditure.android.domain.model.Furniture
import com.founditure.android.domain.model.Location

/**
 * Room database entity representing a furniture item.
 * Implements local data persistence for offline-first architecture.
 * 
 * Addresses requirements:
 * - Local Data Persistence (1.2 Scope/Core System Components/1. Mobile Applications)
 * - Location-based Search (1.2 Scope/Included Features)
 * - AI/ML Infrastructure (1.2 Scope/Core System Components/3. AI/ML Infrastructure)
 */
@Entity(tableName = "furniture")
@TypeConverters(Converters::class)
data class FurnitureEntity(
    @PrimaryKey
    val id: String,

    @ColumnInfo(name = "user_id")
    val userId: String,

    @ColumnInfo(name = "title")
    val title: String,

    @ColumnInfo(name = "description")
    val description: String,

    @ColumnInfo(name = "category")
    val category: String,

    @ColumnInfo(name = "condition")
    val condition: String,

    @ColumnInfo(name = "dimensions")
    val dimensions: Map<String, Double>,

    @ColumnInfo(name = "material")
    val material: String,

    @ColumnInfo(name = "is_available")
    val isAvailable: Boolean,

    @ColumnInfo(name = "ai_metadata")
    val aiMetadata: Map<String, Any>,

    @ColumnInfo(name = "latitude")
    val latitude: Double,

    @ColumnInfo(name = "longitude")
    val longitude: Double,

    @ColumnInfo(name = "created_at")
    val createdAt: Long,

    @ColumnInfo(name = "expires_at")
    val expiresAt: Long
) {
    init {
        require(title.isNotBlank()) { "Title cannot be empty" }
        require(description.isNotBlank()) { "Description cannot be empty" }
        require(material.isNotBlank()) { "Material cannot be empty" }
        require(latitude >= -90 && latitude <= 90) { "Invalid latitude value" }
        require(longitude >= -180 && longitude <= 180) { "Invalid longitude value" }
        require(expiresAt > createdAt) { "Expiration time must be after creation time" }
    }

    /**
     * Converts the entity to a domain model instance.
     * Maps database fields to domain model properties.
     */
    fun toDomainModel(): Furniture {
        return Furniture(
            id = id,
            userId = userId,
            title = title,
            description = description,
            category = category,
            condition = condition,
            dimensions = dimensions,
            material = material,
            isAvailable = isAvailable,
            aiMetadata = aiMetadata,
            location = Location(latitude, longitude),
            createdAt = createdAt,
            expiresAt = expiresAt
        )
    }

    companion object {
        /**
         * Creates an entity instance from a domain model.
         * Maps domain model properties to database fields.
         */
        fun fromDomainModel(furniture: Furniture): FurnitureEntity {
            return FurnitureEntity(
                id = furniture.id,
                userId = furniture.userId,
                title = furniture.title,
                description = furniture.description,
                category = furniture.category,
                condition = furniture.condition,
                dimensions = furniture.dimensions,
                material = furniture.material,
                isAvailable = furniture.isAvailable,
                aiMetadata = furniture.aiMetadata,
                latitude = furniture.location.latitude,
                longitude = furniture.location.longitude,
                createdAt = furniture.createdAt,
                expiresAt = furniture.expiresAt
            )
        }
    }
}

/**
 * Room type converters for complex data types.
 * Handles conversion between database types and Kotlin types.
 */
object Converters {
    /**
     * Converts dimensions map to JSON string for storage
     */
    @TypeConverter
    fun fromDimensionsMap(dimensions: Map<String, Double>): String {
        return dimensions.entries.joinToString(separator = ",") { "${it.key}:${it.value}" }
    }

    /**
     * Converts JSON string to dimensions map from storage
     */
    @TypeConverter
    fun toDimensionsMap(value: String): Map<String, Double> {
        if (value.isBlank()) return emptyMap()
        return value.split(",").associate {
            val (key, value) = it.split(":")
            key to value.toDouble()
        }
    }

    /**
     * Converts AI metadata map to JSON string for storage
     */
    @TypeConverter
    fun fromAIMetadataMap(metadata: Map<String, Any>): String {
        return metadata.entries.joinToString(separator = ",") { "${it.key}=${it.value}" }
    }

    /**
     * Converts JSON string to AI metadata map from storage
     */
    @TypeConverter
    fun toAIMetadataMap(value: String): Map<String, Any> {
        if (value.isBlank()) return emptyMap()
        return value.split(",").associate {
            val (key, value) = it.split("=")
            key to when {
                value == "true" || value == "false" -> value.toBoolean()
                value.toDoubleOrNull() != null -> value.toDouble()
                else -> value
            }
        }
    }
}