/**
 * Human Tasks:
 * 1. Ensure proper camera permissions are configured in AndroidManifest.xml
 * 2. Verify storage permissions for image processing
 * 3. Configure ProGuard rules for image processing libraries
 * 4. Set up proper memory allocation for large image processing
 * 5. Configure ML model input specifications in build configuration
 */

package com.founditure.android.util

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.exifinterface.media.ExifInterface // version: 1.3.6
import com.founditure.android.util.Constants.UI.MAX_IMAGE_SIZE
import com.founditure.android.util.Constants.UI.THUMBNAIL_SIZE
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Utility class providing image processing capabilities for the Founditure Android application.
 * Implements requirements from:
 * - Image Processing (1.2 Scope/Core System Components/1. Mobile Applications)
 * - AI/ML Infrastructure (1.2 Scope/Core System Components/3. AI/ML Infrastructure)
 * - Data Management (1.2 Scope/Core System Components/4. Data Management)
 */
object ImageUtils {

    /**
     * Compresses a bitmap image while maintaining aspect ratio and quality.
     * Implements requirement: Local data persistence and image processing capabilities
     */
    fun compressImage(bitmap: Bitmap, quality: Int): ByteArray {
        val outputStream = ByteArrayOutputStream()
        try {
            bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
            return outputStream.toByteArray()
        } finally {
            outputStream.close()
        }
    }

    /**
     * Resizes an image to specified dimensions while maintaining aspect ratio.
     * Implements requirement: Image preprocessing for AI/ML model input
     */
    fun resizeImage(bitmap: Bitmap, maxWidth: Int = MAX_IMAGE_SIZE, maxHeight: Int = MAX_IMAGE_SIZE): Bitmap {
        val width = bitmap.width
        val height = bitmap.height

        val ratioBitmap = width.toFloat() / height.toFloat()
        val ratioMax = maxWidth.toFloat() / maxHeight.toFloat()

        var finalWidth = maxWidth
        var finalHeight = maxHeight

        if (ratioMax > ratioBitmap) {
            finalWidth = (maxHeight.toFloat() * ratioBitmap).toInt()
        } else {
            finalHeight = (maxWidth.toFloat() / ratioBitmap).toInt()
        }

        return Bitmap.createScaledBitmap(bitmap, finalWidth, finalHeight, true)
    }

    /**
     * Creates a thumbnail from a bitmap image.
     * Implements requirement: Object storage for media and cache layers
     */
    fun createThumbnail(bitmap: Bitmap): Bitmap {
        val width = bitmap.width
        val height = bitmap.height
        val aspectRatio = width.toFloat() / height.toFloat()

        val thumbnailWidth: Int
        val thumbnailHeight: Int

        if (width > height) {
            thumbnailWidth = THUMBNAIL_SIZE
            thumbnailHeight = (THUMBNAIL_SIZE / aspectRatio).toInt()
        } else {
            thumbnailHeight = THUMBNAIL_SIZE
            thumbnailWidth = (THUMBNAIL_SIZE * aspectRatio).toInt()
        }

        return Bitmap.createScaledBitmap(bitmap, thumbnailWidth, thumbnailHeight, true)
    }

    /**
     * Rotates an image based on EXIF orientation data.
     * Implements requirement: Image preprocessing for AI/ML model input
     */
    fun rotateImage(bitmap: Bitmap, imagePath: String): Bitmap {
        val exif = ExifInterface(imagePath)
        val orientation = exif.getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_UNDEFINED
        )

        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.postScale(1f, -1f)
        }

        return Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            matrix,
            true
        )
    }

    /**
     * Prepares an image for ML model input by normalizing size and format.
     * Implements requirement: Image preprocessing for AI/ML model input
     */
    fun prepareImageForML(bitmap: Bitmap): Bitmap {
        // Standard ML input size (224x224 is common for many models)
        val mlInputSize = 224

        // Resize to model input dimensions
        val resizedBitmap = Bitmap.createScaledBitmap(bitmap, mlInputSize, mlInputSize, true)

        // Convert to ARGB_8888 format which is commonly used for ML input
        val convertedBitmap = resizedBitmap.copy(Bitmap.Config.ARGB_8888, true)

        // Ensure original bitmap is recycled if it was created new
        if (resizedBitmap != bitmap && resizedBitmap != convertedBitmap) {
            resizedBitmap.recycle()
        }

        return convertedBitmap
    }

    /**
     * Private helper function to calculate scaling dimensions
     */
    private fun calculateScaling(
        originalWidth: Int,
        originalHeight: Int,
        targetSize: Int
    ): Pair<Int, Int> {
        val aspectRatio = originalWidth.toFloat() / originalHeight.toFloat()
        return if (originalWidth > originalHeight) {
            Pair(targetSize, (targetSize / aspectRatio).toInt())
        } else {
            Pair((targetSize * aspectRatio).toInt(), targetSize)
        }
    }
}