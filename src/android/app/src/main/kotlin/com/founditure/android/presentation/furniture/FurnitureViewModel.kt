/*
 * Human Tasks:
 * 1. Configure proper timeout values for furniture operations in the app-level build.gradle
 * 2. Verify error messages are properly localized in strings.xml
 * 3. Ensure proper Hilt module configuration for dependency injection
 */

package com.founditure.android.presentation.furniture

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.founditure.android.domain.model.Furniture
import com.founditure.android.domain.usecase.furniture.CreateFurnitureUseCase
import com.founditure.android.domain.usecase.furniture.GetFurnitureListUseCase
import com.founditure.android.domain.usecase.furniture.GetFurnitureListUseCase.FurnitureFilter
import com.founditure.android.domain.usecase.furniture.GetFurnitureListUseCase.SortCriteria
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel implementation for managing furniture-related UI state and business logic.
 * 
 * Addresses requirements:
 * - Furniture Listing Management (1.2 Scope/Core System Components/2. Backend Services)
 * - Offline-first Architecture (1.2 Scope/Core System Components/1. Mobile Applications)
 * - Location Services (1.2 Scope/Core System Components/2. Backend Services)
 */
@HiltViewModel
class FurnitureViewModel @Inject constructor(
    private val createFurnitureUseCase: CreateFurnitureUseCase,
    private val getFurnitureListUseCase: GetFurnitureListUseCase
) : ViewModel() {

    // UI State definition
    data class FurnitureUiState(
        val isLoading: Boolean = false,
        val furniture: List<Furniture> = emptyList(),
        val error: String? = null,
        val currentFilter: FurnitureFilter = FurnitureFilter()
    )

    // Private mutable state
    private val _uiState = MutableStateFlow(FurnitureUiState())
    
    // Public immutable state
    val uiState: StateFlow<FurnitureUiState> = _uiState.asStateFlow()

    init {
        // Load initial furniture list with default filter
        loadFurnitureList(_uiState.value.currentFilter)
    }

    /**
     * Creates a new furniture listing.
     * Implements Furniture Listing Management requirement.
     *
     * @param furniture The furniture item to create
     */
    fun createFurniture(furniture: Furniture) {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                
                // Create furniture using use case
                createFurnitureUseCase.execute(furniture)
                
                // Reload furniture list to reflect changes
                loadFurnitureList(_uiState.value.currentFilter)
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to create furniture listing"
                    )
                }
            }
        }
    }

    /**
     * Loads furniture listings with optional filtering.
     * Implements Offline-first Architecture and Location Services requirements.
     *
     * @param filter Filter parameters for furniture list
     */
    fun loadFurnitureList(filter: FurnitureFilter) {
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isLoading = true, error = null) }
                
                // Collect furniture list flow
                getFurnitureListUseCase.execute(filter)
                    .catch { e ->
                        _uiState.update {
                            it.copy(
                                isLoading = false,
                                error = e.message ?: "Failed to load furniture listings"
                            )
                        }
                    }
                    .collect { furnitureList ->
                        _uiState.update {
                            it.copy(
                                isLoading = false,
                                furniture = furnitureList,
                                currentFilter = filter,
                                error = null
                            )
                        }
                    }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load furniture listings"
                    )
                }
            }
        }
    }

    /**
     * Updates the current furniture filter and reloads list.
     * Implements Location Services requirement for location-based filtering.
     *
     * @param newFilter Updated filter parameters
     */
    fun updateFilter(newFilter: FurnitureFilter) {
        viewModelScope.launch {
            try {
                // Update current filter in UI state
                _uiState.update { 
                    it.copy(currentFilter = newFilter, error = null)
                }
                
                // Reload furniture list with new filter
                loadFurnitureList(newFilter)
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        error = e.message ?: "Failed to update filter"
                    )
                }
            }
        }
    }

    /**
     * Clears any error state in the UI.
     */
    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    /**
     * Creates a location-based filter for furniture search.
     * Helper method for implementing Location Services requirement.
     *
     * @param latitude Current latitude
     * @param longitude Current longitude
     * @param radius Search radius in kilometers
     * @param category Optional category filter
     * @param condition Optional condition filter
     * @return FurnitureFilter configured for location-based search
     */
    fun createLocationFilter(
        latitude: Double,
        longitude: Double,
        radius: Double,
        category: String? = null,
        condition: String? = null
    ): FurnitureFilter {
        return FurnitureFilter(
            latitude = latitude,
            longitude = longitude,
            radius = radius,
            category = category,
            condition = condition,
            sortBy = SortCriteria.DISTANCE
        )
    }

    /**
     * Creates a category-based filter for furniture search.
     * Helper method for implementing Furniture Listing Management requirement.
     *
     * @param category Furniture category to filter by
     * @param condition Optional condition filter
     * @return FurnitureFilter configured for category-based search
     */
    fun createCategoryFilter(
        category: String,
        condition: String? = null
    ): FurnitureFilter {
        return FurnitureFilter(
            category = category,
            condition = condition,
            sortBy = SortCriteria.CREATED_AT_DESC
        )
    }
}