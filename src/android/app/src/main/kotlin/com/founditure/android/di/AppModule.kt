/**
 * Human Tasks:
 * 1. Ensure proper Dagger Hilt setup in build.gradle
 * 2. Configure ProGuard rules for dependency injection
 * 3. Verify proper AndroidManifest.xml application name setup
 * 4. Set up proper test configurations for dependency injection
 */

package com.founditure.android.di

import android.content.Context
import com.founditure.android.config.AppConfig
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.CoroutineDispatcher
import javax.inject.Singleton

/**
 * Primary Dagger Hilt module providing application-level dependencies
 * Implements requirements from:
 * - Mobile Applications (1.2 Scope/Core System Components/1. Mobile Applications)
 * - System Architecture (3.1 High-Level Architecture Overview)
 */
@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    /**
     * Provides the application context for dependency injection
     * Required for Android-specific operations and services
     * Implements requirements from Mobile Applications section 1.2
     */
    @Provides
    @Singleton
    fun provideApplicationContext(
        @ApplicationContext context: Context
    ): Context = context

    /**
     * Provides coroutine dispatcher for background operations
     * Essential for implementing offline-first architecture
     * Implements requirements from Mobile Applications section 1.2
     */
    @Provides
    @Singleton
    fun provideCoroutineDispatcher(): CoroutineDispatcher = Dispatchers.IO

    /**
     * Provides application configuration instance
     * Centralizes configuration management for the application
     * Implements requirements from System Architecture section 3.1
     */
    @Provides
    @Singleton
    fun provideAppConfig(): AppConfig = AppConfig
}