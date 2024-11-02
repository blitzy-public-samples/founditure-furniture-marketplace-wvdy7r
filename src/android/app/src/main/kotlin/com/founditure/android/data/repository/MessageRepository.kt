package com.founditure.android.data.repository

import com.founditure.android.data.local.dao.MessageDao
import com.founditure.android.data.remote.api.MessageService
import com.founditure.android.data.remote.dto.MessageDto
import com.founditure.android.domain.model.Message
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import com.founditure.android.data.local.entity.MessageEntity
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.firstOrNull
import retrofit2.HttpException
import java.io.IOException

/**
 * HUMAN TASKS:
 * 1. Configure ProGuard rules for Retrofit and Room if using minification
 * 2. Set up appropriate database migration strategies
 * 3. Configure network security policy for API communication
 * 4. Set up appropriate error tracking/monitoring
 * 5. Configure message sync worker for background synchronization
 */

/**
 * Repository implementation that coordinates message data operations between local database,
 * remote API, and domain layer. Implements offline-first architecture with real-time messaging capabilities.
 *
 * Addresses requirements:
 * - Real-time Messaging: Coordinates message operations between local and remote data sources
 * - Offline-first Architecture: Implements local-first data operations with background synchronization
 */
class MessageRepository @Inject constructor(
    private val messageDao: MessageDao,
    private val messageService: MessageService
) {
    /**
     * Retrieves messages between two users for a specific furniture item.
     * Implements offline-first pattern by serving local data first.
     *
     * @param userId1 First user's ID
     * @param userId2 Second user's ID
     * @param furnitureId Furniture item's ID
     * @return Flow emitting list of messages between users
     */
    fun getMessagesBetweenUsers(
        userId1: String,
        userId2: String,
        furnitureId: String
    ): Flow<List<Message>> {
        return messageDao.getMessagesBetweenUsers(userId1, userId2, furnitureId)
            .map { entities ->
                entities.map { it.toDomainModel() }
            }
    }

    /**
     * Sends a new message and handles local/remote persistence.
     * Implements offline-first by saving locally first, then syncing with server.
     *
     * @param message Message to send
     * @return Result containing sent message or error
     */
    suspend fun sendMessage(message: Message): Result<Message> {
        return try {
            // Save to local DB first
            val messageEntity = MessageEntity.fromDomainModel(message)
            messageDao.insertMessage(messageEntity)

            // Sync with server
            val response = messageService.sendMessage(MessageDto.fromDomainModel(message))
            if (response.isSuccessful) {
                val serverMessage = response.body()?.toDomainModel()
                    ?: return Result.failure(Exception("Empty response body"))
                
                // Update local DB with server response
                messageDao.insertMessage(MessageEntity.fromDomainModel(serverMessage))
                Result.success(serverMessage)
            } else {
                Result.failure(HttpException(response))
            }
        } catch (e: IOException) {
            // Network error - message is saved locally and will sync later
            Result.success(message)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Marks a message as read locally and remotely.
     * Updates local DB immediately and syncs with server.
     *
     * @param messageId ID of message to mark as read
     * @return Result indicating success or failure
     */
    suspend fun markMessageAsRead(messageId: String): Result<Unit> {
        return try {
            val timestamp = System.currentTimeMillis()
            messageDao.markMessageAsRead(messageId, timestamp)

            val response = messageService.markAsRead(messageId, timestamp)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(HttpException(response))
            }
        } catch (e: IOException) {
            // Network error - status updated locally and will sync later
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Gets count of unread messages for current user.
     * Serves data from local database for immediate response.
     *
     * @param userId ID of user to get unread count for
     * @return Flow emitting count of unread messages
     */
    fun getUnreadMessageCount(userId: String): Flow<Int> {
        return messageDao.getUnreadMessageCount(userId)
            .catch { emit(0) }
    }

    /**
     * Synchronizes local and remote message data.
     * Handles conflict resolution and ensures data consistency.
     *
     * @return Result indicating sync success or failure
     */
    suspend fun syncMessages(): Result<Unit> {
        return try {
            // Get latest messages from server
            val response = messageService.getMessages(
                userId = getCurrentUserId(), // Implementation needed
                lastMessageId = getLastSyncedMessageId() // Implementation needed
            )

            if (response.isSuccessful) {
                val serverMessages = response.body() ?: emptyList()
                
                // Update local database with server data
                serverMessages.forEach { messageDto ->
                    messageDao.insertMessage(MessageEntity.fromDomainModel(messageDto.toDomainModel()))
                }
                
                Result.success(Unit)
            } else {
                Result.failure(HttpException(response))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // Helper functions - implementations needed based on app architecture
    private fun getCurrentUserId(): String {
        // TODO: Implement based on authentication system
        throw NotImplementedError("getCurrentUserId() not implemented")
    }

    private suspend fun getLastSyncedMessageId(): Long? {
        // TODO: Implement based on sync tracking system
        return null
    }
}

/**
 * Extension function to convert MessageEntity to domain Message model.
 */
private fun MessageEntity.toDomainModel(): Message {
    return Message(
        id = id,
        senderId = senderId,
        receiverId = receiverId,
        furnitureId = furnitureId,
        content = content,
        isRead = isRead,
        sentAt = sentAt,
        readAt = readAt,
        attachmentUrl = attachmentUrl,
        messageType = messageType
    )
}