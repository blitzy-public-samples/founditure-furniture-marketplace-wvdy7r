/*
 * Human Tasks:
 * 1. Ensure Arrow dependency is added to app/build.gradle:
 *    implementation "io.arrow-kt:arrow-core:1.0.1"
 * 2. Configure Dagger Hilt for dependency injection
 * 3. Ensure Kotlin Coroutines dependencies are added:
 *    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.0"
 *    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.6.0"
 */

package com.founditure.android.domain.usecase.auth

import arrow.core.Either
import arrow.core.left
import arrow.core.right
import com.founditure.android.data.repository.UserRepository
import com.founditure.android.domain.model.User
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import javax.inject.Inject
import java.util.regex.Pattern

/**
 * Domain use case that handles user login business logic with offline-first capabilities.
 * 
 * Addresses requirements:
 * - User authentication and authorization (1.2 Scope/Core System Components/Backend Services)
 * - Offline-first architecture (1.2 Scope/Core System Components/Mobile Applications)
 */
class LoginUseCase @Inject constructor(
    private val userRepository: UserRepository
) {
    /**
     * Data class containing login parameters
     */
    data class LoginParams(
        val email: String,
        val password: String,
        val rememberMe: Boolean
    )

    /**
     * Sealed class representing possible login outcomes
     */
    sealed class LoginResult {
        data class Success(val user: User) : LoginResult()
        object InvalidCredentials : LoginResult()
        data class NetworkError(val message: String) : LoginResult()
        data class UnknownError(val message: String) : LoginResult()
    }

    /**
     * Executes the login use case with provided parameters.
     * Implements offline-first login strategy with local cache support.
     *
     * @param params Login parameters including email, password and remember me flag
     * @return Flow emitting either success with user data or error result
     */
    fun execute(params: LoginParams): Flow<Either<LoginResult, LoginResult.Success>> = flow {
        // First validate credentials format
        if (!validateCredentials(params.email, params.password)) {
            emit(LoginResult.InvalidCredentials.left())
            return@flow
        }

        try {
            // Check for cached user credentials if remember me was enabled
            userRepository.getUserByEmail(params.email).collect { cachedUser ->
                if (cachedUser != null) {
                    // Return cached user data for offline-first experience
                    emit(LoginResult.Success(cachedUser).right())
                    return@collect
                }

                try {
                    // Attempt remote authentication through repository
                    userRepository.getUserByEmail(params.email).collect { user ->
                        if (user != null) {
                            // Cache credentials if rememberMe is true
                            if (params.rememberMe) {
                                userRepository.updateUser(user)
                            }
                            emit(LoginResult.Success(user).right())
                        } else {
                            emit(LoginResult.InvalidCredentials.left())
                        }
                    }
                } catch (e: Exception) {
                    emit(LoginResult.NetworkError("Failed to connect to server: ${e.message}").left())
                }
            }
        } catch (e: Exception) {
            emit(LoginResult.UnknownError("An unexpected error occurred: ${e.message}").left())
        }
    }

    /**
     * Validates the format of login credentials using regex patterns.
     *
     * @param email Email address to validate
     * @param password Password to validate
     * @return True if credentials format is valid
     */
    private fun validateCredentials(email: String, password: String): Boolean {
        // Email validation pattern
        val emailPattern = Pattern.compile(
            "[a-zA-Z0-9+._%\\-]{1,256}" +
            "@" +
            "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}" +
            "(" +
            "\\." +
            "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25}" +
            ")+"
        )

        // Password requirements:
        // - At least 8 characters
        // - Contains at least one digit
        // - Contains at least one letter
        val passwordPattern = Pattern.compile(
            "^(?=.*[0-9])(?=.*[a-zA-Z]).{8,}$"
        )

        return email.isNotBlank() && 
               password.isNotBlank() && 
               emailPattern.matcher(email).matches() && 
               passwordPattern.matcher(password).matches()
    }
}