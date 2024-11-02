/*
 * Human Tasks:
 * 1. Ensure location permissions are properly configured in AndroidManifest.xml
 * 2. Configure map API key in local.properties
 * 3. Verify Hilt dependency injection setup in the app module
 */

package com.founditure.android.presentation.map

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.founditure.android.domain.model.Furniture
import com.founditure.android.domain.model.Location
import com.founditure.android.domain.usecase.furniture.GetFurnitureListUseCase
import com.founditure.android.domain.usecase.furniture.GetFurnitureListUseCase.FurnitureFilter
import com.founditure.android.domain.usecase.furniture.GetFurnitureListUseCase.SortCriteria
import com.founditure.android.domain.usecase.location.UpdateLocationUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel implementation for the map screen that handles furniture item locations,
 * map interactions, and location-based search functionality.
 * 
 * Addresses requirements:
 * - Location-based Search (1.2 Scope/Included Features)
 * - Privacy Controls (7.2.3 Privacy Controls)
 * - Real-time Updates (3.4 System Interactions)
 */
@HiltViewModel
class MapViewModel @Inject constructor(
    private val getFurnitureListUseCase: GetFurnitureListUseCase,
    private val updateLocationUseCase: UpdateLocationUseCase
) : ViewModel() {

    // Default zoom level for map view
    companion object {
        const val DEFAULT_ZOOM = 15f
    }

    // Internal mutable state
    private val _state = MutableStateFlow(MapViewState())
    
    // Exposed immutable state
    val state: StateFlow<MapViewState> = _state

    /**
     * Loads furniture items within the specified map area.
     * Implements location-based search requirement.
     *
     * @param latitude Center latitude of search area
     * @param longitude Center longitude of search area
     * @param radius Search radius in kilometers
     */
    fun loadFurnitureInArea(latitude: Double, longitude: Double, radius: Double) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true)

            val filter = FurnitureFilter(
                latitude = latitude,
                longitude = longitude,
                radius = radius,
                sortBy = SortCriteria.DISTANCE
            )

            getFurnitureListUseCase.execute(filter)
                .onEach { furnitureList ->
                    _state.value = _state.value.copy(
                        isLoading = false,
                        furnitureItems = furnitureList,
                        error = null,
                        currentLatitude = latitude,
                        currentLongitude = longitude
                    )
                }
                .catch { error ->
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = error.message ?: "Failed to load furniture items"
                    )
                }
                .launchIn(this)
        }
    }

    /**
     * Updates location for a furniture item with privacy controls.
     * Implements privacy controls requirement.
     *
     * @param furnitureId ID of the furniture item to update
     * @param location New location information
     */
    fun updateFurnitureLocation(furnitureId: String, location: Location) {
        viewModelScope.launch {
            try {
                updateLocationUseCase(
                    java.util.UUID.fromString(furnitureId),
                    location
                ).collect { result ->
                    result.fold(
                        onSuccess = { updatedLocation ->
                            // Refresh furniture list to reflect the update
                            _state.value.currentLatitude?.let { lat ->
                                _state.value.currentLongitude?.let { lng ->
                                    loadFurnitureInArea(
                                        latitude = lat,
                                        longitude = lng,
                                        radius = calculateRadiusFromZoom(_state.value.currentZoom)
                                    )
                                }
                            }
                        },
                        onFailure = { error ->
                            _state.value = _state.value.copy(
                                error = error.message ?: "Failed to update location"
                            )
                        }
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    error = e.message ?: "Failed to update location"
                )
            }
        }
    }

    /**
     * Handles map viewport changes and updates furniture items accordingly.
     * Implements real-time updates requirement.
     *
     * @param newLatitude New center latitude
     * @param newLongitude New center longitude
     * @param zoomLevel New zoom level
     */
    fun onMapMoved(newLatitude: Double, newLongitude: Double, zoomLevel: Float) {
        _state.value = _state.value.copy(
            currentLatitude = newLatitude,
            currentLongitude = newLongitude,
            currentZoom = zoomLevel
        )

        // Calculate visible radius based on zoom level
        val radius = calculateRadiusFromZoom(zoomLevel)
        
        // Load furniture items in the new visible area
        loadFurnitureInArea(newLatitude, newLongitude, radius)
    }

    /**
     * Calculates search radius in kilometers based on map zoom level.
     * Helper function for location-based search.
     *
     * @param zoomLevel Current map zoom level
     * @return Search radius in kilometers
     */
    private fun calculateRadiusFromZoom(zoomLevel: Float): Double {
        // Approximate radius calculation based on zoom level
        // At zoom level 15 (default), radius is about 2.5km
        // Each zoom level doubles/halves the visible area
        return 2.5 * Math.pow(2.0, (15 - zoomLevel))
    }
}

/**
 * Data class representing the UI state for the map screen.
 * Implements state management for map view.
 */
data class MapViewState(
    val isLoading: Boolean = false,
    val furnitureItems: List<Furniture> = emptyList(),
    val error: String? = null,
    val currentLatitude: Double? = null,
    val currentLongitude: Double? = null,
    val currentZoom: Float = DEFAULT_ZOOM
)