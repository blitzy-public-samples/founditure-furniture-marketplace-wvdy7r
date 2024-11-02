/**
 * Human Tasks:
 * 1. Configure ProGuard rules for OkHttp WebSocket
 * 2. Set up proper WebSocket URL in NetworkConfig for each environment
 * 3. Configure proper SSL certificate pinning for WebSocket connections
 * 4. Set up appropriate logging levels for WebSocket events in production
 */

package com.founditure.android.service

import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.lifecycle.LifecycleService
import com.founditure.android.config.NetworkConfig
import com.founditure.android.domain.model.Message
import com.squareup.moshi.Moshi // v1.14.0
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.* // v1.7.1
import kotlinx.coroutines.flow.*
import okhttp3.* // v4.11.0
import okhttp3.logging.HttpLoggingInterceptor
import java.util.concurrent.TimeUnit
import javax.inject.Inject

/**
 * Service class managing WebSocket connections and real-time messaging.
 * Implements requirements:
 * - Real-time Messaging (4.2.2): WebSocket-based messaging system
 * - Mobile Applications (1.2): Native Android real-time capabilities
 * - System Interactions (3.4): WebSocket communication implementation
 */
@AndroidEntryPoint
class WebSocketService : LifecycleService() {

    private var webSocket: WebSocket? = null
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var reconnectionJob: Job? = null
    
    private val _connectionState = MutableStateFlow(WebSocketState.DISCONNECTED)
    val connectionState: StateFlow<WebSocketState> = _connectionState.asStateFlow()
    
    private val _messageFlow = MutableSharedFlow<Message>()
    val messageFlow: SharedFlow<Message> = _messageFlow.asSharedFlow()
    
    private val moshi = Moshi.Builder()
        .add(KotlinJsonAdapterFactory())
        .build()
    
    private val messageAdapter = moshi.adapter(Message::class.java)
    
    private val webSocketClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BASIC
        })
        .build()

    override fun onCreate() {
        super.onCreate()
        connect()
    }

    override fun onBind(intent: Intent): IBinder? {
        super.onBind(intent)
        return null
    }

    /**
     * Establishes WebSocket connection with the server.
     * Implements Real-time Messaging requirement (4.2.2)
     */
    fun connect() {
        if (_connectionState.value == WebSocketState.CONNECTING || 
            _connectionState.value == WebSocketState.CONNECTED) {
            return
        }

        _connectionState.value = WebSocketState.CONNECTING

        val request = Request.Builder()
            .url(NetworkConfig.wsUrl)
            .build()

        webSocket = webSocketClient.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                _connectionState.value = WebSocketState.CONNECTED
                reconnectionJob?.cancel()
                startHeartbeat()
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                serviceScope.launch {
                    try {
                        val message = messageAdapter.fromJson(text)
                        message?.let {
                            _messageFlow.emit(it)
                        }
                    } catch (e: Exception) {
                        _connectionState.value = WebSocketState.ERROR
                    }
                }
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                webSocket.close(1000, null)
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                _connectionState.value = WebSocketState.ERROR
                startReconnectionJob()
            }
        })
    }

    /**
     * Gracefully closes the WebSocket connection.
     * Implements System Interactions requirement (3.4)
     */
    fun disconnect() {
        reconnectionJob?.cancel()
        webSocket?.close(1000, "User initiated disconnect")
        webSocket = null
        _connectionState.value = WebSocketState.DISCONNECTED
        serviceScope.cancel()
    }

    /**
     * Sends a message through the WebSocket connection.
     * Implements Real-time Messaging requirement (4.2.2)
     *
     * @param message Message to be sent
     * @return Boolean indicating success of message sending
     */
    fun sendMessage(message: Message): Boolean {
        if (_connectionState.value != WebSocketState.CONNECTED) {
            return false
        }

        return try {
            val messageJson = messageAdapter.toJson(message)
            webSocket?.send(messageJson) ?: false
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Initiates automatic reconnection attempts with exponential backoff.
     * Implements Mobile Applications requirement (1.2)
     */
    private fun startReconnectionJob() {
        reconnectionJob?.cancel()
        reconnectionJob = serviceScope.launch {
            var attemptCount = 0
            val maxAttempts = 5
            
            while (isActive && attemptCount < maxAttempts) {
                _connectionState.value = WebSocketState.RECONNECTING
                delay(calculateBackoffDelay(attemptCount))
                connect()
                attemptCount++
            }
            
            if (attemptCount >= maxAttempts) {
                _connectionState.value = WebSocketState.ERROR
            }
        }
    }

    /**
     * Calculates exponential backoff delay for reconnection attempts.
     *
     * @param attempt Current attempt number
     * @return Delay duration in milliseconds
     */
    private fun calculateBackoffDelay(attempt: Int): Long {
        return minOf(
            1000L * (1L shl attempt), // Exponential backoff
            30000L // Max delay of 30 seconds
        )
    }

    /**
     * Maintains connection with periodic heartbeat messages.
     * Implements System Interactions requirement (3.4)
     */
    private fun startHeartbeat() {
        serviceScope.launch {
            while (isActive && _connectionState.value == WebSocketState.CONNECTED) {
                webSocket?.send("ping")
                delay(30000) // 30 seconds interval
            }
        }
    }

    override fun onDestroy() {
        disconnect()
        super.onDestroy()
    }
}

/**
 * Enum representing possible WebSocket connection states.
 */
enum class WebSocketState {
    CONNECTING,
    CONNECTED,
    DISCONNECTED,
    RECONNECTING,
    ERROR
}