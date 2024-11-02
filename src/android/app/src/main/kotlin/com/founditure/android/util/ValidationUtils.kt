/**
 * Human Tasks:
 * 1. Verify that the password requirements align with the security policy
 * 2. Ensure proper location permissions are configured in AndroidManifest.xml
 * 3. Review and adjust validation rules based on business requirements
 * 4. Configure proper error messages for different locales
 */

package com.founditure.android.util

import android.util.Patterns // version: latest
import android.location.Location // version: latest

/**
 * Utility class providing validation functions for user input, data models, and business rules.
 * Implements requirements from:
 * - Input Validation (7.3.3 Security Controls)
 * - Data Validation (3.6 Security Architecture)
 */
object ValidationUtils {

    /**
     * Validates email address format using Android patterns
     * Implements requirement: Input validation and sanitization for security
     */
    fun validateEmail(email: String): Boolean {
        if (email.isBlank()) {
            return false
        }
        return Patterns.EMAIL_ADDRESS.matcher(email).matches()
    }

    /**
     * Validates password strength according to security requirements
     * Implements requirement: Data validation for user inputs and model integrity
     */
    fun validatePassword(password: String): Boolean {
        if (password.length < 8) {
            return false
        }

        val hasUpperCase = password.any { it.isUpperCase() }
        val hasLowerCase = password.any { it.isLowerCase() }
        val hasDigit = password.any { it.isDigit() }
        val hasSpecialChar = password.any { !it.isLetterOrDigit() }

        return hasUpperCase && hasLowerCase && hasDigit && hasSpecialChar
    }

    /**
     * Validates phone number format using Android patterns
     * Implements requirement: Input validation and sanitization for security
     */
    fun validatePhoneNumber(phoneNumber: String): Boolean {
        if (phoneNumber.isBlank()) {
            return false
        }
        return Patterns.PHONE.matcher(phoneNumber).matches()
    }

    /**
     * Validates location coordinates and accuracy
     * Implements requirement: Data validation for user inputs and model integrity
     */
    fun validateLocation(latitude: Double, longitude: Double): Boolean {
        return latitude in -90.0..90.0 && longitude in -180.0..180.0
    }

    /**
     * Validates furniture listing input data
     * Implements requirements:
     * - Input validation and sanitization for security
     * - Data validation for user inputs and model integrity
     */
    fun validateFurnitureInput(
        title: String,
        description: String,
        images: List<String>,
        latitude: Double,
        longitude: Double
    ): Pair<Boolean, ErrorCodes?> {
        // Validate title
        if (title.isBlank() || title.length !in 3..100) {
            return Pair(false, ErrorCodes.VALIDATION_ERROR)
        }

        // Validate description
        if (description.isBlank() || description.length !in 10..1000) {
            return Pair(false, ErrorCodes.VALIDATION_ERROR)
        }

        // Validate images
        if (images.isEmpty()) {
            return Pair(false, ErrorCodes.VALIDATION_ERROR)
        }

        // Validate location
        if (!validateLocation(latitude, longitude)) {
            return Pair(false, ErrorCodes.LOCATION_ERROR)
        }

        return Pair(true, null)
    }

    // Private helper functions
    private fun containsOnlyAllowedCharacters(input: String): Boolean {
        val allowedPattern = Regex("^[a-zA-Z0-9\\s.,!?-]*$")
        return allowedPattern.matches(input)
    }

    private fun sanitizeInput(input: String): String {
        return input.trim()
            .replace(Regex("[<>\"'&]"), "")
            .take(1000) // Maximum length limit
    }
}