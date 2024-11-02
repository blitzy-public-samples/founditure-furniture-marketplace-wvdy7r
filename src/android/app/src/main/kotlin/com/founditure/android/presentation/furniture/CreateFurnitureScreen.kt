/*
 * Human Tasks:
 * 1. Configure Google Maps API key in local.properties
 * 2. Verify camera and location permissions in AndroidManifest.xml
 * 3. Set up proper file provider paths in res/xml/file_paths.xml
 * 4. Configure ProGuard rules for Coil image loading library
 * 5. Ensure proper Hilt module configuration for dependency injection
 */

package com.founditure.android.presentation.furniture

import android.net.Uri
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.founditure.android.domain.model.Furniture
import com.founditure.android.domain.model.Location
import com.founditure.android.domain.model.Location.PrivacyLevel
import com.founditure.android.presentation.components.ImagePicker
import com.founditure.android.presentation.components.LocationPicker
import com.founditure.android.presentation.components.rememberImagePickerState
import com.founditure.android.presentation.components.rememberLocationPickerState
import java.util.*
import kotlinx.coroutines.launch

/**
 * Main composable function for the furniture creation screen.
 * Implements requirements:
 * - Furniture documentation and discovery (1.2 Scope/Included Features)
 * - Location-based search (1.2 Scope/Included Features)
 * - Privacy controls (1.2 Scope/Included Features)
 */
@Composable
fun CreateFurnitureScreen(
    navController: NavController,
    modifier: Modifier = Modifier,
    viewModel: FurnitureViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val scrollState = rememberScrollState()
    val snackbarHostState = remember { SnackbarHostState() }
    
    // Form state
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var category by remember { mutableStateOf("") }
    var condition by remember { mutableStateOf("") }
    var material by remember { mutableStateOf("") }
    var dimensions by remember { mutableStateOf(mapOf(
        "length" to 0.0,
        "width" to 0.0,
        "height" to 0.0
    )) }
    
    // Component states
    val imagePickerState = rememberImagePickerState()
    val locationPickerState = rememberLocationPickerState()
    val uiState by viewModel.uiState.collectAsState()
    
    // Validation state
    var hasValidationErrors by remember { mutableStateOf(false) }
    var validationMessages by remember { mutableStateOf(listOf<String>()) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Create Furniture Listing") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(
                            imageVector = androidx.compose.material.icons.Icons.Default.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(scrollState)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Title input
            OutlinedTextField(
                value = title,
                onValueChange = { title = it },
                label = { Text("Title") },
                modifier = Modifier.fillMaxWidth(),
                isError = hasValidationErrors && title.isBlank(),
                keyboardOptions = KeyboardOptions(
                    imeAction = ImeAction.Next
                )
            )

            // Description input
            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                label = { Text("Description") },
                modifier = Modifier.fillMaxWidth(),
                isError = hasValidationErrors && description.isBlank(),
                minLines = 3,
                maxLines = 5,
                keyboardOptions = KeyboardOptions(
                    imeAction = ImeAction.Next
                )
            )

            // Category dropdown
            ExposedDropdownMenuBox(
                expanded = false,
                onExpandedChange = { },
                modifier = Modifier.fillMaxWidth()
            ) {
                OutlinedTextField(
                    value = category,
                    onValueChange = { },
                    label = { Text("Category") },
                    readOnly = true,
                    modifier = Modifier.fillMaxWidth(),
                    isError = hasValidationErrors && category.isBlank()
                )
                DropdownMenu(
                    expanded = false,
                    onDismissRequest = { }
                ) {
                    listOf("chair", "table", "sofa", "bed", "storage", "desk", "cabinet", "shelf", "dresser", "other").forEach { option ->
                        DropdownMenuItem(
                            text = { Text(option.capitalize()) },
                            onClick = { category = option }
                        )
                    }
                }
            }

            // Condition dropdown
            ExposedDropdownMenuBox(
                expanded = false,
                onExpandedChange = { },
                modifier = Modifier.fillMaxWidth()
            ) {
                OutlinedTextField(
                    value = condition,
                    onValueChange = { },
                    label = { Text("Condition") },
                    readOnly = true,
                    modifier = Modifier.fillMaxWidth(),
                    isError = hasValidationErrors && condition.isBlank()
                )
                DropdownMenu(
                    expanded = false,
                    onDismissRequest = { }
                ) {
                    listOf("new", "like_new", "good", "fair", "needs_repair").forEach { option ->
                        DropdownMenuItem(
                            text = { Text(option.replace("_", " ").capitalize()) },
                            onClick = { condition = option }
                        )
                    }
                }
            }

            // Dimensions inputs
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Dimensions (cm)",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        listOf("length", "width", "height").forEach { dimension ->
                            OutlinedTextField(
                                value = dimensions[dimension]?.toString() ?: "0",
                                onValueChange = { value ->
                                    dimensions = dimensions.toMutableMap().apply {
                                        put(dimension, value.toDoubleOrNull() ?: 0.0)
                                    }
                                },
                                label = { Text(dimension.capitalize()) },
                                modifier = Modifier.weight(1f),
                                keyboardOptions = KeyboardOptions(
                                    keyboardType = KeyboardType.Number,
                                    imeAction = ImeAction.Next
                                ),
                                isError = hasValidationErrors && (dimensions[dimension] ?: 0.0) <= 0
                            )
                        }
                    }
                }
            }

            // Material input
            OutlinedTextField(
                value = material,
                onValueChange = { material = it },
                label = { Text("Material") },
                modifier = Modifier.fillMaxWidth(),
                isError = hasValidationErrors && material.isBlank(),
                keyboardOptions = KeyboardOptions(
                    imeAction = ImeAction.Next
                )
            )

            // Image picker
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "Furniture Photos",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    ImagePicker(
                        state = imagePickerState,
                        onImageSelected = { uri ->
                            // Handle selected image
                        },
                        onDismiss = {
                            // Handle dismissal
                        }
                    )
                }
            }

            // Location picker
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "Furniture Location",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    LocationPicker(
                        state = locationPickerState,
                        onLocationSelected = { location ->
                            // Handle selected location
                        },
                        onPrivacyLevelChanged = { privacyLevel ->
                            // Handle privacy level change
                        }
                    )
                }
            }

            // Submit button
            Button(
                onClick = {
                    // Validate form
                    val errors = mutableListOf<String>()
                    if (title.isBlank()) errors.add("Title is required")
                    if (description.isBlank()) errors.add("Description is required")
                    if (category.isBlank()) errors.add("Category is required")
                    if (condition.isBlank()) errors.add("Condition is required")
                    if (material.isBlank()) errors.add("Material is required")
                    if (dimensions.any { it.value <= 0 }) errors.add("Valid dimensions are required")
                    if (imagePickerState.value !is ImagePickerState.Success || 
                        (imagePickerState.value as ImagePickerState.Success).selectedImageUri == null) {
                        errors.add("Image is required")
                    }
                    if (locationPickerState.selectedLocation == null) errors.add("Location is required")

                    if (errors.isEmpty()) {
                        // Create furniture object
                        val furniture = Furniture(
                            id = UUID.randomUUID().toString(),
                            userId = "", // Will be set by backend
                            title = title,
                            description = description,
                            category = category,
                            condition = condition,
                            dimensions = dimensions,
                            material = material,
                            isAvailable = true,
                            aiMetadata = mapOf(), // Will be set by AI service
                            location = locationPickerState.selectedLocation!!,
                            createdAt = System.currentTimeMillis(),
                            expiresAt = System.currentTimeMillis() + (30 * 24 * 60 * 60 * 1000) // 30 days
                        )

                        scope.launch {
                            try {
                                viewModel.createFurniture(furniture)
                                snackbarHostState.showSnackbar("Furniture listing created successfully")
                                navController.navigateUp()
                            } catch (e: Exception) {
                                snackbarHostState.showSnackbar("Failed to create furniture listing: ${e.message}")
                            }
                        }
                    } else {
                        hasValidationErrors = true
                        validationMessages = errors
                        scope.launch {
                            snackbarHostState.showSnackbar("Please fix the validation errors")
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 16.dp)
            ) {
                Text("Create Listing")
            }

            // Show validation errors if any
            if (hasValidationErrors && validationMessages.isNotEmpty()) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        Text(
                            text = "Please fix the following errors:",
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.onErrorContainer
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        validationMessages.forEach { message ->
                            Text(
                                text = "• $message",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onErrorContainer
                            )
                        }
                    }
                }
            }
        }
    }
}