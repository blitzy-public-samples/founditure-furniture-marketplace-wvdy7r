/*
 * Human Tasks:
 * 1. Ensure Hilt dependencies are properly configured in build.gradle
 * 2. Verify proper ProGuard rules for Kotlin Coroutines if using code obfuscation
 * 3. Configure proper error tracking and analytics for profile operations
 * 4. Set up proper monitoring for profile data loading performance
 */

package com.founditure.android.presentation.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.founditure.android.data.repository.UserRepository
import com.founditure.android.domain.model.User
import com.founditure.android.domain.model.Points
import com.founditure.android.domain.usecase.points.GetPointsUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel implementation for the user profile screen.
 * Manages user profile data, points, and achievements state following MVVM architecture pattern.
 * 
 * Addresses requirements:
 * - User Management (1.2 Scope/Core System Components/Backend Services)
 * - Points System (1.2 Scope/Core System Components/Backend Services)
 * - Offline-first Architecture (1.2 Scope/Core System Components/Mobile Applications)
 */
@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val getPointsUseCase: GetPointsUseCase
) : ViewModel() {

    // UI state holder with initial loading state
    private val _uiState = MutableStateFlow(ProfileUiState())
    val uiState: StateFlow<ProfileUiState> = _uiState

    /**
     * Loads user profile data and points information.
     * Implements offline-first pattern by loading from local database first.
     *
     * @param userId Unique identifier of the user
     */
    fun loadUserProfile(userId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)

            try {
                // Collect user data from repository
                userRepository.getUser(userId)
                    .catch { exception ->
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            error = "Failed to load profile: ${exception.message}"
                        )
                    }
                    .collectLatest { user ->
                        // Load points data once we have user information
                        user?.let { loadUserPoints(it) }
                        
                        _uiState.value = _uiState.value.copy(
                            user = user,
                            isLoading = false
                        )
                    }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "An unexpected error occurred: ${e.message}"
                )
            }
        }
    }

    /**
     * Updates user profile information with offline support.
     * Updates local database first and syncs with remote when possible.
     *
     * @param updatedUser Updated user data
     * @return Success status of update operation
     */
    suspend fun updateUserProfile(updatedUser: User): Boolean {
        _uiState.value = _uiState.value.copy(isLoading = true, error = null)

        return try {
            val success = userRepository.updateUser(updatedUser)
            
            if (success) {
                _uiState.value = _uiState.value.copy(
                    user = updatedUser,
                    isLoading = false
                )
            } else {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "Failed to update profile"
                )
            }
            
            success
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(
                isLoading = false,
                error = "An error occurred while updating profile: ${e.message}"
            )
            false
        }
    }

    /**
     * Forces a refresh of profile data from remote source.
     * Used when user explicitly requests a refresh or after certain actions.
     */
    fun refreshProfile() {
        viewModelScope.launch {
            _uiState.value.user?.id?.let { userId ->
                _uiState.value = _uiState.value.copy(isLoading = true, error = null)

                try {
                    // Trigger repository sync
                    val syncSuccess = userRepository.syncUser(userId)
                    
                    if (!syncSuccess) {
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            error = "Failed to sync profile data"
                        )
                        return@launch
                    }

                    // Reload profile data after sync
                    loadUserProfile(userId)
                } catch (e: Exception) {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "Failed to refresh profile: ${e.message}"
                    )
                }
            }
        }
    }

    /**
     * Private helper function to load user points data.
     * Handles points and achievements retrieval and state updates.
     *
     * @param user Current user data
     */
    private fun loadUserPoints(user: User) {
        viewModelScope.launch {
            try {
                getPointsUseCase.execute(user.id)
                    .catch { exception ->
                        _uiState.value = _uiState.value.copy(
                            error = "Failed to load points: ${exception.message}"
                        )
                    }
                    .collectLatest { points ->
                        _uiState.value = _uiState.value.copy(
                            points = points
                        )
                    }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = "Failed to load points data: ${e.message}"
                )
            }
        }
    }

    /**
     * Clears current error state.
     * Called when error has been displayed to user.
     */
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }

    /**
     * Resets ViewModel state.
     * Called when navigating away from profile screen.
     */
    fun resetState() {
        _uiState.value = ProfileUiState()
    }
}

/**
 * Data class representing the UI state for the profile screen.
 * Encapsulates all data needed for profile display.
 */
data class ProfileUiState(
    val user: User? = null,
    val points: Points? = null,
    val isLoading: Boolean = false,
    val error: String? = null
)