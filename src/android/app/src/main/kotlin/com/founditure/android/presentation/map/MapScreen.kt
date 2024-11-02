/*
 * Human Tasks:
 * 1. Ensure Google Maps API key is configured in local.properties
 * 2. Verify location permissions are properly set up in AndroidManifest.xml
 * 3. Test map clustering performance with large datasets
 * 4. Validate map controls accessibility with TalkBack
 */

package com.founditure.android.presentation.map

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.google.maps.android.compose.*
import com.google.maps.android.compose.clustering.Clustering
import com.google.maps.android.compose.clustering.MarkerClusterRenderer
import com.founditure.android.presentation.components.FurnitureCard
import com.founditure.android.presentation.theme.FounditureTheme
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import kotlinx.coroutines.flow.collectLatest

/**
 * Main composable for the map screen showing furniture items on an interactive map.
 * 
 * Requirements addressed:
 * - Location-based Search (1.2 Scope/Included Features)
 * - Map View (6.1.1 Mobile Navigation Structure)
 * - Real-time Updates (3.4 System Interactions)
 *
 * @param navController Navigation controller for screen transitions
 * @param modifier Optional modifier for the composable
 */
@Composable
fun MapScreen(
    navController: NavController,
    modifier: Modifier = Modifier,
    viewModel: MapViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val cameraPositionState = rememberCameraPositionState()
    var isListView by remember { mutableStateOf(false) }

    FounditureTheme {
        Box(modifier = modifier.fillMaxSize()) {
            // Main content based on view mode
            if (isListView) {
                // List view of furniture items
                if (state.furnitureItems.isEmpty()) {
                    // Empty state
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "No furniture items found in this area",
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                } else {
                    // Scrollable list of furniture cards
                    Column(modifier = Modifier.fillMaxSize()) {
                        state.furnitureItems.forEach { furniture ->
                            FurnitureCard(
                                furniture = furniture,
                                onClick = { 
                                    navController.navigate("furniture_detail/${furniture.id}")
                                }
                            )
                        }
                    }
                }
            } else {
                // Map view with clustering
                GoogleMap(
                    modifier = Modifier.fillMaxSize(),
                    cameraPositionState = cameraPositionState,
                    properties = MapProperties(
                        isMyLocationEnabled = true,
                        mapType = MapType.NORMAL
                    ),
                    uiSettings = MapUiSettings(
                        zoomControlsEnabled = true,
                        myLocationButtonEnabled = true,
                        mapToolbarEnabled = false
                    )
                ) {
                    // Clustered markers for furniture items
                    Clustering(
                        items = state.furnitureItems.map { furniture ->
                            ClusterItem(
                                position = LatLng(
                                    furniture.location.latitude,
                                    furniture.location.longitude
                                ),
                                title = furniture.title,
                                snippet = furniture.description,
                                zIndex = 1f
                            )
                        },
                        onClusterClick = { cluster ->
                            // Zoom into cluster
                            val position = CameraPosition.Builder()
                                .target(cluster.position)
                                .zoom(cameraPositionState.position.zoom + 2)
                                .build()
                            cameraPositionState.animate(position)
                            true
                        },
                        onClusterItemClick = { item ->
                            // Find corresponding furniture item
                            state.furnitureItems.find { 
                                it.location.latitude == item.position.latitude &&
                                it.location.longitude == item.position.longitude
                            }?.let { furniture ->
                                navController.navigate("furniture_detail/${furniture.id}")
                            }
                            true
                        },
                        clusterRenderer = MarkerClusterRenderer()
                    )
                }

                // Camera position change listener
                LaunchedEffect(cameraPositionState.position) {
                    viewModel.onMapMoved(
                        newLatitude = cameraPositionState.position.target.latitude,
                        newLongitude = cameraPositionState.position.target.longitude,
                        zoomLevel = cameraPositionState.position.zoom
                    )
                }
            }

            // Map controls overlay
            MapControls(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(16.dp),
                onLocationClick = {
                    // Request current location and move camera
                    state.currentLatitude?.let { lat ->
                        state.currentLongitude?.let { lng ->
                            val position = CameraPosition.Builder()
                                .target(LatLng(lat, lng))
                                .zoom(MapViewModel.DEFAULT_ZOOM)
                                .build()
                            cameraPositionState.animate(position)
                        }
                    }
                },
                onListViewToggle = {
                    isListView = !isListView
                }
            )

            // Loading indicator
            if (state.isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier
                        .align(Alignment.Center)
                        .size(48.dp)
                )
            }

            // Error message
            state.error?.let { error ->
                Snackbar(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(16.dp)
                ) {
                    Text(text = error)
                }
            }
        }
    }
}

/**
 * Composable for map control buttons.
 *
 * @param modifier Optional modifier for the controls
 * @param onLocationClick Callback when location button is clicked
 * @param onListViewToggle Callback when list view toggle is clicked
 */
@Composable
private fun MapControls(
    modifier: Modifier = Modifier,
    onLocationClick: () -> Unit,
    onListViewToggle: () -> Unit
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Location button
        FloatingActionButton(
            onClick = onLocationClick,
            containerColor = MaterialTheme.colorScheme.primaryContainer
        ) {
            Icon(
                imageVector = androidx.compose.material.icons.Icons.Filled.MyLocation,
                contentDescription = "My Location",
                tint = MaterialTheme.colorScheme.onPrimaryContainer
            )
        }

        // List view toggle
        FloatingActionButton(
            onClick = onListViewToggle,
            containerColor = MaterialTheme.colorScheme.primaryContainer
        ) {
            Icon(
                imageVector = androidx.compose.material.icons.Icons.Filled.List,
                contentDescription = "Toggle List View",
                tint = MaterialTheme.colorScheme.onPrimaryContainer
            )
        }
    }
}

/**
 * Data class representing a cluster item for map markers.
 */
private data class ClusterItem(
    val position: LatLng,
    val title: String,
    val snippet: String,
    val zIndex: Float
)