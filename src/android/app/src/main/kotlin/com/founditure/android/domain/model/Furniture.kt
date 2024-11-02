/*
 * Human Tasks:
 * 1. Ensure kotlinx.parcelize plugin is enabled in the app-level build.gradle
 * 2. Verify predefined categories and conditions are synchronized with backend
 */

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

/**
 * Domain model class representing a furniture item in the Founditure application.
 * Implements Parcelable for efficient data passing between Android components.
 * 
 * Addresses requirements:
 * - Furniture Listing Management (1.2 Scope/Core System Components/2. Backend Services)
 * - Offline-first Architecture (1.2 Scope/Core System Components/1. Mobile Applications)
 * - AI/ML Infrastructure (1.2 Scope/Core System Components/3. AI/ML Infrastructure)
 */
@Parcelize
data class Furniture(
    val id: String,
    val userId: String,
    val title: String,
    val description: String,
    val category: String,
    val condition: String,
    val dimensions: Map<String, Double>,
    val material: String,
    val isAvailable: Boolean,
    val aiMetadata: Map<String, Any>,
    val location: Location,
    val createdAt: Long,
    val expiresAt: Long
) : Parcelable {

    companion object {
        private val VALID_CATEGORIES = setOf(
            "chair", "table", "sofa", "bed", "storage",
            "desk", "cabinet", "shelf", "dresser", "other"
        )

        private val VALID_CONDITIONS = setOf(
            "new", "like_new", "good", "fair", "needs_repair"
        )

        private val REQUIRED_DIMENSIONS = setOf(
            "length", "width", "height"
        )
    }

    init {
        // Validate required fields are not empty
        require(title.isNotBlank()) { "Title cannot be empty" }
        require(description.isNotBlank()) { "Description cannot be empty" }
        require(material.isNotBlank()) { "Material cannot be empty" }

        // Validate category against predefined categories
        require(category.lowercase() in VALID_CATEGORIES) {
            "Invalid category: $category. Must be one of: ${VALID_CATEGORIES.joinToString()}"
        }

        // Validate condition against predefined conditions
        require(condition.lowercase() in VALID_CONDITIONS) {
            "Invalid condition: $condition. Must be one of: ${VALID_CONDITIONS.joinToString()}"
        }

        // Validate dimensions map contains required measurements
        require(dimensions.keys.containsAll(REQUIRED_DIMENSIONS)) {
            "Dimensions must include all of: ${REQUIRED_DIMENSIONS.joinToString()}"
        }

        // Validate all dimensions are positive
        require(dimensions.all { it.value > 0 }) {
            "All dimensions must be positive values"
        }

        // Validate expiration is after creation
        require(expiresAt > createdAt) {
            "Expiration time must be after creation time"
        }
    }

    /**
     * Checks if the furniture listing has expired.
     * Returns true if current time is past expiresAt, false otherwise.
     */
    fun isExpired(): Boolean {
        val currentTime = System.currentTimeMillis()
        return currentTime > expiresAt
    }

    /**
     * Formats the dimensions map into a human-readable string.
     * Returns formatted dimensions string with appropriate units.
     */
    fun getDimensionsFormatted(): String {
        return buildString {
            append("${dimensions["length"]}cm × ")
            append("${dimensions["width"]}cm × ")
            append("${dimensions["height"]}cm")
            
            // Add additional dimensions if present
            dimensions.forEach { (key, value) ->
                if (key !in REQUIRED_DIMENSIONS) {
                    append(" • $key: ${value}cm")
                }
            }
        }
    }

    /**
     * Creates a copy of the Furniture with optional property modifications.
     * Implements the data class copy function with additional validation.
     */
    fun copy(
        id: String = this.id,
        userId: String = this.userId,
        title: String = this.title,
        description: String = this.description,
        category: String = this.category,
        condition: String = this.condition,
        dimensions: Map<String, Double> = this.dimensions,
        material: String = this.material,
        isAvailable: Boolean = this.isAvailable,
        aiMetadata: Map<String, Any> = this.aiMetadata,
        location: Location = this.location,
        createdAt: Long = this.createdAt,
        expiresAt: Long = this.expiresAt
    ): Furniture {
        // Create new instance with validation
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
            location = location,
            createdAt = createdAt,
            expiresAt = expiresAt
        )
    }

    /**
     * Returns a map of AI-generated metadata with proper type casting.
     * Implements AI/ML Infrastructure requirement for metadata access.
     */
    @Suppress("UNCHECKED_CAST")
    fun getAIMetadataTyped(): Map<String, Any> {
        return mapOf(
            "confidence" to (aiMetadata["confidence"] as? Double ?: 0.0),
            "categories" to (aiMetadata["categories"] as? List<String> ?: emptyList()),
            "tags" to (aiMetadata["tags"] as? List<String> ?: emptyList()),
            "quality_score" to (aiMetadata["quality_score"] as? Double ?: 0.0),
            "damage_detected" to (aiMetadata["damage_detected"] as? Boolean ?: false),
            "style_classification" to (aiMetadata["style_classification"] as? String ?: "unknown")
        )
    }
}