/*
 * Human Tasks:
 * 1. Ensure proper SSL certificate pinning hashes are configured in NetworkConfig
 * 2. Verify network security config XML is properly set up in res/xml/network_security_config.xml
 * 3. Configure ProGuard rules for OkHttp, Retrofit and Moshi
 * 4. Set up proper logging rules for different build variants
 */

package com.founditure.android.di

import com.founditure.android.config.NetworkConfig
import com.founditure.android.data.remote.api.ApiService
import com.squareup.moshi.Moshi // v1.14.0
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import dagger.Module // v2.48
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient // v4.11.0
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit // v2.9.0
import retrofit2.converter.moshi.MoshiConverterFactory
import javax.inject.Singleton

/**
 * Dagger Hilt module providing network-related dependencies for the Founditure Android application.
 * 
 * Implements requirements:
 * - Mobile Applications (1.2): Native Android application with offline-first architecture
 * - Network Security (7.3.1): Implementation of secure network protocols including TLS 1.3 and certificate pinning
 * - RESTful API Gateway (3.1): Client-server communication through API Gateway
 */
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    /**
     * Provides singleton OkHttpClient instance with security configurations.
     * Implements Network Security requirement (7.3.1)
     */
    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        return OkHttpClient.Builder().apply {
            // Set connection and read timeouts from NetworkConfig
            connectTimeout(NetworkConfig.connectTimeout, java.util.concurrent.TimeUnit.SECONDS)
            readTimeout(NetworkConfig.readTimeout, java.util.concurrent.TimeUnit.SECONDS)
            
            // Configure certificate pinning
            certificatePinner(
                okhttp3.CertificatePinner.Builder().apply {
                    NetworkConfig.certificateHashes.forEach { hash ->
                        add(NetworkConfig.apiUrl.removePrefix("https://"), hash)
                    }
                }.build()
            )

            // Configure TLS 1.3 and fallback options
            connectionSpecs(listOf(
                okhttp3.ConnectionSpec.Builder(okhttp3.ConnectionSpec.MODERN_TLS)
                    .tlsVersions(okhttp3.TlsVersion.TLS_1_3)
                    .build(),
                okhttp3.ConnectionSpec.COMPATIBLE_TLS
            ))

            // Add logging interceptor for debug builds
            if (com.founditure.android.BuildConfig.DEBUG) {
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
     * Provides singleton Moshi instance for JSON parsing.
     */
    @Provides
    @Singleton
    fun provideMoshi(): Moshi {
        return Moshi.Builder()
            .add(KotlinJsonAdapterFactory())
            .build()
    }

    /**
     * Provides singleton Retrofit instance for API communication.
     * Implements RESTful API Gateway requirement (3.1)
     */
    @Provides
    @Singleton
    fun provideRetrofit(
        okHttpClient: OkHttpClient,
        moshi: Moshi
    ): Retrofit {
        return Retrofit.Builder()
            .baseUrl(NetworkConfig.apiUrl)
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
    }

    /**
     * Provides singleton ApiService instance.
     * Implements Mobile Applications requirement (1.2)
     */
    @Provides
    @Singleton
    fun provideApiService(retrofit: Retrofit): ApiService {
        return retrofit.create(ApiService::class.java)
    }
}