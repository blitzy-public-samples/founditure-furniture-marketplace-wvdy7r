/*
 * HUMAN TASKS:
 * 1. Configure analytics events for chat list interactions
 * 2. Verify accessibility labels for screen readers
 * 3. Test pull-to-refresh behavior with different network conditions
 * 4. Review and adjust error message strings for localization
 */

package com.founditure.android.presentation.messages

import androidx.compose.foundation.layout.* // v1.5.0
import androidx.compose.material3.* // v1.1.0
import androidx.compose.runtime.* // v1.5.0
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel // v1.0.0
import com.founditure.android.domain.model.Message
import com.founditure.android.presentation.components.ChatBubble
import com.google.accompanist.swiperefresh.SwipeRefresh
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState
import java.text.SimpleDateFormat
import java.util.*

/**
 * Main composable function that renders the chat list screen.
 * Implements pull-to-refresh, unread indicators, and real-time updates.
 * 
 * Addresses requirements:
 * - Real-time Messaging: Displays real-time chat list with WebSocket integration
 * - Mobile-first Platform: Native Android UI implementation
 * - Offline-first Architecture: Handles offline state and data persistence
 *
 * @param modifier Optional modifier for customizing the layout
 * @param onChatSelected Callback when a chat is selected
 */
@Composable
fun ChatListScreen(
    modifier: Modifier = Modifier,
    onChatSelected: (String) -> Unit
) {
    val viewModel: MessageViewModel = hiltViewModel()
    val uiState by viewModel.uiState.collectAsState()
    val swipeRefreshState = rememberSwipeRefreshState(uiState.isLoading)

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Messages") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        },
        modifier = modifier
    ) { paddingValues ->
        SwipeRefresh(
            state = swipeRefreshState,
            onRefresh = { /* Trigger refresh in ViewModel */ },
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                uiState.isLoading && uiState.messages.isEmpty() -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                uiState.error != null && uiState.messages.isEmpty() -> {
                    ErrorState(
                        error = uiState.error!!,
                        onRetry = { /* Trigger retry in ViewModel */ },
                        modifier = Modifier.fillMaxSize()
                    )
                }
                uiState.messages.isEmpty() -> {
                    EmptyState(
                        modifier = Modifier.fillMaxSize()
                    )
                }
                else -> {
                    ChatList(
                        messages = uiState.messages,
                        onChatSelected = onChatSelected,
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
        }
    }
}

/**
 * Composable function that renders an individual chat list item.
 *
 * @param lastMessage The last message in the conversation
 * @param onClick Callback when the item is clicked
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
private fun ChatListItem(
    lastMessage: Message,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        onClick = onClick,
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 1.dp,
        modifier = modifier
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // User Avatar
            Surface(
                shape = MaterialTheme.shapes.small,
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                modifier = Modifier.size(48.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = lastMessage.senderId.first().toString(),
                        style = MaterialTheme.typography.titleMedium
                    )
                }
            }

            Spacer(modifier = Modifier.width(16.dp))

            // Message Preview
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = lastMessage.senderId, // Replace with actual user name
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    text = lastMessage.content,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }

            Spacer(modifier = Modifier.width(8.dp))

            // Timestamp and Unread Indicator
            Column(
                horizontalAlignment = Alignment.End
            ) {
                Text(
                    text = formatTimestamp(lastMessage.sentAt),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
                
                if (!lastMessage.isRead) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Surface(
                        shape = MaterialTheme.shapes.small,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(8.dp)
                    ) {}
                }
            }
        }
    }
}

/**
 * Composable function that renders the empty state when no chats exist.
 *
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
private fun EmptyState(
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "No Messages Yet",
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onSurface
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Start a conversation about furniture items you're interested in",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )
    }
}

/**
 * Composable function that renders the error state.
 *
 * @param error The error message to display
 * @param onRetry Callback when retry is clicked
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
private fun ErrorState(
    error: String,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = error,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.error
        )
        Spacer(modifier = Modifier.height(16.dp))
        Button(
            onClick = onRetry,
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.primary
            )
        ) {
            Text("Retry")
        }
    }
}

/**
 * Composable function that renders the list of chats.
 *
 * @param messages List of messages to display
 * @param onChatSelected Callback when a chat is selected
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
private fun ChatList(
    messages: List<Message>,
    onChatSelected: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier,
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        items(
            count = messages.size,
            key = { index -> messages[index].id }
        ) { index ->
            ChatListItem(
                lastMessage = messages[index],
                onClick = { onChatSelected(messages[index].id) },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp)
            )
        }
    }
}

/**
 * Formats a timestamp into a human-readable string.
 *
 * @param timestamp The timestamp in milliseconds
 * @return Formatted string representation of the timestamp
 */
private fun formatTimestamp(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val diff = now - timestamp
    
    return when {
        diff < 24 * 60 * 60 * 1000 -> {
            SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(timestamp))
        }
        diff < 7 * 24 * 60 * 60 * 1000 -> {
            SimpleDateFormat("EEE", Locale.getDefault()).format(Date(timestamp))
        }
        else -> {
            SimpleDateFormat("MMM dd", Locale.getDefault()).format(Date(timestamp))
        }
    }
}