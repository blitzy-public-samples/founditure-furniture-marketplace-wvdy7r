/*
 * Human Tasks:
 * 1. Verify proper image loading configuration in app-level build.gradle for Coil
 * 2. Ensure proper permissions are declared in AndroidManifest.xml for location access
 * 3. Test deep linking configuration for furniture detail screen navigation
 */

package com.founditure.android.presentation.furniture

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.google.accompanist.pager.ExperimentalPagerApi
import com.google.accompanist.pager.HorizontalPager
import com.google.accompanist.pager.HorizontalPagerIndicator
import com.google.accompanist.pager.rememberPagerState
import com.founditure.android.domain.model.Furniture
import com.founditure.android.presentation.theme.FounditureTheme

/**
 * Main composable function that renders the furniture detail screen.
 * 
 * Requirements addressed:
 * - Furniture Listing Management: Detailed view of furniture listings
 * - Location Services: Integration of location information display
 * - Mobile Applications: Native Android UI implementation
 *
 * @param navController Navigation controller for screen navigation
 * @param furnitureId ID of the furniture item to display
 */
@Composable
fun FurnitureDetailScreen(
    navController: NavController,
    furnitureId: String,
    viewModel: FurnitureViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    // Find the specific furniture item
    val furniture = uiState.furniture.find { it.id == furnitureId }
    
    Scaffold(
        topBar = {
            SmallTopAppBar(
                title = { Text("Furniture Details") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "Navigate back"
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                uiState.isLoading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                uiState.error != null -> {
                    ErrorMessage(
                        message = uiState.error!!,
                        onRetry = { viewModel.clearError() }
                    )
                }
                furniture != null -> {
                    FurnitureDetailContent(
                        furniture = furniture,
                        modifier = Modifier.fillMaxSize()
                    )
                }
                else -> {
                    Text(
                        text = "Furniture not found",
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
            }
        }
    }
}

/**
 * Composable function that renders the main content of the furniture detail screen.
 *
 * @param furniture Furniture item to display
 * @param modifier Modifier for the content
 */
@Composable
private fun FurnitureDetailContent(
    furniture: Furniture,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        // Image carousel
        FurnitureImagePager(
            imageUrls = furniture.aiMetadata["images"] as? List<String> ?: emptyList(),
            modifier = Modifier
                .fillMaxWidth()
                .height(300.dp)
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Title and category
        Text(
            text = furniture.title,
            style = MaterialTheme.typography.headlineMedium
        )
        
        Text(
            text = furniture.category.capitalize(),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.secondary
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Condition and material
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Text(
                    text = "Condition",
                    style = MaterialTheme.typography.labelLarge
                )
                Text(
                    text = furniture.condition.replace("_", " ").capitalize(),
                    style = MaterialTheme.typography.bodyMedium
                )
            }
            Column {
                Text(
                    text = "Material",
                    style = MaterialTheme.typography.labelLarge
                )
                Text(
                    text = furniture.material,
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Dimensions
        Text(
            text = "Dimensions",
            style = MaterialTheme.typography.labelLarge
        )
        Text(
            text = furniture.getDimensionsFormatted(),
            style = MaterialTheme.typography.bodyMedium
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Location information
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "Location",
                    style = MaterialTheme.typography.titleMedium
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = furniture.location.address,
                    style = MaterialTheme.typography.bodyMedium
                )
                // Map preview would be implemented here
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Description
        Text(
            text = "Description",
            style = MaterialTheme.typography.labelLarge
        )
        Text(
            text = furniture.description,
            style = MaterialTheme.typography.bodyMedium
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Availability status
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = if (furniture.isAvailable) 
                    MaterialTheme.colorScheme.primaryContainer
                else 
                    MaterialTheme.colorScheme.errorContainer
            )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = if (furniture.isAvailable) "Available" else "Not Available",
                    style = MaterialTheme.typography.titleMedium
                )
                Text(
                    text = "Expires: ${formatDate(furniture.expiresAt)}",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    }
}

/**
 * Composable function for displaying furniture images in a horizontal pager.
 *
 * @param imageUrls List of image URLs to display
 * @param modifier Modifier for the pager
 */
@OptIn(ExperimentalPagerApi::class)
@Composable
private fun FurnitureImagePager(
    imageUrls: List<String>,
    modifier: Modifier = Modifier
) {
    if (imageUrls.isEmpty()) {
        Box(
            modifier = modifier,
            contentAlignment = Alignment.Center
        ) {
            Text("No images available")
        }
        return
    }

    val pagerState = rememberPagerState()
    
    Box(modifier = modifier) {
        HorizontalPager(
            count = imageUrls.size,
            state = pagerState,
            modifier = Modifier.fillMaxSize()
        ) { page ->
            AsyncImage(
                model = ImageRequest.Builder(LocalContext.current)
                    .data(imageUrls[page])
                    .crossfade(true)
                    .build(),
                contentDescription = "Furniture image ${page + 1}",
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
        }
        
        // Page indicator
        HorizontalPagerIndicator(
            pagerState = pagerState,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(16.dp),
            activeColor = MaterialTheme.colorScheme.primary,
            inactiveColor = MaterialTheme.colorScheme.surfaceVariant
        )
    }
}

/**
 * Preview composable for the furniture detail screen.
 */
@Preview(showBackground = true)
@Composable
private fun FurnitureDetailPreview() {
    val sampleFurniture = Furniture(
        id = "sample-id",
        userId = "user-id",
        title = "Vintage Wooden Chair",
        description = "Beautiful vintage wooden chair in excellent condition",
        category = "chair",
        condition = "good",
        dimensions = mapOf(
            "length" to 45.0,
            "width" to 45.0,
            "height" to 90.0
        ),
        material = "Solid Oak",
        isAvailable = true,
        aiMetadata = mapOf(
            "images" to listOf(
                "https://example.com/image1.jpg",
                "https://example.com/image2.jpg"
            )
        ),
        location = Location(
            latitude = 37.7749,
            longitude = -122.4194,
            address = "123 Sample St, San Francisco, CA"
        ),
        createdAt = System.currentTimeMillis(),
        expiresAt = System.currentTimeMillis() + (7 * 24 * 60 * 60 * 1000) // 7 days
    )
    
    FounditureTheme {
        FurnitureDetailContent(furniture = sampleFurniture)
    }
}

/**
 * Error message composable for displaying error states.
 */
@Composable
private fun ErrorMessage(
    message: String,
    onRetry: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
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
 * Helper function to format timestamps into readable dates.
 */
private fun formatDate(timestamp: Long): String {
    val date = java.text.SimpleDateFormat("MMM dd, yyyy", java.util.Locale.getDefault())
    return date.format(java.util.Date(timestamp))
}