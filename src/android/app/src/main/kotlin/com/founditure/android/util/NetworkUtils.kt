/**
 * Human Tasks:
 * 1. Configure network security config in res/xml/network_security_config.xml
 * 2. Set up certificate pinning for production API endpoints
 * 3. Configure ProGuard rules for OkHttp and Coroutines
 * 4. Ensure proper permissions in AndroidManifest.xml: ACCESS_NETWORK_STATE, INTERNET
 * 5. Review and adjust timeout values for different network conditions
 */

package com.founditure.android.util

import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.delay
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import okhttp3.CertificatePinner
import java.util.concurrent.TimeUnit
import javax.net.ssl.SSLSocketFactory
import javax.net.ssl.X509TrustManager

/**
 * Implements requirements:
 * - Mobile Applications: Native Android application with offline-first architecture
 * - Network Security: Implementation of secure network protocols and monitoring
 */

/**
 * Enum representing different network quality levels
 */
enum class NetworkQuality {
    POOR,      // < 150 kbps
    MODERATE,  // 150 kbps - 550 kbps
    GOOD,      // 550 kbps - 2000 kbps
    EXCELLENT  // > 2000 kbps
}

/**
 * Data class representing the current network state
 */
data class NetworkState(
    val isConnected: Boolean,
    val quality: NetworkQuality,
    val connectionType: String
)

/**
 * Singleton object providing network utility functions
 */
object NetworkUtils {
    private lateinit var connectivityManager: ConnectivityManager
    private val okHttpClient: OkHttpClient by lazy { createOkHttpClient() }
    private val networkStateFlow = flow {
        while (true) {
            emit(NetworkState(
                isConnected = isNetworkAvailable(),
                quality = getNetworkQuality(),
                connectionType = getConnectionType()
            ))
            delay(1000) // Check network state every second
        }
    }

    /**
     * Initializes NetworkUtils with ConnectivityManager
     */
    fun initialize(connectivityManager: ConnectivityManager) {
        this.connectivityManager = connectivityManager
    }

    /**
     * Creates and configures OkHttpClient instance with security settings
     * Implements Network Security requirement
     */
    private fun createOkHttpClient(): OkHttpClient {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG) {
                HttpLoggingInterceptor.Level.BODY
            } else {
                HttpLoggingInterceptor.Level.NONE
            }
        }

        val certificatePinner = CertificatePinner.Builder()
            .add("api.founditure.com", "sha256/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
            .build()

        return OkHttpClient.Builder()
            .connectTimeout(API.TIMEOUT_CONNECT, TimeUnit.SECONDS)
            .readTimeout(API.TIMEOUT_READ, TimeUnit.SECONDS)
            .addInterceptor(loggingInterceptor)
            .addInterceptor { chain ->
                val request = chain.request().newBuilder()
                    .addHeader("Accept", "application/json")
                    .addHeader("Content-Type", "application/json")
                    .build()
                chain.proceed(request)
            }
            .certificatePinner(certificatePinner)
            .retryOnConnectionFailure(true)
            .build()
    }

    /**
     * Checks if network connection is available
     * Implements Mobile Applications requirement for offline-first architecture
     */
    fun isNetworkAvailable(): Boolean {
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
    }

    /**
     * Determines current network connection quality based on bandwidth
     * Implements Network Security requirement for monitoring
     */
    fun getNetworkQuality(): NetworkQuality {
        val network = connectivityManager.activeNetwork ?: return NetworkQuality.POOR
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return NetworkQuality.POOR
        
        return when {
            !capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) -> NetworkQuality.POOR
            capabilities.getLinkDownstreamBandwidthKbps() > 2000 -> NetworkQuality.EXCELLENT
            capabilities.getLinkDownstreamBandwidthKbps() > 550 -> NetworkQuality.GOOD
            capabilities.getLinkDownstreamBandwidthKbps() > 150 -> NetworkQuality.MODERATE
            else -> NetworkQuality.POOR
        }
    }

    /**
     * Gets the current connection type (WiFi, Cellular, etc.)
     */
    private fun getConnectionType(): String {
        val network = connectivityManager.activeNetwork ?: return "None"
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return "None"
        
        return when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "WiFi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "Cellular"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "Ethernet"
            else -> "Unknown"
        }
    }

    /**
     * Monitors network state changes and emits updates
     * Implements Network Security requirement for monitoring
     */
    fun monitorNetworkState(): Flow<NetworkState> = networkStateFlow

    /**
     * Executes network operation with retry logic
     * Implements Mobile Applications requirement for offline-first architecture
     */
    suspend fun <T> executeWithRetry(
        operation: suspend () -> T,
        maxRetries: Int = API.MAX_RETRIES
    ): T {
        var attempts = 0
        var lastException: Exception? = null

        while (attempts < maxRetries) {
            try {
                return operation()
            } catch (e: Exception) {
                lastException = e
                attempts++
                
                if (attempts < maxRetries) {
                    // Exponential backoff
                    val backoffDelay = (Math.pow(2.0, attempts.toDouble()) * 1000).toLong()
                    delay(backoffDelay)
                }
            }
        }

        throw lastException ?: IllegalStateException("Operation failed after $maxRetries attempts")
    }

    /**
     * Gets the configured OkHttpClient instance
     */
    fun getOkHttpClient(): OkHttpClient = okHttpClient
}