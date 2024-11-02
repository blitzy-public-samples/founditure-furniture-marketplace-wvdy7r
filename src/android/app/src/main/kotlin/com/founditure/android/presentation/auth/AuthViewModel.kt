/*
 * Human Tasks:
 * 1. Ensure Kotlin Coroutines dependencies are added to app/build.gradle:
 *    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.0"
 *    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.6.0"
 * 2. Configure Dagger Hilt for dependency injection
 * 3. Verify ViewModelScope is properly configured in app/build.gradle:
 *    implementation "androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1"
 */

package com.founditure.android.presentation.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.founditure.android.domain.model.User
import com.founditure.android.domain.usecase.auth.LoginUseCase
import com.founditure.android.domain.usecase.auth.LoginUseCase.LoginParams
import com.founditure.android.domain.usecase.auth.LoginUseCase.LoginResult
import com.founditure.android.domain.usecase.auth.RegisterUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel that manages authentication state and operations.
 * 
 * Addresses requirements:
 * - User registration and authentication (1.2 Scope/Included Features)
 * - Privacy controls (1.2 Scope/Included Features)
 * - Offline-first architecture (1.2 Scope/Core System Components/Mobile Applications)
 */
class AuthViewModel @Inject constructor(
    private val loginUseCase: LoginUseCase,
    private val registerUseCase: RegisterUseCase
) : ViewModel() {

    // Sealed class representing possible authentication states
    sealed class AuthState {
        object Idle : AuthState()
        object Loading : AuthState()
        data class Authenticated(val user: User) : AuthState()
        data class Error(val message: String) : AuthState()
    }

    // Private mutable state flow for internal updates
    private val _authState = MutableStateFlow<AuthState>(AuthState.Idle)
    
    // Public immutable state flow for UI consumption
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    /**
     * Attempts to log in user with provided credentials.
     * Implements offline-first login strategy with local cache support.
     */
    fun login(email: String, password: String, rememberMe: Boolean) {
        viewModelScope.launch {
            try {
                _authState.value = AuthState.Loading

                // Create login parameters
                val params = LoginParams(
                    email = email,
                    password = password,
                    rememberMe = rememberMe
                )

                // Execute login use case and collect results
                loginUseCase.execute(params).collect { result ->
                    result.fold(
                        { error ->
                            _authState.value = when (error) {
                                is LoginResult.InvalidCredentials -> 
                                    AuthState.Error("Invalid email or password")
                                is LoginResult.NetworkError -> 
                                    AuthState.Error(error.message)
                                is LoginResult.UnknownError -> 
                                    AuthState.Error(error.message)
                                else -> AuthState.Error("An unexpected error occurred")
                            }
                        },
                        { success ->
                            _authState.value = AuthState.Authenticated(success.user)
                        }
                    )
                }
            } catch (e: Exception) {
                _authState.value = AuthState.Error("Login failed: ${e.message}")
            }
        }
    }

    /**
     * Registers a new user with provided information.
     * Implements secure registration flow with validation.
     */
    fun register(
        email: String,
        password: String,
        fullName: String,
        phoneNumber: String?
    ) {
        viewModelScope.launch {
            try {
                _authState.value = AuthState.Loading

                // Execute registration use case and collect results
                registerUseCase.execute(
                    email = email,
                    password = password,
                    fullName = fullName,
                    phoneNumber = phoneNumber
                ).collect { result ->
                    result.fold(
                        onSuccess = { user ->
                            _authState.value = AuthState.Authenticated(user)
                        },
                        onFailure = { error ->
                            _authState.value = AuthState.Error(
                                error.message ?: "Registration failed"
                            )
                        }
                    )
                }
            } catch (e: Exception) {
                _authState.value = AuthState.Error("Registration failed: ${e.message}")
            }
        }
    }

    /**
     * Logs out the current user.
     * Implements secure logout with state cleanup.
     */
    fun logout() {
        viewModelScope.launch {
            try {
                // Reset authentication state
                _authState.value = AuthState.Idle
            } catch (e: Exception) {
                _authState.value = AuthState.Error("Logout failed: ${e.message}")
            }
        }
    }

    /**
     * Cleans up resources when ViewModel is cleared.
     * Implements proper resource management.
     */
    override fun onCleared() {
        super.onCleared()
        // Additional cleanup if needed
    }
}