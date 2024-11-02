/*
 * Human Tasks:
 * 1. Ensure Kotlin Coroutines dependencies are added to app/build.gradle:
 *    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.0"
 *    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.6.0"
 * 2. Configure Dagger Hilt for dependency injection
 * 3. Verify password validation rules align with security policy
 */

package com.founditure.android.domain.usecase.auth

import com.founditure.android.domain.model.User
import com.founditure.android.data.repository.UserRepository
import com.founditure.android.util.ValidationUtils
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import java.util.UUID
import javax.inject.Inject

/**
 * Domain use case that handles user registration business logic.
 * Implements requirements:
 * - Core user registration functionality (1.2 Scope/Included Features)
 * - Initial points allocation for new users (1.2 Scope/Included Features)
 * - Input validation and sanitization (7.3.3 Security Controls)
 */
class RegisterUseCase @Inject constructor(
    private val userRepository: UserRepository
) {
    /**
     * Executes the registration process with provided user data.
     * Implements core registration flow with validation and security measures.
     */
    fun execute(
        email: String,
        password: String,
        fullName: String,
        phoneNumber: String?
    ): Flow<Result<User>> = flow {
        try {
            // Validate registration input
            validateRegistrationInput(email, password, fullName, phoneNumber).fold(
                onSuccess = {
                    // Check if email already exists
                    userRepository.getUserByEmail(email).collect { existingUser ->
                        if (existingUser != null) {
                            emit(Result.failure(Exception("Email already registered")))
                            return@collect
                        }

                        // Create new user with initial points (0)
                        val newUser = User(
                            id = UUID.randomUUID().toString(),
                            email = email,
                            fullName = fullName,
                            phoneNumber = phoneNumber,
                            points = 0, // Initial points allocation
                            profileImageUrl = null,
                            createdAt = System.currentTimeMillis(),
                            updatedAt = System.currentTimeMillis(),
                            isVerified = false,
                            preferences = emptyMap()
                        )

                        // Attempt to save user in repository
                        val success = userRepository.updateUser(newUser)
                        if (success) {
                            emit(Result.success(newUser))
                        } else {
                            emit(Result.failure(Exception("Failed to create user")))
                        }
                    }
                },
                onFailure = { error ->
                    emit(Result.failure(error))
                }
            )
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    /**
     * Validates all registration input fields.
     * Implements input validation and security controls.
     */
    private fun validateRegistrationInput(
        email: String,
        password: String,
        fullName: String,
        phoneNumber: String?
    ): Result<Unit> {
        // Validate email format
        if (!ValidationUtils.validateEmail(email)) {
            return Result.failure(Exception("Invalid email format"))
        }

        // Validate password strength
        if (!ValidationUtils.validatePassword(password)) {
            return Result.failure(Exception("Password does not meet security requirements"))
        }

        // Validate full name
        if (fullName.isBlank()) {
            return Result.failure(Exception("Full name is required"))
        }

        // Validate phone number if provided
        if (!phoneNumber.isNullOrBlank() && !ValidationUtils.validatePhoneNumber(phoneNumber)) {
            return Result.failure(Exception("Invalid phone number format"))
        }

        return Result.success(Unit)
    }
}