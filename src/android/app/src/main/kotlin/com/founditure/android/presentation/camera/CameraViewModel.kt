/**
 * Human Tasks:
 * 1. Configure camera permissions in AndroidManifest.xml
 * 2. Set up proper memory allocation for image processing in app/build.gradle
 * 3. Configure ML model input specifications in build configuration
 * 4. Verify CameraX dependencies are properly included
 * 5. Set up proper ProGuard rules for CameraX and ML libraries
 */

package com.founditure.android.presentation.camera

import android.content.Context
import android.net.Uri
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.founditure.android.domain.model.Furniture
import com.founditure.android.domain.usecase.furniture.CreateFurnitureUseCase
import com.founditure.android.util.ImageUtils
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.util.concurrent.Executor
import javax.inject.Inject

// Version information for external dependencies
// androidx.camera:camera-core:1.3.0
// androidx.camera:camera-lifecycle:1.3.0
// androidx.camera:camera-view:1.3.0

/**
 * ViewModel managing camera operations and furniture creation workflow.
 * Implements requirements:
 * - Camera Integration (1.2 Scope/Core System Components/1. Mobile Applications)
 * - AI/ML Infrastructure (1.2 Scope/Core System Components/3. AI/ML Infrastructure)
 * - Offline-first Architecture (1.2 Scope/Core System Components/1. Mobile Applications)
 */
@HiltViewModel
class CameraViewModel @Inject constructor(
    private val createFurnitureUseCase: CreateFurnitureUseCase
) : ViewModel() {

    // Camera state management
    sealed class CameraState {
        object Initializing : CameraState()
        object Ready : CameraState()
        data class Error(val message: String) : CameraState()
    }

    // Processing state management
    sealed class ProcessingState {
        object Idle : ProcessingState()
        object Capturing : ProcessingState()
        object Processing : ProcessingState()
        object Creating : ProcessingState()
        data class Success(val furniture: Furniture) : ProcessingState()
        data class Error(val message: String) : ProcessingState()
    }

    private val _cameraState = MutableStateFlow<CameraState>(CameraState.Initializing)
    val cameraState: StateFlow<CameraState> = _cameraState.asStateFlow()

    private val _processingState = MutableStateFlow<ProcessingState>(ProcessingState.Idle)
    val processingState: StateFlow<ProcessingState> = _processingState.asStateFlow()

    private var imageCapture: ImageCapture? = null
    private var cameraExecutor: Executor? = null

    /**
     * Sets up the camera with required configuration.
     * Implements Camera Integration requirement.
     */
    fun setupCamera(context: Context) {
        viewModelScope.launch {
            try {
                val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
                val cameraProvider = cameraProviderFuture.get()

                // Configure camera preview
                val preview = Preview.Builder().build()

                // Configure image capture
                imageCapture = ImageCapture.Builder()
                    .setCaptureMode(ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY)
                    .build()

                // Select back camera
                val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

                cameraExecutor = ContextCompat.getMainExecutor(context)

                // Unbind all previous use cases
                cameraProvider.unbindAll()

                // Bind use cases to camera
                cameraProvider.bindToLifecycle(
                    context as androidx.lifecycle.LifecycleOwner,
                    cameraSelector,
                    preview,
                    imageCapture
                )

                _cameraState.value = CameraState.Ready
            } catch (e: Exception) {
                _cameraState.value = CameraState.Error("Failed to setup camera: ${e.message}")
            }
        }
    }

    /**
     * Captures an image and processes it for furniture creation.
     * Implements Camera Integration and AI/ML Infrastructure requirements.
     */
    fun captureImage() {
        val imageCapture = imageCapture ?: return
        _processingState.value = ProcessingState.Capturing

        viewModelScope.launch {
            try {
                // Create temporary file for image
                val photoFile = withContext(Dispatchers.IO) {
                    File.createTempFile("furniture_", ".jpg")
                }

                val outputOptions = ImageCapture.OutputFileOptions.Builder(photoFile).build()

                // Capture image
                withContext(Dispatchers.IO) {
                    imageCapture.takePicture(
                        outputOptions,
                        cameraExecutor!!,
                        object : ImageCapture.OnImageSavedCallback {
                            override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                                viewModelScope.launch {
                                    processImage(photoFile)
                                }
                            }

                            override fun onError(exception: ImageCaptureException) {
                                _processingState.value = ProcessingState.Error(
                                    "Failed to capture image: ${exception.message}"
                                )
                            }
                        }
                    )
                }
            } catch (e: Exception) {
                _processingState.value = ProcessingState.Error("Failed to process image: ${e.message}")
            }
        }
    }

    /**
     * Processes captured image for AI analysis and furniture creation.
     * Implements AI/ML Infrastructure requirement.
     */
    private suspend fun processImage(imageFile: File) {
        _processingState.value = ProcessingState.Processing

        try {
            // Read image file
            val bitmap = withContext(Dispatchers.IO) {
                android.graphics.BitmapFactory.decodeFile(imageFile.absolutePath)
            }

            // Rotate image if needed
            val rotatedBitmap = ImageUtils.rotateImage(bitmap, imageFile.absolutePath)

            // Prepare image for ML processing
            val processedBitmap = ImageUtils.prepareImageForML(rotatedBitmap)

            // Compress image for storage
            val compressedImageData = ImageUtils.compressImage(processedBitmap, 85)

            // Create initial furniture object with processed image
            val furniture = Furniture(
                id = "",
                userId = "", // Will be set by CreateFurnitureUseCase
                title = "",
                description = "",
                category = "other", // Default category, to be updated by AI
                condition = "good", // Default condition, to be updated by AI
                dimensions = mapOf(
                    "length" to 0.0,
                    "width" to 0.0,
                    "height" to 0.0
                ),
                material = "",
                isAvailable = true,
                aiMetadata = mapOf(
                    "imageProcessed" to true,
                    "processingTimestamp" to System.currentTimeMillis()
                ),
                location = null, // To be set later
                createdAt = System.currentTimeMillis(),
                expiresAt = System.currentTimeMillis() + (30L * 24L * 60L * 60L * 1000L) // 30 days
            )

            createFurniture(furniture)

            // Cleanup temporary file
            withContext(Dispatchers.IO) {
                imageFile.delete()
            }
        } catch (e: Exception) {
            _processingState.value = ProcessingState.Error("Failed to process image: ${e.message}")
        }
    }

    /**
     * Creates a furniture listing with processed image data.
     * Implements Offline-first Architecture requirement.
     */
    private suspend fun createFurniture(furniture: Furniture) {
        _processingState.value = ProcessingState.Creating

        try {
            val result = createFurnitureUseCase.execute(furniture)
            _processingState.value = ProcessingState.Success(result)
        } catch (e: Exception) {
            _processingState.value = ProcessingState.Error("Failed to create furniture: ${e.message}")
        }
    }

    /**
     * Cleanup camera resources when ViewModel is cleared
     */
    override fun onCleared() {
        super.onCleared()
        cameraExecutor = null
        imageCapture = null
    }
}