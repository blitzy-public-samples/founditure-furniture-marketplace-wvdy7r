package com.founditure.android.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.founditure.android.data.local.entity.MessageEntity
import kotlinx.coroutines.flow.Flow

/**
 * Room database Data Access Object (DAO) interface for handling message persistence operations.
 * 
 * Human Tasks:
 * 1. Verify database indices are created for optimizing query performance
 * 2. Monitor query execution plans for performance optimization
 * 3. Consider implementing database triggers for complex state changes
 * 4. Set up database backup strategy for message history
 *
 * Addresses requirements:
 * - Real-time Messaging: Local database persistence layer for real-time messaging system
 * - Offline-first Architecture: Local data persistence enabling offline message access and operations
 */
@Dao
interface MessageDao {

    /**
     * Inserts a new message into the database.
     * Uses REPLACE strategy to handle conflicts, ensuring message uniqueness.
     *
     * @param message The message entity to insert
     * @return The row ID of the inserted message
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessage(message: MessageEntity): Long

    /**
     * Updates an existing message in the database.
     * Useful for updating read status or modifying message content.
     *
     * @param message The message entity to update
     * @return Number of messages updated (should be 1 if successful)
     */
    @Update
    suspend fun updateMessage(message: MessageEntity): Int

    /**
     * Deletes a message from the database.
     * Used for message removal or cleanup operations.
     *
     * @param message The message entity to delete
     * @return Number of messages deleted (should be 1 if successful)
     */
    @Delete
    suspend fun deleteMessage(message: MessageEntity): Int

    /**
     * Retrieves a specific message by its ID.
     * Returns a Flow to observe message changes.
     *
     * @param messageId The ID of the message to retrieve
     * @return Flow emitting the message or null if not found
     */
    @Query("SELECT * FROM messages WHERE id = :messageId")
    fun getMessageById(messageId: String): Flow<MessageEntity?>

    /**
     * Retrieves all messages between two users for a specific furniture item.
     * Orders messages by sent timestamp in descending order.
     *
     * @param userId1 First user's ID
     * @param userId2 Second user's ID
     * @param furnitureId The furniture item's ID
     * @return Flow emitting list of messages between users
     */
    @Query("""
        SELECT * FROM messages 
        WHERE (senderId = :userId1 AND receiverId = :userId2 AND furnitureId = :furnitureId) 
        OR (senderId = :userId2 AND receiverId = :userId1 AND furnitureId = :furnitureId) 
        ORDER BY sentAt DESC
    """)
    fun getMessagesBetweenUsers(
        userId1: String,
        userId2: String,
        furnitureId: String
    ): Flow<List<MessageEntity>>

    /**
     * Gets count of unread messages for a user.
     * Used for notification badges and unread message indicators.
     *
     * @param userId The ID of the user to check unread messages for
     * @return Flow emitting count of unread messages
     */
    @Query("SELECT COUNT(*) FROM messages WHERE receiverId = :userId AND isRead = 0")
    fun getUnreadMessageCount(userId: String): Flow<Int>

    /**
     * Marks a message as read with current timestamp.
     * Updates both read status and read timestamp.
     *
     * @param messageId The ID of the message to mark as read
     * @param timestamp The timestamp when the message was read
     * @return Number of messages updated (should be 1 if successful)
     */
    @Query("UPDATE messages SET isRead = 1, readAt = :timestamp WHERE id = :messageId")
    suspend fun markMessageAsRead(messageId: String, timestamp: Long): Int

    /**
     * Gets the latest message for a specific furniture item.
     * Used for showing message previews in furniture listings.
     *
     * @param furnitureId The ID of the furniture item
     * @return Flow emitting the latest message or null if none exists
     */
    @Query("""
        SELECT * FROM messages 
        WHERE furnitureId = :furnitureId 
        ORDER BY sentAt DESC 
        LIMIT 1
    """)
    fun getLatestMessageForFurniture(furnitureId: String): Flow<MessageEntity?>
}