// kotlinx.parcelize v1.9.0
@file:Suppress("unused")

package com.founditure.android.domain.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

/**
 * Domain model representing a chat message between users regarding furniture items.
 * Implements Parcelable for efficient data transfer between Android components.
 * 
 * Addresses requirements:
 * - Real-time Messaging: Core message model supporting chat functionality
 * - Offline-first Architecture: Parcelable implementation for local storage and state management
 */
@Parcelize
data class Message(
    val id: String,
    val senderId: String,
    val receiverId: String,
    val furnitureId: String,
    val content: String,
    val isRead: Boolean,
    val sentAt: Long,
    val readAt: Long?,
    val attachmentUrl: String?,
    val messageType: String
) : Parcelable {

    /**
     * Checks if the message was sent by the current user.
     *
     * @param currentUserId The ID of the current user to compare against
     * @return Boolean indicating if the message was sent by the current user
     */
    fun isFromCurrentUser(currentUserId: String): Boolean {
        return senderId == currentUserId
    }

    /**
     * Checks if the message contains an attachment.
     *
     * @return Boolean indicating if the message has an attachment URL
     */
    fun hasAttachment(): Boolean {
        return !attachmentUrl.isNullOrEmpty()
    }

    /**
     * Creates a new Message instance with updated read status and timestamp.
     * Supports immutability pattern by returning a new instance.
     *
     * @return New Message instance with updated read status
     */
    fun markAsRead(): Message {
        return copy(
            isRead = true,
            readAt = System.currentTimeMillis()
        )
    }

    companion object {
        // Message types constants for type safety
        const val TYPE_TEXT = "TEXT"
        const val TYPE_IMAGE = "IMAGE"
        const val TYPE_LOCATION = "LOCATION"
        const val TYPE_SYSTEM = "SYSTEM"
    }
}