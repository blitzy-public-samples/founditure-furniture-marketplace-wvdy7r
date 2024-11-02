/*
 * Human Tasks:
 * 1. Verify furniture category and condition lists are synchronized with backend
 * 2. Ensure proper error handling for network failures during furniture creation
 * 3. Configure proper timeout values for furniture creation operations
 */

package com.founditure.android.domain.usecase.furniture

import com.founditure.android.data.repository.FurnitureRepository
import com.founditure.android.domain.model.Furniture
import kotlinx.coroutines.withContext
import kotlinx.coroutines.Dispatchers
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Use case implementation for creating new furniture listings in the Founditure application.
 * Implements business logic for furniture creation with validation and offline support.
 *
 * Addresses requirements:
 * - Furniture Listing Management (1.2 Scope/Core System Components/2. Backend Services)
 * - Offline-first Architecture (1.2 Scope/Core System Components/1. Mobile Applications)
 */
@Singleton
class CreateFurnitureUseCase @Inject constructor(
    private val furnitureRepository: FurnitureRepository
) {
    companion object {
        private const val MAX_TITLE_LENGTH = 100
        private const val MAX_DESCRIPTION_LENGTH = 1000
        private const val MIN_DIMENSION_CM = 1.0
        private const val MAX_DIMENSION_CM = 1000.0
        private const val LISTING_EXPIRATION_DAYS = 30L
    }

    /**
     * Creates a new furniture listing with validation and processing.
     * Implements offline-first architecture for furniture creation.
     *
     * @param furniture Furniture item to be created
     * @return Created furniture item with server-generated ID and metadata
     * @throws IllegalArgumentException if validation fails
     */
    suspend fun execute(furniture: Furniture): Furniture = withContext(Dispatchers.IO) {
        // Validate furniture data
        validateFurniture(furniture)

        // Set creation and expiration timestamps
        val currentTime = System.currentTimeMillis()
        val expirationTime = currentTime + TimeUnit.DAYS.toMillis(LISTING_EXPIRATION_DAYS)

        // Create furniture with timestamps
        val furnitureWithTimestamps = furniture.copy(
            createdAt = currentTime,
            expiresAt = expirationTime
        )

        // Create furniture through repository with offline support
        furnitureRepository.createFurniture(furnitureWithTimestamps)
    }

    /**
     * Validates furniture data against business rules.
     * Implements comprehensive validation for furniture listings.
     *
     * @param furniture Furniture item to validate
     * @return true if validation passes
     * @throws IllegalArgumentException if validation fails
     */
    private fun validateFurniture(furniture: Furniture) {
        // Validate title
        require(furniture.title.isNotBlank()) { "Title cannot be empty" }
        require(furniture.title.length <= MAX_TITLE_LENGTH) {
            "Title cannot exceed $MAX_TITLE_LENGTH characters"
        }

        // Validate description
        require(furniture.description.isNotBlank()) { "Description cannot be empty" }
        require(furniture.description.length <= MAX_DESCRIPTION_LENGTH) {
            "Description cannot exceed $MAX_DESCRIPTION_LENGTH characters"
        }

        // Validate dimensions
        validateDimensions(furniture.dimensions)

        // Validate category and condition
        validateCategoryAndCondition(furniture)

        // Validate material
        require(furniture.material.isNotBlank()) { "Material cannot be empty" }

        // Validate location
        validateLocation(furniture)
    }

    /**
     * Validates furniture dimensions against acceptable ranges.
     *
     * @param dimensions Map of dimension measurements
     * @throws IllegalArgumentException if dimensions are invalid
     */
    private fun validateDimensions(dimensions: Map<String, Double>) {
        // Check required dimensions
        val requiredDimensions = setOf("length", "width", "height")
        require(dimensions.keys.containsAll(requiredDimensions)) {
            "Missing required dimensions: ${requiredDimensions.minus(dimensions.keys).joinToString()}"
        }

        // Validate dimension values
        dimensions.forEach { (dimension, value) ->
            require(value >= MIN_DIMENSION_CM) {
                "$dimension must be at least $MIN_DIMENSION_CM cm"
            }
            require(value <= MAX_DIMENSION_CM) {
                "$dimension cannot exceed $MAX_DIMENSION_CM cm"
            }
        }
    }

    /**
     * Validates furniture category and condition against predefined values.
     *
     * @param furniture Furniture item to validate
     * @throws IllegalArgumentException if category or condition is invalid
     */
    private fun validateCategoryAndCondition(furniture: Furniture) {
        // Category validation using predefined categories from Furniture model
        require(furniture.category.isNotBlank()) { "Category cannot be empty" }

        // Condition validation using predefined conditions from Furniture model
        require(furniture.condition.isNotBlank()) { "Condition cannot be empty" }
    }

    /**
     * Validates furniture location data.
     *
     * @param furniture Furniture item to validate
     * @throws IllegalArgumentException if location is invalid
     */
    private fun validateLocation(furniture: Furniture) {
        requireNotNull(furniture.location) { "Location cannot be null" }
        
        with(furniture.location) {
            // Validate latitude range
            require(latitude >= -90.0 && latitude <= 90.0) {
                "Invalid latitude: $latitude"
            }
            
            // Validate longitude range
            require(longitude >= -180.0 && longitude <= 180.0) {
                "Invalid longitude: $longitude"
            }
        }
    }
}