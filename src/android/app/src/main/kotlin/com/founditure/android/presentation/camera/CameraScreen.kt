/**
 * Human Tasks:
 * 1. Configure camera permissions in AndroidManifest.xml
 * 2. Set up proper memory allocation for image processing in app/build.gradle
 * 3. Configure ML model input specifications in build configuration
 * 4. Verify CameraX dependencies are properly included
 * 5. Set up proper ProGuard rules for CameraX and ML libraries
 */

package com.founditure.android.presentation.camera

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.founditure.android.presentation.components.ImagePicker
import com.founditure.android.presentation.components.rememberImagePickerState
import kotlinx.coroutines.flow.collectLatest

// Version information for external dependencies
// androidx.compose.material3:material3:1.1.0
// androidx.compose.runtime:runtime:1.5.0
// androidx.compose.foundation:foundation:1.5.0
// androidx.camera:camera-view:1.3.0
// androidx.hilt:hilt-navigation-compose:1.0.0

/**
 * Main camera screen composable that implements furniture documentation interface
 * Implements requirements:
 * - Camera Integration (1.2 Scope/Core System Components/1. Mobile Applications)
 * - AI/ML Integration (1.2 Scope/Core System Components/3. AI/ML Infrastructure)
 * - Offline-first Architecture (1.2 Scope/Core System Components/1. Mobile Applications)
 */
@Composable
fun CameraScreen(
    navController: NavController,
    viewModel: CameraViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val cameraState by viewModel.cameraState.collectAsState()
    val processingState by viewModel.processingState.collectAsState()
    val imagePickerState = rememberImagePickerState()

    // Permission launcher for camera access
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            viewModel.setupCamera(context)
        }
    }

    // Check camera permission on launch
    LaunchedEffect(Unit) {
        when (PackageManager.PERMISSION_GRANTED) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.CAMERA
            ) -> viewModel.setupCamera(context)
            else -> permissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    // Handle processing state changes
    LaunchedEffect(processingState) {
        when (processingState) {
            is CameraViewModel.ProcessingState.Success -> {
                val furniture = (processingState as CameraViewModel.ProcessingState.Success).furniture
                navController.navigate("furniture/${furniture.id}")
            }
            else -> {}
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // Camera Preview
        when (cameraState) {
            is CameraViewModel.CameraState.Ready -> {
                CameraPreview(cameraState)
            }
            is CameraViewModel.CameraState.Error -> {
                Text(
                    text = (cameraState as CameraViewModel.CameraState.Error).message,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            else -> {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center)
                )
            }
        }

        // Processing Overlay
        ProcessingOverlay(processingState)

        // Camera Controls
        CameraControls(
            onCapture = { viewModel.captureImage() },
            onGallery = { /* ImagePicker will handle this */ },
            onClose = { navController.navigateUp() }
        )

        // Image Picker for gallery access
        ImagePicker(
            state = imagePickerState,
            onImageSelected = { uri ->
                // Handle selected image from gallery
                // Implementation would go through the same processing pipeline
            },
            onDismiss = { /* Handle dismiss */ }
        )
    }
}

/**
 * Camera preview composable that displays real-time camera feed
 * Implements Camera Integration requirement
 */
@Composable
private fun CameraPreview(cameraState: CameraViewModel.CameraState) {
    AndroidView(
        factory = { context ->
            PreviewView(context).apply {
                implementationMode = PreviewView.ImplementationMode.PERFORMANCE
                scaleType = PreviewView.ScaleType.FILL_CENTER
            }
        },
        modifier = Modifier.fillMaxSize()
    )
}

/**
 * Camera controls composable that provides capture and navigation buttons
 * Implements Camera Integration requirement
 */
@Composable
private fun CameraControls(
    onCapture: () -> Unit,
    onGallery: () -> Unit,
    onClose: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Close button
        IconButton(
            onClick = onClose,
            modifier = Modifier
                .align(Alignment.TopStart)
                .background(Color.Black.copy(alpha = 0.5f), shape = MaterialTheme.shapes.small)
        ) {
            Icon(
                imageVector = Icons.Default.Close,
                contentDescription = "Close camera",
                tint = Color.White
            )
        }

        // Bottom controls
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(bottom = 32.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Gallery button
            IconButton(
                onClick = onGallery,
                modifier = Modifier.background(
                    Color.Black.copy(alpha = 0.5f),
                    shape = MaterialTheme.shapes.small
                )
            ) {
                Icon(
                    imageVector = Icons.Default.PhotoLibrary,
                    contentDescription = "Open gallery",
                    tint = Color.White
                )
            }

            // Capture button
            IconButton(
                onClick = onCapture,
                modifier = Modifier
                    .size(72.dp)
                    .background(Color.White, shape = MaterialTheme.shapes.small)
            ) {
                Icon(
                    imageVector = Icons.Default.Camera,
                    contentDescription = "Take photo",
                    tint = Color.Black,
                    modifier = Modifier.size(32.dp)
                )
            }

            // Flash toggle (placeholder for symmetry)
            IconButton(
                onClick = { /* Toggle flash */ },
                modifier = Modifier.background(
                    Color.Black.copy(alpha = 0.5f),
                    shape = MaterialTheme.shapes.small
                )
            ) {
                Icon(
                    imageVector = Icons.Default.FlashOff,
                    contentDescription = "Toggle flash",
                    tint = Color.White
                )
            }
        }
    }
}

/**
 * Processing overlay composable that shows AI feedback and processing status
 * Implements AI/ML Integration requirement
 */
@Composable
private fun ProcessingOverlay(processingState: CameraViewModel.ProcessingState) {
    when (processingState) {
        is CameraViewModel.ProcessingState.Capturing,
        is CameraViewModel.ProcessingState.Processing,
        is CameraViewModel.ProcessingState.Creating -> {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.5f))
            ) {
                Column(
                    modifier = Modifier.align(Alignment.Center),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    CircularProgressIndicator(color = Color.White)
                    Text(
                        text = when (processingState) {
                            is CameraViewModel.ProcessingState.Capturing -> "Capturing image..."
                            is CameraViewModel.ProcessingState.Processing -> "Analyzing furniture..."
                            is CameraViewModel.ProcessingState.Creating -> "Creating listing..."
                            else -> ""
                        },
                        color = Color.White
                    )
                }
            }
        }
        is CameraViewModel.ProcessingState.Error -> {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.5f))
            ) {
                Text(
                    text = processingState.message,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier
                        .align(Alignment.Center)
                        .padding(16.dp)
                )
            }
        }
        else -> {}
    }
}