/**
 * Human Tasks:
 * 1. Configure file provider paths in res/xml/file_paths.xml
 * 2. Add camera and storage permissions in AndroidManifest.xml
 * 3. Configure ProGuard rules for Coil image loading library
 * 4. Set up proper memory allocation for image processing in android:largeHeap
 * 5. Test on various Android versions for permission handling
 */

package com.founditure.android.presentation.components

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage // version: 2.4.0
import com.founditure.android.R
import com.founditure.android.util.ImageUtils.compressImage
import com.founditure.android.util.ImageUtils.resizeImage
import com.founditure.android.util.ImageUtils.rotateImage
import com.founditure.android.util.PermissionUtils.hasRequiredPermissions
import com.founditure.android.util.PermissionUtils.requestPermissions
import android.Manifest
import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.ui.platform.LocalLifecycleOwner
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

/**
 * Sealed class representing different states of the image picker
 * Implements requirement: Content moderation (1.2 Scope/Included Features)
 */
sealed class ImagePickerState {
    data class Success(val selectedImageUri: Uri? = null) : ImagePickerState()
    data class Loading(val isLoading: Boolean = false) : ImagePickerState()
    data class Error(val error: String? = null) : ImagePickerState()
}

/**
 * Composable function that provides an image picker interface with camera and gallery options
 * Implements requirement: Furniture documentation (1.2 Scope/Core System Components/1. Mobile Applications)
 */
@Composable
fun ImagePicker(
    state: State<ImagePickerState>,
    onImageSelected: (Uri) -> Unit,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    var showImageSourceDialog by remember { mutableStateOf(false) }
    var tempImageUri by remember { mutableStateOf<Uri?>(null) }

    // Camera launcher
    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicture()
    ) { success ->
        if (success) {
            tempImageUri?.let { uri ->
                // Process and validate the captured image
                try {
                    val bitmap = MediaStore.Images.Media.getBitmap(context.contentResolver, uri)
                    val rotatedBitmap = rotateImage(bitmap, uri.path ?: "")
                    val resizedBitmap = resizeImage(rotatedBitmap)
                    val compressedData = compressImage(resizedBitmap, 85)
                    
                    // Save processed image and notify
                    context.contentResolver.openOutputStream(uri)?.use { 
                        it.write(compressedData)
                    }
                    onImageSelected(uri)
                } catch (e: Exception) {
                    (state.value as? ImagePickerState.Error)?.error?.let { error ->
                        // Handle error state
                    }
                }
            }
        }
    }

    // Gallery launcher
    val galleryLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            try {
                val bitmap = MediaStore.Images.Media.getBitmap(context.contentResolver, it)
                val resizedBitmap = resizeImage(bitmap)
                val compressedData = compressImage(resizedBitmap, 85)
                
                // Create a new file for the processed image
                val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
                val contentValues = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, "IMG_$timestamp.jpg")
                    put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                }
                
                val processedUri = context.contentResolver.insert(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    contentValues
                )
                
                processedUri?.let { newUri ->
                    context.contentResolver.openOutputStream(newUri)?.use { 
                        it.write(compressedData)
                    }
                    onImageSelected(newUri)
                }
            } catch (e: Exception) {
                (state.value as? ImagePickerState.Error)?.error?.let { error ->
                    // Handle error state
                }
            }
        }
    }

    // Permission launcher
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val allGranted = permissions.values.all { it }
        if (allGranted) {
            showImageSourceDialog = true
        }
    }

    // Show loading state
    when (state.value) {
        is ImagePickerState.Loading -> {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        }
        is ImagePickerState.Error -> {
            AlertDialog(
                onDismissRequest = onDismiss,
                title = { Text("Error") },
                text = { Text((state.value as ImagePickerState.Error).error ?: "Unknown error") },
                confirmButton = {
                    Button(onClick = onDismiss) {
                        Text("OK")
                    }
                }
            )
        }
        is ImagePickerState.Success -> {
            // Show image source selection dialog
            if (showImageSourceDialog) {
                AlertDialog(
                    onDismissRequest = { showImageSourceDialog = false },
                    title = { Text("Select Image Source") },
                    text = {
                        Column {
                            Button(
                                onClick = {
                                    val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault())
                                        .format(Date())
                                    val contentValues = ContentValues().apply {
                                        put(MediaStore.Images.Media.DISPLAY_NAME, "IMG_$timestamp.jpg")
                                        put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                                    }
                                    tempImageUri = context.contentResolver.insert(
                                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                                        contentValues
                                    )
                                    tempImageUri?.let { cameraLauncher.launch(it) }
                                    showImageSourceDialog = false
                                },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 8.dp)
                            ) {
                                Text("Camera")
                            }
                            Button(
                                onClick = {
                                    galleryLauncher.launch("image/*")
                                    showImageSourceDialog = false
                                },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 8.dp)
                            ) {
                                Text("Gallery")
                            }
                        }
                    },
                    confirmButton = {},
                    dismissButton = {
                        Button(onClick = { showImageSourceDialog = false }) {
                            Text("Cancel")
                        }
                    }
                )
            }

            // Show selected image
            (state.value as ImagePickerState.Success).selectedImageUri?.let { uri ->
                AsyncImage(
                    model = uri,
                    contentDescription = "Selected image",
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp)
                )
            }
        }
    }

    // Check and request permissions when needed
    LaunchedEffect(Unit) {
        if (!hasRequiredPermissions(context)) {
            permissionLauncher.launch(
                arrayOf(
                    Manifest.permission.CAMERA,
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
                        Manifest.permission.WRITE_EXTERNAL_STORAGE
                    } else {
                        Manifest.permission.ACCESS_MEDIA_LOCATION
                    }
                )
            )
        } else {
            showImageSourceDialog = true
        }
    }
}

/**
 * Creates and remembers ImagePickerState instance
 * Implements requirement: Content moderation (1.2 Scope/Included Features)
 */
@Composable
fun rememberImagePickerState(): State<ImagePickerState> {
    return remember { mutableStateOf(ImagePickerState.Success()) }
}