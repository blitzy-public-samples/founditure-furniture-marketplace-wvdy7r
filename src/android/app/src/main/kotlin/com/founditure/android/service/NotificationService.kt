/*
 * Human Tasks:
 * 1. Configure Firebase Cloud Messaging in the Firebase Console
 * 2. Add google-services.json to the app directory
 * 3. Configure notification channels in device settings
 * 4. Set up notification icons in res/drawable
 * 5. Add required permissions in AndroidManifest.xml:
 *    - <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
 *    - <uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
 */

package com.founditure.android.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.founditure.android.MainActivity
import com.founditure.android.R
import com.founditure.android.domain.model.Furniture
import com.founditure.android.domain.model.Message
import com.founditure.android.util.Constants.ContentType
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * Service class responsible for handling push notifications in the Founditure Android application.
 * Implements requirements from:
 * - Push Notifications (1.2 Scope/Included Features)
 * - Real-time Messaging (1.2 Scope/Core System Components/Backend Services)
 * - Points System (1.2 Scope/Included Features)
 */
@AndroidEntryPoint
class NotificationService : FirebaseMessagingService() {

    @Inject
    lateinit var notificationManager: NotificationManager

    private val serviceScope = CoroutineScope(Dispatchers.IO)

    companion object {
        private const val CHANNEL_FURNITURE_ID = "furniture_notifications"
        private const val CHANNEL_MESSAGES_ID = "message_notifications"
        private const val CHANNEL_POINTS_ID = "points_notifications"
        
        private const val NOTIFICATION_ID_FURNITURE = 1001
        private const val NOTIFICATION_ID_MESSAGE = 1002
        private const val NOTIFICATION_ID_POINTS = 1003
        
        private const val PENDING_INTENT_FLAGS = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    /**
     * Handles new FCM token generation.
     * Implements requirement: Push Notifications system for real-time user engagement
     */
    override fun onNewToken(token: String) {
        Timber.d("New FCM token: $token")
        serviceScope.launch {
            try {
                // TODO: Send token to backend server
                // userRepository.updateFcmToken(token)
            } catch (e: Exception) {
                Timber.e(e, "Failed to update FCM token")
            }
        }
    }

    /**
     * Processes incoming FCM messages and creates appropriate notifications.
     * Implements requirements for furniture listings, messages, and points notifications
     */
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Timber.d("Received FCM message: ${remoteMessage.data}")

        remoteMessage.data.let { data ->
            when (data["type"]) {
                ContentType.FURNITURE.name -> handleFurnitureNotification(data)
                ContentType.MESSAGE.name -> handleMessageNotification(data)
                "POINTS" -> handlePointsNotification(data)
                else -> Timber.w("Unknown notification type: ${data["type"]}")
            }
        }
    }

    /**
     * Creates notification channels for different notification types.
     * Required for Android O and above.
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val furnitureChannel = NotificationChannel(
                CHANNEL_FURNITURE_ID,
                "Furniture Updates",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications about furniture listings"
                enableVibration(true)
            }

            val messagesChannel = NotificationChannel(
                CHANNEL_MESSAGES_ID,
                "Messages",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Chat message notifications"
                enableVibration(true)
            }

            val pointsChannel = NotificationChannel(
                CHANNEL_POINTS_ID,
                "Points & Achievements",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Points and achievements updates"
                enableVibration(true)
            }

            notificationManager.createNotificationChannels(
                listOf(furnitureChannel, messagesChannel, pointsChannel)
            )
        }
    }

    /**
     * Handles furniture-related notifications.
     * Implements requirement: Push notification system for furniture listings
     */
    private fun handleFurnitureNotification(data: Map<String, String>) {
        val furniture = Furniture(
            id = data["furnitureId"] ?: return,
            userId = data["userId"] ?: return,
            title = data["title"] ?: "New Furniture",
            description = data["description"] ?: "",
            category = data["category"] ?: "other",
            condition = data["condition"] ?: "good",
            dimensions = mapOf(),
            material = data["material"] ?: "",
            isAvailable = data["isAvailable"]?.toBoolean() ?: true,
            aiMetadata = mapOf(),
            location = null,
            createdAt = System.currentTimeMillis(),
            expiresAt = System.currentTimeMillis() + (7 * 24 * 60 * 60 * 1000) // 7 days
        )

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("furnitureId", furniture.id)
            putExtra("notificationType", ContentType.FURNITURE.name)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            NOTIFICATION_ID_FURNITURE,
            intent,
            PENDING_INTENT_FLAGS
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_FURNITURE_ID)
            .setSmallIcon(R.drawable.ic_notification_furniture)
            .setContentTitle(furniture.title)
            .setContentText(furniture.description)
            .setAutoCancel(true)
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        notificationManager.notify(NOTIFICATION_ID_FURNITURE, notification)
    }

    /**
     * Handles message notifications.
     * Implements requirement: Real-time notification delivery for messaging system
     */
    private fun handleMessageNotification(data: Map<String, String>) {
        val message = Message(
            id = data["messageId"] ?: return,
            senderId = data["senderId"] ?: return,
            receiverId = data["receiverId"] ?: return,
            furnitureId = data["furnitureId"] ?: "",
            content = data["content"] ?: "",
            isRead = false,
            sentAt = System.currentTimeMillis(),
            readAt = null,
            attachmentUrl = data["attachmentUrl"],
            messageType = data["messageType"] ?: Message.TYPE_TEXT
        )

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("chatId", "${message.senderId}_${message.receiverId}")
            putExtra("notificationType", ContentType.MESSAGE.name)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            NOTIFICATION_ID_MESSAGE,
            intent,
            PENDING_INTENT_FLAGS
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_MESSAGES_ID)
            .setSmallIcon(R.drawable.ic_notification_message)
            .setContentTitle(data["senderName"] ?: "New Message")
            .setContentText(message.content)
            .setAutoCancel(true)
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        notificationManager.notify(NOTIFICATION_ID_MESSAGE, notification)
    }

    /**
     * Handles points and achievements notifications.
     * Implements requirement: Notifications for points and achievements updates
     */
    private fun handlePointsNotification(data: Map<String, String>) {
        val points = data["points"]?.toIntOrNull() ?: 0
        val reason = data["reason"] ?: "Achievement unlocked!"

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("showPoints", true)
            putExtra("notificationType", "POINTS")
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            NOTIFICATION_ID_POINTS,
            intent,
            PENDING_INTENT_FLAGS
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_POINTS_ID)
            .setSmallIcon(R.drawable.ic_notification_points)
            .setContentTitle("Points Update")
            .setContentText("$reason (+$points points)")
            .setAutoCancel(true)
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        notificationManager.notify(NOTIFICATION_ID_POINTS, notification)
    }
}