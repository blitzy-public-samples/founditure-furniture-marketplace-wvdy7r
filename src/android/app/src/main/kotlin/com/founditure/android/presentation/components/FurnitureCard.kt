// androidx.compose.material3:material3:1.1.0
// androidx.compose.foundation:foundation:1.5.0
// coil-compose:2.4.0

package com.founditure.android.presentation.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.founditure.android.domain.model.Furniture
import com.founditure.android.presentation.theme.FounditureTheme

/*
 * HUMAN TASKS:
 * 1. Verify image loading placeholder assets are available in the resources
 * 2. Ensure content descriptions are properly localized
 * 3. Validate accessibility features with TalkBack
 * 4. Test card appearance across different screen sizes
 */

/**
 * A composable function that renders a furniture item in a material design card format.
 * 
 * Requirements addressed:
 * - Mobile Applications: Native Android application with modern UI components
 * - UI Components: Card-based listings in the mobile interface
 *
 * @param furniture The furniture item to display
 * @param modifier Optional modifier for the card
 * @param onClick Callback when the card is clicked
 */
@Composable
fun FurnitureCard(
    furniture: Furniture,
    modifier: Modifier = Modifier,
    onClick: (Furniture) -> Unit
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = MaterialTheme.shapes.medium,
        onClick = { onClick(furniture) }
    ) {
        Column {
            // Furniture image
            AsyncImage(
                model = furniture.aiMetadata["imageUrl"] as? String,
                contentDescription = furniture.title,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp),
                contentScale = ContentScale.Crop
            )

            // Furniture details
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                // Title and condition
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = furniture.title,
                        style = MaterialTheme.typography.titleLarge,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f)
                    )
                    
                    // Availability indicator
                    if (furniture.isAvailable) {
                        Surface(
                            color = MaterialTheme.colorScheme.primaryContainer,
                            shape = MaterialTheme.shapes.small
                        ) {
                            Text(
                                text = "Available",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onPrimaryContainer,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Category and condition
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = furniture.category.replaceFirstChar { it.uppercase() },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "•",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = furniture.condition.replace('_', ' ')
                            .replaceFirstChar { it.uppercase() },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Location
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = androidx.compose.material.icons.Icons.Filled.LocationOn,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = furniture.location.address,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                // Dimensions
                if (furniture.dimensions.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = furniture.getDimensionsFormatted(),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

/**
 * Preview function for the FurnitureCard component in Android Studio.
 * 
 * Requirements addressed:
 * - Mobile Applications: Native Android application with modern UI components
 * - UI Components: Card-based listings in the mobile interface
 */
@Preview(showBackground = true)
@Composable
fun FurnitureCardPreview() {
    val sampleFurniture = Furniture(
        id = "1",
        userId = "user1",
        title = "Vintage Wooden Chair",
        description = "Beautiful vintage wooden chair in excellent condition",
        category = "chair",
        condition = "good",
        dimensions = mapOf(
            "length" to 45.0,
            "width" to 45.0,
            "height" to 90.0
        ),
        material = "wood",
        isAvailable = true,
        aiMetadata = mapOf(
            "imageUrl" to "https://example.com/chair.jpg",
            "confidence" to 0.95,
            "categories" to listOf("chair", "vintage", "wooden")
        ),
        location = Location(
            latitude = 37.7749,
            longitude = -122.4194,
            address = "San Francisco, CA"
        ),
        createdAt = System.currentTimeMillis(),
        expiresAt = System.currentTimeMillis() + (7 * 24 * 60 * 60 * 1000) // 7 days
    )

    FounditureTheme {
        FurnitureCard(
            furniture = sampleFurniture,
            onClick = {}
        )
    }
}