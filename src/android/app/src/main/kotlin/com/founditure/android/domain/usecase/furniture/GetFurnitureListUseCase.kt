package com.founditure.android.domain.usecase.furniture

import com.founditure.android.data.repository.FurnitureRepository
import com.founditure.android.domain.model.Furniture
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Use case implementation for retrieving a list of furniture items with filtering and sorting capabilities.
 * 
 * Addresses requirements:
 * - Furniture Listing Management (1.2 Scope/Core System Components/2. Backend Services)
 * - Offline-first Architecture (1.2 Scope/Core System Components/1. Mobile Applications)
 * - Location Services (1.2 Scope/Core System Components/2. Backend Services)
 */
@Singleton
class GetFurnitureListUseCase @Inject constructor(
    private val furnitureRepository: FurnitureRepository
) {
    /**
     * Data class representing filter parameters for furniture list retrieval
     */
    data class FurnitureFilter(
        val category: String? = null,
        val condition: String? = null,
        val latitude: Double? = null,
        val longitude: Double? = null,
        val radius: Double? = null,
        val sortBy: SortCriteria = SortCriteria.CREATED_AT_DESC
    )

    /**
     * Enum class defining available sorting criteria for furniture listings
     */
    enum class SortCriteria {
        CREATED_AT_DESC,
        DISTANCE,
        TITLE_ASC
    }

    /**
     * Retrieves a list of furniture items based on provided filter parameters.
     * Implements offline-first architecture and location-based search capabilities.
     *
     * @param filter Filter parameters for furniture list retrieval
     * @return Flow emitting filtered and sorted list of furniture items
     */
    fun execute(filter: FurnitureFilter): Flow<List<Furniture>> {
        // Check if location-based search is requested
        return if (filter.latitude != null && filter.longitude != null && filter.radius != null) {
            // Use location-based search
            furnitureRepository.searchFurnitureNearLocation(
                latitude = filter.latitude,
                longitude = filter.longitude,
                radius = filter.radius
            ).map { furnitureList ->
                applyFilters(furnitureList, filter)
            }
        } else {
            // Use regular search
            furnitureRepository.getAllFurniture().map { furnitureList ->
                applyFilters(furnitureList, filter)
            }
        }
    }

    /**
     * Applies category, condition filters and sorting to the furniture list
     *
     * @param furnitureList Original list of furniture items
     * @param filter Filter parameters to apply
     * @return Filtered and sorted list of furniture items
     */
    private fun applyFilters(
        furnitureList: List<Furniture>,
        filter: FurnitureFilter
    ): List<Furniture> {
        var filteredList = furnitureList

        // Apply category filter if specified
        filter.category?.let { category ->
            filteredList = filteredList.filter { 
                it.category.equals(category, ignoreCase = true)
            }
        }

        // Apply condition filter if specified
        filter.condition?.let { condition ->
            filteredList = filteredList.filter {
                it.condition.equals(condition, ignoreCase = true)
            }
        }

        // Filter out unavailable items
        filteredList = filteredList.filter { it.isAvailable }

        // Apply sorting based on criteria
        filteredList = when (filter.sortBy) {
            SortCriteria.CREATED_AT_DESC -> {
                filteredList.sortedByDescending { it.createdAt }
            }
            SortCriteria.DISTANCE -> {
                if (filter.latitude != null && filter.longitude != null) {
                    filteredList.sortedBy { furniture ->
                        calculateDistance(
                            filter.latitude,
                            filter.longitude,
                            furniture.location.latitude,
                            furniture.location.longitude
                        )
                    }
                } else {
                    filteredList
                }
            }
            SortCriteria.TITLE_ASC -> {
                filteredList.sortedBy { it.title }
            }
        }

        return filteredList
    }

    /**
     * Calculates the distance between two geographic coordinates using the Haversine formula
     *
     * @param lat1 First latitude
     * @param lon1 First longitude
     * @param lat2 Second latitude
     * @param lon2 Second longitude
     * @return Distance in kilometers
     */
    private fun calculateDistance(
        lat1: Double,
        lon1: Double,
        lat2: Double,
        lon2: Double
    ): Double {
        val r = 6371.0 // Earth's radius in kilometers
        val lat1Rad = Math.toRadians(lat1)
        val lat2Rad = Math.toRadians(lat2)
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)

        val a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2)

        val c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

        return r * c
    }
}