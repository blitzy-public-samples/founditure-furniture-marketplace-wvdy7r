/*
 * Human Tasks:
 * 1. Add Google Maps API key to local.properties or appropriate secrets management
 * 2. Verify location permissions in AndroidManifest.xml:
 *    - android.permission.ACCESS_FINE_LOCATION
 *    - android.permission.ACCESS_COARSE_LOCATION
 * 3. Configure Google Maps styling in res/raw/map_style.json
 */

package com.founditure.android.presentation.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.founditure.android.domain.model.Location
import com.founditure.android.domain.model.Location.PrivacyLevel
import com.founditure.android.util.LocationUtils
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.*
import kotlinx.coroutines.launch
import java.util.*

/**
 * State holder class for the LocationPicker component.
 * Implements requirements:
 * - Location Services (1.2 Scope/Core System Components/1. Mobile Applications)
 * - Privacy Controls (7.2.3 Privacy Controls)
 */
class LocationPickerState(
    initialLocation: Location? = null,
    initialPrivacyLevel: PrivacyLevel = PrivacyLevel.APPROXIMATE
) {
    var selectedLocation by mutableStateOf(initialLocation)
        private set
    
    var privacyLevel by mutableStateOf(initialPrivacyLevel)
        private set
    
    var isPickerVisible by mutableStateOf(false)
        private set

    /**
     * Updates the selected location if valid
     */
    fun updateLocation(location: Location) {
        if (LocationUtils.isLocationValid(location)) {
            selectedLocation = location
            isPickerVisible = false
        }
    }

    /**
     * Updates privacy level and applies to current location
     */
    fun updatePrivacyLevel(level: PrivacyLevel) {
        privacyLevel = level
        selectedLocation?.let { location ->
            selectedLocation = location.copy(privacyLevel = level)
        }
    }
}

/**
 * Composable function that renders the location picker UI.
 * Implements requirements:
 * - Location Services (1.2 Scope/Core System Components/1. Mobile Applications)
 * - Privacy Controls (7.2.3 Privacy Controls)
 */
@Composable
fun LocationPicker(
    state: LocationPickerState,
    onLocationSelected: (Location) -> Unit,
    onPrivacyLevelChanged: (PrivacyLevel) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    
    val mapProperties by remember {
        mutableStateOf(
            MapProperties(
                isMyLocationEnabled = true,
                mapType = MapType.NORMAL
            )
        )
    }
    
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(
            state.selectedLocation?.let { 
                LatLng(it.latitude, it.longitude)
            } ?: LatLng(0.0, 0.0),
            15f
        )
    }

    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Map view
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(300.dp)
        ) {
            GoogleMap(
                modifier = Modifier.fillMaxSize(),
                properties = mapProperties,
                cameraPositionState = cameraPositionState,
                onMapClick = { latLng ->
                    coroutineScope.launch {
                        val newLocation = Location(
                            id = UUID.randomUUID(),
                            furnitureId = UUID.randomUUID(), // Temporary ID
                            latitude = latLng.latitude,
                            longitude = latLng.longitude,
                            address = "", // Will be reverse geocoded
                            privacyLevel = state.privacyLevel,
                            recordedAt = System.currentTimeMillis()
                        )
                        state.updateLocation(newLocation)
                        onLocationSelected(newLocation)
                    }
                }
            ) {
                // Show marker for selected location
                state.selectedLocation?.let { location ->
                    val displayCoords = location.getDisplayCoordinates()
                    Marker(
                        state = MarkerState(
                            position = LatLng(
                                displayCoords.first,
                                displayCoords.second
                            )
                        ),
                        title = location.getDisplayAddress()
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Privacy level selector
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
        ) {
            Text(
                text = "Location Privacy",
                style = MaterialTheme.typography.titleMedium
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            PrivacyLevelSelector(
                selectedLevel = state.privacyLevel,
                onLevelSelected = { level ->
                    state.updatePrivacyLevel(level)
                    onPrivacyLevelChanged(level)
                }
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Location info display
        state.selectedLocation?.let { location ->
            LocationInfoCard(
                location = location,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
            )
        }
    }
}

@Composable
private fun PrivacyLevelSelector(
    selectedLevel: PrivacyLevel,
    onLevelSelected: (PrivacyLevel) -> Unit
) {
    Column {
        PrivacyLevel.values().forEach { level ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                RadioButton(
                    selected = level == selectedLevel,
                    onClick = { onLevelSelected(level) }
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = when (level) {
                        PrivacyLevel.EXACT -> "Exact Location"
                        PrivacyLevel.APPROXIMATE -> "Approximate Area"
                        PrivacyLevel.AREA_ONLY -> "General Area Only"
                        PrivacyLevel.HIDDEN -> "Hidden Location"
                    }
                )
            }
        }
    }
}

@Composable
private fun LocationInfoCard(
    location: Location,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = "Selected Location",
                style = MaterialTheme.typography.titleMedium
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = location.getDisplayAddress().ifEmpty { "Address not available" },
                style = MaterialTheme.typography.bodyMedium
            )
            if (location.privacyLevel == PrivacyLevel.EXACT) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Coordinates: ${location.latitude}, ${location.longitude}",
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}

/**
 * Composable function that creates and remembers LocationPickerState.
 */
@Composable
fun rememberLocationPickerState(
    initialLocation: Location? = null,
    initialPrivacyLevel: PrivacyLevel = PrivacyLevel.APPROXIMATE
): LocationPickerState {
    return remember {
        LocationPickerState(
            initialLocation = initialLocation,
            initialPrivacyLevel = initialPrivacyLevel
        )
    }
}