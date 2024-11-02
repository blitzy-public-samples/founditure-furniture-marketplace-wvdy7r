package com.founditure.android.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.founditure.android.domain.model.Message

/**
 * Room database entity representing a chat message between users.
 * 
 * Human Tasks:
 * 1. Ensure Room database schema version is updated when modifying this entity
 * 2. Run Room schema export to update database migrations
 * 3. Verify database indices for query performance optimization
 *
 * Addresses requirements:
 * - Real-time Messaging: Local database persistence for real-time messaging system
 * - Offline-first Architecture: Local data persistence enabling offline message access
 */
@Entity(tableName = "messages")
data class MessageEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,

    @ColumnInfo(name = "sender_id")
    val senderId: String,

    @ColumnInfo(name = "receiver_id")
    val receiverId: String,

    @ColumnInfo(name = "furniture_id")
    val furnitureId: String,

    @ColumnInfo(name = "content")
    val content: String,

    @ColumnInfo(name = "is_read")
    val isRead: Boolean,

    @ColumnInfo(name = "sent_at")
    val sentAt: Long,

    @ColumnInfo(name = "read_at")
    val readAt: Long?,

    @ColumnInfo(name = "attachment_url")
    val attachmentUrl: String?,

    @ColumnInfo(name = "message_type")
    val messageType: String
) {
    /**
     * Converts MessageEntity to domain Message model.
     * Supports clean architecture by mapping data layer to domain layer.
     *
     * @return Message Domain model representation of the message
     */
    fun toDomainModel(): Message {
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

    companion object {
        /**
         * Creates a MessageEntity from a domain Message model.
         * Supports clean architecture by mapping domain layer to data layer.
         *
         * @param message Domain model to convert
         * @return MessageEntity Database entity representation of the message
         */
        fun toEntity(message: Message): MessageEntity {
            return MessageEntity(
                id = message.id,
                senderId = message.senderId,
                receiverId = message.receiverId,
                furnitureId = message.furnitureId,
                content = message.content,
                isRead = message.isRead,
                sentAt = message.sentAt,
                readAt = message.readAt,
                attachmentUrl = message.attachmentUrl,
                messageType = message.messageType
            )
        }
    }
}