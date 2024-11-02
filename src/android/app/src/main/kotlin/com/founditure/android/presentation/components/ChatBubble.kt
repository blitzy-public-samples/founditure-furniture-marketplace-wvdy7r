/*
 * HUMAN TASKS:
 * 1. Verify accessibility labels are properly set for screen readers
 * 2. Test chat bubble layout with different text lengths and screen sizes
 * 3. Validate RTL language support for message layout
 */

package com.founditure.android.presentation.components

import androidx.compose.foundation.layout.* // v1.5.0
import androidx.compose.material3.* // v1.1.0
import androidx.compose.runtime.* // v1.5.0
import androidx.compose.ui.Modifier // v1.5.0
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.founditure.android.domain.model.Message
import com.founditure.android.presentation.theme.Primary
import com.founditure.android.presentation.theme.Surface
import com.founditure.android.presentation.theme.OnPrimary
import com.founditure.android.presentation.theme.OnSurface
import java.text.SimpleDateFormat
import java.util.*

/**
 * A reusable chat bubble component that renders messages in a conversation.
 * Implements Material Design 3 styling with dynamic theming support.
 * 
 * Addresses requirements:
 * - Real-time messaging: Provides visual representation of chat messages
 * - Mobile-first Platform: Native Android UI component for messaging interface
 *
 * @param message The message to display in the bubble
 * @param currentUserId The ID of the current user to determine message alignment
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
fun ChatBubble(
    message: Message,
    currentUserId: String,
    modifier: Modifier = Modifier
) {
    val isFromCurrentUser = message.isFromCurrentUser(currentUserId)
    val bubbleColor = if (isFromCurrentUser) Primary else Surface
    val textColor = if (isFromCurrentUser) OnPrimary else OnSurface
    val horizontalAlignment = if (isFromCurrentUser) Arrangement.End else Arrangement.Start

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        horizontalAlignment = if (isFromCurrentUser) androidx.compose.ui.Alignment.End 
                            else androidx.compose.ui.Alignment.Start
    ) {
        // Message content
        MessageContent(
            content = message.content,
            textColor = textColor,
            modifier = Modifier
                .padding(bottom = 4.dp)
                .widthIn(max = 280.dp)
        )

        // Attachment preview if present
        if (message.hasAttachment()) {
            Surface(
                modifier = Modifier
                    .padding(bottom = 4.dp)
                    .widthIn(max = 200.dp),
                shape = MaterialTheme.shapes.medium,
                color = bubbleColor,
                shadowElevation = 1.dp
            ) {
                Text(
                    text = "📎 Attachment",
                    color = textColor,
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(8.dp)
                )
            }
        }

        // Timestamp and read status
        MessageTimestamp(
            timestamp = message.sentAt,
            isRead = message.isRead,
            textColor = textColor.copy(alpha = 0.7f),
            modifier = Modifier.padding(start = 4.dp, end = 4.dp)
        )
    }
}

/**
 * Composable function for rendering the message text content.
 *
 * @param content The text content of the message
 * @param textColor The color to apply to the text
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
private fun MessageContent(
    content: String,
    textColor: androidx.compose.ui.graphics.Color,
    modifier: Modifier = Modifier
) {
    Surface(
        shape = MaterialTheme.shapes.medium,
        color = if (textColor == OnPrimary) Primary else Surface,
        shadowElevation = 1.dp,
        modifier = modifier
    ) {
        Text(
            text = content,
            color = textColor,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
        )
    }
}

/**
 * Composable function for rendering message timestamp and read status.
 *
 * @param timestamp The message timestamp in milliseconds
 * @param isRead Whether the message has been read
 * @param textColor The color to apply to the text
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
private fun MessageTimestamp(
    timestamp: Long,
    isRead: Boolean,
    textColor: androidx.compose.ui.graphics.Color,
    modifier: Modifier = Modifier
) {
    val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
    val formattedTime = timeFormat.format(Date(timestamp))
    
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
    ) {
        Text(
            text = formattedTime,
            color = textColor,
            style = MaterialTheme.typography.labelSmall,
            fontSize = 11.sp
        )
        
        if (isRead) {
            Text(
                text = "✓✓",
                color = textColor,
                style = MaterialTheme.typography.labelSmall,
                fontSize = 11.sp
            )
        }
    }
}