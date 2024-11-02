/**
 * Human Tasks:
 * 1. Ensure proper SSL certificate pinning hashes are configured for production environment
 * 2. Verify network security config XML is properly set up in res/xml/network_security_config.xml
 * 3. Configure ProGuard rules for OkHttp and Retrofit
 * 4. Set up proper logging rules for different build variants
 */

package com.founditure.android.config

import com.founditure.android.BuildConfig
import com.founditure.android.util.API
import com.squareup.moshi.Moshi // v1.14.0
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import okhttp3.CertificatePinner
import okhttp3.OkHttpClient // v4.11.0
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit // v2.9.0
import retrofit2.converter.moshi.MoshiConverterFactory
import java.util.concurrent.TimeUnit

/**
 * Network configuration object containing all network-related settings for the Founditure application.
 * Implements requirements from:
 * - Mobile Applications (1.2): Native Android application with offline-first architecture
 * - Network Security (7.3.1): Implementation of secure network protocols and configurations
 * - System Architecture (3.1): API Gateway and service layer configuration
 */
object NetworkConfig {
    // API endpoint configuration
    val apiUrl = "${API.BASE_URL}/api/${API.API_VERSION}"
    val wsUrl = API.BASE_URL.replace("https", "wss") + "/ws"
    
    // Timeout configurations
    val connectTimeout = API.TIMEOUT_CONNECT
    val readTimeout = API.TIMEOUT_READ
    
    // Security configurations
    val enableCertificatePinning = true
    val certificateHashes = setOf(
        "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", // Replace with actual certificate hash
        "sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=" // Backup certificate hash
    )

    /**
     * Creates and configures OkHttpClient instance with security settings.
     * Implements Network Security requirement (7.3.1)
     */
    fun createOkHttpClient(): OkHttpClient {
        return OkHttpClient.Builder().apply {
            // Configure timeouts
            connectTimeout(connectTimeout, TimeUnit.SECONDS)
            readTimeout(readTimeout, TimeUnit.SECONDS)
            
            // Configure certificate pinning
            if (enableCertificatePinning) {
                certificatePinner(
                    CertificatePinner.Builder().apply {
                        certificateHashes.forEach { hash ->
                            add(API.BASE_URL.removePrefix("https://"), hash)
                        }
                    }.build()
                )
            }

            // Configure TLS settings
            connectionSpecs(listOf(
                okhttp3.ConnectionSpec.MODERN_TLS,
                okhttp3.ConnectionSpec.COMPATIBLE_TLS
            ))

            // Add logging interceptor for debug builds
            if (BuildConfig.DEBUG) {
                addInterceptor(HttpLoggingInterceptor().apply {
                    level = HttpLoggingInterceptor.Level.BODY
                })
            }

            // Add authentication interceptor
            addInterceptor { chain ->
                val original = chain.request()
                val requestBuilder = original.newBuilder()
                    .header("Accept", "application/json")
                    .header("Content-Type", "application/json")
                    .method(original.method, original.body)
                
                chain.proceed(requestBuilder.build())
            }
        }.build()
    }

    /**
     * Creates and configures Retrofit instance for API communication.
     * Implements System Architecture requirement (3.1)
     */
    fun createRetrofitInstance(client: OkHttpClient): Retrofit {
        val moshi = Moshi.Builder()
            .add(KotlinJsonAdapterFactory())
            .build()

        return Retrofit.Builder()
            .baseUrl(apiUrl)
            .client(client)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
    }
}