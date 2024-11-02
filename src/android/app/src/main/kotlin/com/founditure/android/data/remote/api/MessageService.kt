package com.founditure.android.data.remote.api

import com.founditure.android.data.remote.dto.MessageDto
import retrofit2.Response // retrofit2 v2.9.0
import retrofit2.http.*
import kotlinx.coroutines.flow.Flow // kotlinx.coroutines v1.7.0

/**
 * HUMAN TASKS:
 * 1. Ensure Retrofit dependency is included in app/build.gradle
 * 2. Configure ProGuard rules for Retrofit if using minification
 * 3. Add this service to your Retrofit/Dagger service provider configuration
 */

/**
 * Retrofit service interface for handling message-related API endpoints.
 * 
 * Addresses requirements:
 * - Real-time Messaging: Provides API endpoints for sending and receiving messages
 * - Offline-first Architecture: Supports pagination and message synchronization
 */
interface MessageService {

    /**
     * Retrieves messages for a specific chat conversation.
     * 
     * @param userId ID of the user whose messages to retrieve
     * @param lastMessageId Optional ID of the last message for pagination
     * @param limit Maximum number of messages to return
     * @return Response containing list of messages
     */
    @GET("messages/{userId}")
    suspend fun getMessages(
        @Path("userId") userId: String,
        @Query("lastMessageId") lastMessageId: Long? = null,
        @Query("limit") limit: Int = 50
    ): Response<List<MessageDto>>

    /**
     * Sends a new message in a chat conversation.
     * 
     * @param message Message data to send
     * @return Response containing the sent message with server-generated data
     */
    @POST("messages")
    suspend fun sendMessage(
        @Body message: MessageDto
    ): Response<MessageDto>

    /**
     * Marks messages as read in a conversation.
     * 
     * @param conversationId ID of the conversation to mark as read
     * @param timestamp Timestamp of last read message
     * @return Response indicating success/failure
     */
    @PUT("messages/{conversationId}/read")
    suspend fun markAsRead(
        @Path("conversationId") conversationId: String,
        @Query("timestamp") timestamp: Long
    ): Response<Unit>

    /**
     * Deletes a specific message.
     * 
     * @param messageId ID of the message to delete
     * @return Response indicating success/failure
     */
    @DELETE("messages/{messageId}")
    suspend fun deleteMessage(
        @Path("messageId") messageId: String
    ): Response<Unit>

    /**
     * Gets count of unread messages for the user.
     * 
     * @return Response containing number of unread messages
     */
    @GET("messages/unread/count")
    suspend fun getUnreadCount(): Response<Int>
}