package com.founditure.android.domain.usecase.message

import com.founditure.android.data.repository.MessageRepository
import com.founditure.android.domain.model.Message
import java.util.UUID
import javax.inject.Inject
import kotlinx.coroutines.flow.first

/**
 * HUMAN TASKS:
 * 1. Configure ProGuard rules for UUID class if using minification
 * 2. Set up appropriate error tracking for message sending failures
 * 3. Configure network security policy for message attachments
 * 4. Set up appropriate retry policies for failed message sends
 */

/**
 * Use case implementation for sending messages between users regarding furniture items.
 * Implements business logic for message creation, validation, and persistence.
 *
 * Addresses requirements:
 * - Real-time Messaging: Handles message creation and delivery through repository layer
 * - Offline-first Architecture: Supports offline message sending with local persistence
 */
class SendMessageUseCase @Inject constructor(
    private val messageRepository: MessageRepository
) {
    /**
     * Executes the use case to send a new message.
     * Validates input, creates message instance, and persists through repository.
     *
     * @param senderId ID of the message sender
     * @param receiverId ID of the message recipient
     * @param furnitureId ID of the furniture item being discussed
     * @param content Message content
     * @param attachmentUrl Optional URL for message attachment
     * @return Result containing sent message or error
     */
    suspend fun execute(
        senderId: String,
        receiverId: String,
        furnitureId: String,
        content: String,
        attachmentUrl: String? = null
    ): Result<Message> {
        return try {
            // Validate input parameters
            if (!validateInput(content, senderId, receiverId, furnitureId)) {
                return Result.failure(IllegalArgumentException("Invalid message parameters"))
            }

            // Create message instance
            val message = Message(
                id = UUID.randomUUID().toString(),
                senderId = senderId,
                receiverId = receiverId,
                furnitureId = furnitureId,
                content = content,
                isRead = false,
                sentAt = System.currentTimeMillis(),
                readAt = null,
                attachmentUrl = attachmentUrl,
                messageType = determineMessageType(attachmentUrl)
            )

            // Send message through repository
            messageRepository.sendMessage(message)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Validates input parameters for message sending.
     * Ensures all required fields are present and valid.
     *
     * @param content Message content
     * @param senderId Sender's ID
     * @param receiverId Receiver's ID
     * @param furnitureId Furniture item's ID
     * @return Boolean indicating if input is valid
     */
    private fun validateInput(
        content: String,
        senderId: String,
        receiverId: String,
        furnitureId: String
    ): Boolean {
        return content.isNotBlank() &&
                senderId.isNotBlank() &&
                receiverId.isNotBlank() &&
                furnitureId.isNotBlank() &&
                senderId != receiverId // Prevent self-messaging
    }

    /**
     * Determines message type based on attachment presence.
     * Supports different message types for proper rendering.
     *
     * @param attachmentUrl Optional attachment URL
     * @return String representing message type
     */
    private fun determineMessageType(attachmentUrl: String?): String {
        return when {
            attachmentUrl != null -> {
                when {
                    isImageUrl(attachmentUrl) -> Message.TYPE_IMAGE
                    isLocationUrl(attachmentUrl) -> Message.TYPE_LOCATION
                    else -> Message.TYPE_TEXT
                }
            }
            else -> Message.TYPE_TEXT
        }
    }

    /**
     * Checks if URL points to an image resource.
     *
     * @param url URL to check
     * @return Boolean indicating if URL is an image
     */
    private fun isImageUrl(url: String): Boolean {
        val imageExtensions = listOf(".jpg", ".jpeg", ".png", ".gif", ".webp")
        return imageExtensions.any { url.lowercase().endsWith(it) }
    }

    /**
     * Checks if URL points to a location resource.
     *
     * @param url URL to check
     * @return Boolean indicating if URL is a location
     */
    private fun isLocationUrl(url: String): Boolean {
        return url.contains("location/") || url.contains("maps/")
    }
}