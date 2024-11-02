package com.founditure.android.data.remote.dto

import com.founditure.android.domain.model.Message
import com.google.gson.annotations.SerializedName // gson v2.9.0
import kotlinx.serialization.JsonClass // kotlinx.serialization v1.5.0

/**
 * HUMAN TASKS:
 * 1. Ensure Gson and Kotlinx.Serialization dependencies are included in the app/build.gradle
 * 2. Configure ProGuard rules to keep DTO serialization if using minification
 */

/**
 * Data Transfer Object representing a chat message for network communication.
 * 
 * Addresses requirements:
 * - Real-time Messaging: Network data transfer object for real-time messaging system
 * - Offline-first Architecture: DTO supporting synchronization of offline messages with backend
 */
@JsonClass(generateAdapter = true)
data class MessageDto(
    @SerializedName("id")
    val id: String,

    @SerializedName("sender_id")
    val senderId: String,

    @SerializedName("receiver_id")
    val receiverId: String,

    @SerializedName("furniture_id")
    val furnitureId: String,

    @SerializedName("content")
    val content: String,

    @SerializedName("is_read")
    val isRead: Boolean,

    @SerializedName("sent_at")
    val sentAt: Long,

    @SerializedName("read_at")
    val readAt: Long?,

    @SerializedName("attachment_url")
    val attachmentUrl: String?,

    @SerializedName("message_type")
    val messageType: String
) {
    /**
     * Converts MessageDto to domain Message model.
     * 
     * @return Domain model representation of the message
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
         * Converts domain Message to MessageDto.
         * 
         * @param message Domain model to convert
         * @return Network DTO representation of the message
         */
        fun fromDomainModel(message: Message): MessageDto {
            return MessageDto(
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