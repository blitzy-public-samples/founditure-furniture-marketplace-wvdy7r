/*
 * HUMAN TASKS:
 * 1. Configure analytics events for message interactions
 * 2. Verify accessibility labels for screen reader support
 * 3. Test RTL layout support for chat interface
 * 4. Review offline message queue configuration
 * 5. Set up proper error tracking integration
 */

package com.founditure.android.presentation.messages

import androidx.compose.foundation.layout.* // v1.5.0
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.* // v1.1.0
import androidx.compose.runtime.* // v1.5.0
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel // v1.0.0
import com.founditure.android.domain.model.Message
import com.founditure.android.presentation.components.ChatBubble
import kotlinx.coroutines.launch

/**
 * Main composable function that renders the chat screen interface.
 * Implements Material Design 3 guidelines with real-time messaging support.
 *
 * Addresses requirements:
 * - Real-time Messaging: Implements real-time message display and interaction
 * - Mobile-first Platform: Native Android UI implementation
 * - Offline-first Architecture: Handles message state with offline support
 *
 * @param currentUserId ID of the current user
 * @param otherUserId ID of the other user in the conversation
 * @param furnitureId ID of the furniture item being discussed
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
fun ChatScreen(
    currentUserId: String,
    otherUserId: String,
    furnitureId: String,
    modifier: Modifier = Modifier
) {
    val viewModel: MessageViewModel = hiltViewModel()
    val uiState by viewModel.uiState.collectAsState()
    val scope = rememberCoroutineScope()
    val listState = rememberLazyListState()
    
    // Load messages when the screen is first composed
    LaunchedEffect(currentUserId, otherUserId, furnitureId) {
        viewModel.loadMessages(currentUserId, otherUserId, furnitureId)
    }

    // Scroll to bottom when new messages arrive
    LaunchedEffect(uiState.messages.size) {
        if (uiState.messages.isNotEmpty()) {
            listState.animateScrollToItem(uiState.messages.size - 1)
        }
    }

    Scaffold(
        topBar = {
            ChatTopBar(
                otherUserId = otherUserId,
                onBackClick = { /* Handle navigation */ }
            )
        },
        bottomBar = {
            MessageInput(
                text = rememberSaveable { mutableStateOf("") },
                onSendClick = { text ->
                    viewModel.sendMessage(
                        senderId = currentUserId,
                        receiverId = otherUserId,
                        furnitureId = furnitureId,
                        content = text
                    )
                },
                isSending = uiState.isSending
            )
        },
        modifier = modifier
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Message list
            MessageList(
                messages = uiState.messages,
                currentUserId = currentUserId,
                listState = listState,
                modifier = Modifier.fillMaxSize()
            )

            // Loading indicator
            if (uiState.isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center)
                )
            }

            // Error snackbar
            uiState.error?.let { error ->
                LaunchedEffect(error) {
                    scope.launch {
                        SnackbarHostState().showSnackbar(
                            message = error,
                            duration = SnackbarDuration.Short
                        )
                        viewModel.clearError()
                    }
                }
            }
        }
    }
}

/**
 * Composable function that renders the list of messages.
 *
 * @param messages List of messages to display
 * @param currentUserId ID of the current user
 * @param listState State object for the lazy list
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
private fun MessageList(
    messages: List<Message>,
    currentUserId: String,
    listState: LazyListState,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        state = listState,
        reverseLayout = false,
        contentPadding = PaddingValues(vertical = 8.dp),
        modifier = modifier
    ) {
        items(
            items = messages,
            key = { message -> message.id }
        ) { message ->
            ChatBubble(
                message = message,
                currentUserId = currentUserId,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

/**
 * Composable function that renders the message input field.
 *
 * @param text State holder for input text
 * @param onSendClick Callback for send button click
 * @param isSending Whether a message is currently being sent
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
private fun MessageInput(
    text: MutableState<String>,
    onSendClick: (String) -> Unit,
    isSending: Boolean,
    modifier: Modifier = Modifier
) {
    Surface(
        tonalElevation = 2.dp,
        modifier = modifier
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Text input field
            OutlinedTextField(
                value = text.value,
                onValueChange = { text.value = it },
                placeholder = { Text("Type a message") },
                modifier = Modifier
                    .weight(1f)
                    .padding(end = 8.dp),
                enabled = !isSending,
                singleLine = true
            )

            // Send button
            IconButton(
                onClick = {
                    if (text.value.isNotBlank()) {
                        onSendClick(text.value)
                        text.value = ""
                    }
                },
                enabled = text.value.isNotBlank() && !isSending
            ) {
                Icon(
                    painter = painterResource(id = android.R.drawable.ic_menu_send),
                    contentDescription = "Send message",
                    tint = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}

/**
 * Composable function that renders the chat screen top bar.
 *
 * @param otherUserId ID of the other user in the conversation
 * @param onBackClick Callback for back button click
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
private fun ChatTopBar(
    otherUserId: String,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    TopAppBar(
        title = { Text(otherUserId) }, // TODO: Replace with user's display name
        navigationIcon = {
            IconButton(onClick = onBackClick) {
                Icon(
                    painter = painterResource(id = android.R.drawable.ic_menu_close_clear_cancel),
                    contentDescription = "Navigate back"
                )
            }
        },
        modifier = modifier
    )
}