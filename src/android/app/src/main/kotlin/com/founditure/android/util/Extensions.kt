/*
 * Human Tasks:
 * 1. Ensure Glide dependency is added to app/build.gradle
 * 2. Configure proper placeholder and error drawables in res/drawable
 * 3. Verify Toast duration constants are properly configured
 */

package com.founditure.android.util

import android.view.View // version: latest
import android.widget.ImageView // version: latest
import android.content.Context // version: latest
import android.widget.Toast // version: latest
import com.google.android.material.textfield.TextInputLayout // version: 1.9.0
import androidx.lifecycle.LifecycleOwner // version: 2.6.1
import com.bumptech.glide.Glide // version: 4.15.1
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.Date
import com.founditure.android.domain.model.Furniture
import com.founditure.android.util.ValidationUtils.validateLocation

/**
 * Extension functions for Android Views and components.
 * Implements requirements:
 * - Mobile-first Platform (1.1 System Overview)
 * - Offline-first Architecture (1.2 Scope/Core System Components/Mobile Applications)
 */

/**
 * Makes a view visible
 */
fun View.visible() {
    visibility = View.VISIBLE
}

/**
 * Makes a view invisible (keeps layout space)
 */
fun View.invisible() {
    visibility = View.INVISIBLE
}

/**
 * Makes a view gone (removes from layout)
 */
fun View.gone() {
    visibility = View.GONE
}

/**
 * Loads an image from URL into ImageView using Glide
 * Implements requirement: Mobile-first Platform for efficient image loading
 */
fun ImageView.loadFromUrl(
    url: String,
    placeholder: Int,
    error: Int
) {
    Glide.with(context)
        .load(url)
        .placeholder(placeholder)
        .error(error)
        .centerCrop()
        .into(this)
}

/**
 * Clears error state of TextInputLayout
 * Implements requirement: Mobile-first Platform for form handling
 */
fun TextInputLayout.clearError() {
    error = null
    isErrorEnabled = false
}

/**
 * Converts timestamp string to formatted date
 * Implements requirement: Mobile-first Platform for date formatting
 */
fun String.toFormattedDate(format: String): String {
    return try {
        val timestamp = this.toLongOrNull() ?: return this
        val dateFormat = SimpleDateFormat(format, Locale.getDefault())
        dateFormat.format(Date(timestamp))
    } catch (e: Exception) {
        this
    }
}

/**
 * Formats distance with appropriate unit
 * Implements requirement: Mobile-first Platform for distance display
 */
fun Double.toFormattedDistance(): String {
    return when {
        this >= 1000 -> String.format("%.1f km", this / 1000)
        else -> String.format("%.0f m", this)
    }
}

/**
 * Shows toast message with specified duration
 * Implements requirement: Mobile-first Platform for user feedback
 */
fun Context.showToast(
    message: String,
    duration: Int = Toast.LENGTH_SHORT
) {
    Toast.makeText(this, message, duration).show()
}

/**
 * Extension function to convert Furniture to Map
 * Implements requirement: Offline-first Architecture for data transformation
 */
fun Furniture.toMap(): Map<String, Any> {
    return mapOf(
        "id" to id,
        "userId" to userId,
        "title" to title,
        "description" to description,
        "category" to category,
        "condition" to condition,
        "dimensions" to dimensions,
        "material" to material,
        "isAvailable" to isAvailable,
        "aiMetadata" to aiMetadata,
        "location" to location,
        "createdAt" to createdAt,
        "expiresAt" to expiresAt
    )
}

/**
 * Extension function to validate location coordinates
 * Implements requirement: Mobile-first Platform for location validation
 */
fun Pair<Double, Double>.isValidLocation(): Boolean {
    return validateLocation(first, second)
}

/**
 * Extension function for safe resource loading
 * Implements requirement: Mobile-first Platform for resource handling
 */
fun Context.getResourceString(resId: Int): String {
    return try {
        getString(resId)
    } catch (e: Exception) {
        ""
    }
}

/**
 * Extension function for safe dimension conversion
 * Implements requirement: Mobile-first Platform for UI scaling
 */
fun Context.dpToPx(dp: Float): Int {
    return (dp * resources.displayMetrics.density).toInt()
}

/**
 * Extension function for safe pixel conversion
 * Implements requirement: Mobile-first Platform for UI scaling
 */
fun Context.pxToDp(px: Float): Int {
    return (px / resources.displayMetrics.density).toInt()
}

/**
 * Extension function for safe lifecycle observation
 * Implements requirement: Mobile-first Platform for lifecycle management
 */
fun <T> LifecycleOwner.safeObserve(block: () -> T): T? {
    return try {
        block()
    } catch (e: Exception) {
        null
    }
}