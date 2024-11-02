package com.founditure.android.presentation.messages

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.founditure.android.domain.model.Message
import com.founditure.android.domain.usecase.message.GetMessagesUseCase
import com.founditure.android.domain.usecase.message.SendMessageUseCase
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.launch

/**
 * HUMAN TASKS:
 * 1. Configure appropriate error tracking service integration
 * 2. Set up analytics events for message-related actions
 * 3. Configure appropriate logging levels for different build variants
 * 4. Review and adjust coroutine exception handling policies if needed
 */

/**
 * Data class representing the UI state for message-related screens.
 * Implements the UI state pattern for predictable state management.
 */
data class MessageUiState(
    val messages: List<Message> = emptyList(),
    val isLoading: Boolean = false,
    val isSending: Boolean = false,
    val error: String? = null
)

/**
 * ViewModel implementation for managing message-related UI state and business logic.
 * Follows MVVM architecture pattern and implements offline-first approach.
 *
 * Addresses requirements:
 * - Real-time Messaging: Manages real-time message state updates through StateFlow
 * - Offline-first Architecture: Handles message operations with offline support
 */
class MessageViewModel @Inject constructor(
    private val sendMessageUseCase: SendMessageUseCase,
    private val getMessagesUseCase: GetMessagesUseCase
) : ViewModel() {

    // Internal mutable state
    private val _uiState = MutableStateFlow(MessageUiState())
    
    // Exposed immutable state
    val uiState: StateFlow<MessageUiState> = _uiState

    /**
     * Loads messages between current user and other user for a specific furniture item.
     * Implements real-time message retrieval with error handling.
     *
     * @param currentUserId ID of the current user
     * @param otherUserId ID of the other user in the conversation
     * @param furnitureId ID of the furniture item being discussed
     */
    fun loadMessages(
        currentUserId: String,
        otherUserId: String,
        furnitureId: String
    ) {
        viewModelScope.launch {
            try {
                // Update loading state
                _uiState.value = _uiState.value.copy(
                    isLoading = true,
                    error = null
                )

                // Collect messages flow from use case
                getMessagesUseCase(
                    currentUserId = currentUserId,
                    otherUserId = otherUserId,
                    furnitureId = furnitureId
                ).catch { throwable ->
                    // Handle error state
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = throwable.message ?: "Error loading messages"
                    )
                }.collect { messages ->
                    // Update success state
                    _uiState.value = _uiState.value.copy(
                        messages = messages,
                        isLoading = false,
                        error = null
                    )
                }
            } catch (e: Exception) {
                // Handle unexpected errors
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Unexpected error occurred"
                )
            }
        }
    }

    /**
     * Sends a new message to another user regarding a furniture item.
     * Implements message sending with error handling and state updates.
     *
     * @param senderId ID of the message sender
     * @param receiverId ID of the message recipient
     * @param furnitureId ID of the furniture item being discussed
     * @param content Message content
     * @param attachmentUrl Optional URL for message attachment
     */
    fun sendMessage(
        senderId: String,
        receiverId: String,
        furnitureId: String,
        content: String,
        attachmentUrl: String? = null
    ) {
        viewModelScope.launch {
            try {
                // Update sending state
                _uiState.value = _uiState.value.copy(
                    isSending = true,
                    error = null
                )

                // Send message using use case
                sendMessageUseCase.execute(
                    senderId = senderId,
                    receiverId = receiverId,
                    furnitureId = furnitureId,
                    content = content,
                    attachmentUrl = attachmentUrl
                ).fold(
                    onSuccess = { message ->
                        // Update success state with new message
                        _uiState.value = _uiState.value.copy(
                            messages = _uiState.value.messages + message,
                            isSending = false,
                            error = null
                        )
                    },
                    onFailure = { throwable ->
                        // Handle error state
                        _uiState.value = _uiState.value.copy(
                            isSending = false,
                            error = throwable.message ?: "Error sending message"
                        )
                    }
                )
            } catch (e: Exception) {
                // Handle unexpected errors
                _uiState.value = _uiState.value.copy(
                    isSending = false,
                    error = e.message ?: "Unexpected error occurred"
                )
            }
        }
    }

    /**
     * Clears any error state in the UI.
     * Supports error state recovery.
     */
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}