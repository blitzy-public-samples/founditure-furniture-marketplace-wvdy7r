/*
 * Human Tasks:
 * 1. Verify proper Hilt module configuration for ViewModel injection
 * 2. Ensure proper theme configuration in the app's theme.xml
 * 3. Validate accessibility features with TalkBack
 * 4. Test pull-to-refresh behavior across different Android versions
 */

package com.founditure.android.presentation.furniture

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Sort
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.founditure.android.domain.usecase.furniture.GetFurnitureListUseCase.FurnitureFilter
import com.founditure.android.domain.usecase.furniture.GetFurnitureListUseCase.SortCriteria
import com.founditure.android.presentation.components.FurnitureCard
import com.founditure.android.presentation.navigation.Screen
import com.google.accompanist.swiperefresh.SwipeRefresh
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState

/**
 * Main composable function that renders the furniture list screen.
 * 
 * Requirements addressed:
 * - Furniture documentation and discovery (1.2 Scope/Included Features)
 * - Location-based search (1.2 Scope/Included Features)
 * - Mobile-first platform (1.1 System Overview)
 *
 * @param navController Navigation controller for screen transitions
 * @param modifier Optional modifier for the screen
 */
@Composable
fun FurnitureListScreen(
    navController: NavController,
    modifier: Modifier = Modifier,
    viewModel: FurnitureViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val swipeRefreshState = rememberSwipeRefreshState(uiState.isLoading)
    var showFilterDialog by remember { mutableStateOf(false) }
    var showSortDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Discover Furniture") },
                actions = {
                    // Sort action
                    IconButton(onClick = { showSortDialog = true }) {
                        Icon(
                            imageVector = Icons.Default.Sort,
                            contentDescription = "Sort furniture"
                        )
                    }
                    // Filter action
                    IconButton(onClick = { showFilterDialog = true }) {
                        Icon(
                            imageVector = Icons.Default.FilterList,
                            contentDescription = "Filter furniture"
                        )
                    }
                }
            )
        },
        modifier = modifier
    ) { paddingValues ->
        SwipeRefresh(
            state = swipeRefreshState,
            onRefresh = { viewModel.loadFurnitureList(uiState.currentFilter) },
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            Box(modifier = Modifier.fillMaxSize()) {
                when {
                    uiState.isLoading && uiState.furniture.isEmpty() -> {
                        CircularProgressIndicator(
                            modifier = Modifier.align(Alignment.Center)
                        )
                    }
                    uiState.error != null -> {
                        ErrorMessage(
                            message = uiState.error!!,
                            onRetry = { viewModel.loadFurnitureList(uiState.currentFilter) },
                            modifier = Modifier.align(Alignment.Center)
                        )
                    }
                    uiState.furniture.isEmpty() -> {
                        EmptyState(
                            modifier = Modifier.align(Alignment.Center)
                        )
                    }
                    else -> {
                        FurnitureListContent(
                            furniture = uiState.furniture,
                            onItemClick = { furniture ->
                                navController.navigate(
                                    Screen.FurnitureDetail.createRoute(furniture.id)
                                )
                            }
                        )
                    }
                }
            }
        }

        // Filter Dialog
        if (showFilterDialog) {
            FurnitureFilterBar(
                viewModel = viewModel,
                currentFilter = uiState.currentFilter,
                onDismiss = { showFilterDialog = false },
                onApply = { filter ->
                    viewModel.updateFilter(filter)
                    showFilterDialog = false
                }
            )
        }

        // Sort Dialog
        if (showSortDialog) {
            SortDialog(
                currentSort = uiState.currentFilter.sortBy,
                onDismiss = { showSortDialog = false },
                onSortSelected = { sortCriteria ->
                    viewModel.updateFilter(
                        uiState.currentFilter.copy(sortBy = sortCriteria)
                    )
                    showSortDialog = false
                }
            )
        }
    }
}

/**
 * Composable function that renders the filtering options.
 *
 * @param viewModel ViewModel instance for state management
 * @param currentFilter Current filter state
 * @param onDismiss Callback when dialog is dismissed
 * @param onApply Callback when filter is applied
 */
@Composable
private fun FurnitureFilterBar(
    viewModel: FurnitureViewModel,
    currentFilter: FurnitureFilter,
    onDismiss: () -> Unit,
    onApply: (FurnitureFilter) -> Unit
) {
    var category by remember { mutableStateOf(currentFilter.category) }
    var condition by remember { mutableStateOf(currentFilter.condition) }
    var radius by remember { mutableStateOf(currentFilter.radius ?: 10.0) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Filter Furniture") },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Category Filter
                OutlinedTextField(
                    value = category ?: "",
                    onValueChange = { category = it.takeIf { it.isNotEmpty() } },
                    label = { Text("Category") },
                    modifier = Modifier.fillMaxWidth()
                )

                // Condition Filter
                OutlinedTextField(
                    value = condition ?: "",
                    onValueChange = { condition = it.takeIf { it.isNotEmpty() } },
                    label = { Text("Condition") },
                    modifier = Modifier.fillMaxWidth()
                )

                // Distance Filter
                Text("Search Radius (km)", style = MaterialTheme.typography.bodyMedium)
                Slider(
                    value = radius.toFloat(),
                    onValueChange = { radius = it.toDouble() },
                    valueRange = 1f..50f,
                    steps = 49
                )
                Text("${radius.toInt()} km")
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onApply(
                        currentFilter.copy(
                            category = category,
                            condition = condition,
                            radius = radius
                        )
                    )
                }
            ) {
                Text("Apply")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

/**
 * Composable function that renders the sort options dialog.
 *
 * @param currentSort Current sort criteria
 * @param onDismiss Callback when dialog is dismissed
 * @param onSortSelected Callback when sort option is selected
 */
@Composable
private fun SortDialog(
    currentSort: SortCriteria,
    onDismiss: () -> Unit,
    onSortSelected: (SortCriteria) -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Sort By") },
        text = {
            Column {
                SortCriteria.values().forEach { criteria ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = criteria == currentSort,
                            onClick = { onSortSelected(criteria) }
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = when (criteria) {
                                SortCriteria.CREATED_AT_DESC -> "Newest First"
                                SortCriteria.CREATED_AT_ASC -> "Oldest First"
                                SortCriteria.DISTANCE -> "Distance"
                            }
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Close")
            }
        }
    )
}

/**
 * Composable function that renders the list of furniture items.
 *
 * @param furniture List of furniture items to display
 * @param onItemClick Callback when an item is clicked
 */
@Composable
private fun FurnitureListContent(
    furniture: List<com.founditure.android.domain.model.Furniture>,
    onItemClick: (com.founditure.android.domain.model.Furniture) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        items(
            items = furniture,
            key = { it.id }
        ) { item ->
            FurnitureCard(
                furniture = item,
                onClick = onItemClick
            )
        }
    }
}

/**
 * Composable function that renders an error message with retry option.
 *
 * @param message Error message to display
 * @param onRetry Callback when retry is clicked
 */
@Composable
private fun ErrorMessage(
    message: String,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.error
        )
        Spacer(modifier = Modifier.height(8.dp))
        Button(onClick = onRetry) {
            Text("Retry")
        }
    }
}

/**
 * Composable function that renders an empty state message.
 */
@Composable
private fun EmptyState(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "No furniture items found",
            style = MaterialTheme.typography.bodyLarge
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Try adjusting your filters or check back later",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}