package com.founditure.android.domain.usecase.message

import com.founditure.android.data.repository.MessageRepository
import com.founditure.android.domain.model.Message
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import javax.inject.Inject

/**
 * HUMAN TASKS:
 * 1. Ensure proper error tracking is configured for production monitoring
 * 2. Set up appropriate logging levels for different environments
 * 3. Configure message pagination settings if needed for large chat histories
 */

/**
 * Use case that encapsulates the business logic for retrieving chat messages between users
 * regarding furniture items. Implements clean architecture pattern by separating domain logic
 * from data layer.
 *
 * Addresses requirements:
 * - Real-time Messaging: Provides real-time message retrieval through Flow
 * - Offline-first Architecture: Leverages repository's offline-first implementation
 */
class GetMessagesUseCase @Inject constructor(
    private val messageRepository: MessageRepository
) {
    /**
     * Operator function to execute the use case and retrieve messages between users.
     * Returns a Flow of messages to support real-time updates.
     *
     * @param currentUserId ID of the current user
     * @param otherUserId ID of the other user in the conversation
     * @param furnitureId ID of the furniture item being discussed
     * @return Flow emitting list of messages between users
     */
    operator fun invoke(
        currentUserId: String,
        otherUserId: String,
        furnitureId: String
    ): Flow<List<Message>> {
        // Validate input parameters
        require(currentUserId.isNotBlank()) { "Current user ID cannot be blank" }
        require(otherUserId.isNotBlank()) { "Other user ID cannot be blank" }
        require(furnitureId.isNotBlank()) { "Furniture ID cannot be blank" }
        
        // Get messages from repository and handle potential errors
        return messageRepository.getMessagesBetweenUsers(
            userId1 = currentUserId,
            userId2 = otherUserId,
            furnitureId = furnitureId
        ).map { messages ->
            // Sort messages by timestamp to ensure correct order
            messages.sortedBy { it.sentAt }
        }.catch { throwable ->
            // Log error and emit empty list to prevent app crashes
            // Logger.error("Error retrieving messages", throwable)
            emit(emptyList())
        }
    }
}