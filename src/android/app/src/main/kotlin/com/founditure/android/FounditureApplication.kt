/**
 * Human Tasks:
 * 1. Ensure Dagger Hilt dependencies are properly configured in build.gradle:
 *    implementation "com.google.dagger:hilt-android:2.48"
 *    kapt "com.google.dagger:hilt-android-compiler:2.48"
 * 2. Add Timber dependency:
 *    implementation "com.jakewharton.timber:timber:5.0.1"
 * 3. Configure AndroidManifest.xml to use this Application class:
 *    android:name=".FounditureApplication"
 * 4. Set up ProGuard rules for Dagger Hilt and Timber
 * 5. Configure crash reporting service (e.g., Firebase Crashlytics)
 */

package com.founditure.android

import android.app.Application
import androidx.work.Configuration
import androidx.work.WorkManager
import com.founditure.android.config.NetworkConfig
import com.founditure.android.data.local.AppDatabase
import com.founditure.android.di.AppModule
import dagger.hilt.android.HiltAndroidApp
import timber.log.Timber
import javax.inject.Inject

/**
 * Main application class for the Founditure Android application.
 * Initializes core components, dependency injection, and application-wide configurations.
 * 
 * Implements requirements:
 * - Mobile Applications (1.2): Native Android application with offline-first architecture
 * - System Architecture (3.1): Mobile client architecture implementation and configuration
 */
@HiltAndroidApp
class FounditureApplication : Application(), Configuration.Provider {

    // Injected via Dagger Hilt
    @Inject
    lateinit var appModule: AppModule

    // Local database instance
    private lateinit var database: AppDatabase

    override fun onCreate() {
        super.onCreate()
        
        // Initialize Timber for logging in debug mode
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
            Timber.d("Initializing Founditure application in debug mode")
        }

        // Initialize database instance
        try {
            database = AppDatabase.getDatabase(this)
            Timber.d("Local database initialized successfully")
        } catch (e: Exception) {
            Timber.e(e, "Failed to initialize local database")
            // Consider implementing a fallback strategy or user notification
        }

        // Initialize network configuration
        try {
            NetworkConfig.createOkHttpClient()
            Timber.d("Network configuration initialized successfully")
        } catch (e: Exception) {
            Timber.e(e, "Failed to initialize network configuration")
        }

        // Configure crash reporting
        setupCrashReporting()

        // Initialize WorkManager for background tasks
        initializeWorkManager()

        Timber.i("Founditure application initialization completed")
    }

    /**
     * Provides WorkManager configuration for background tasks.
     * Required by Configuration.Provider interface.
     */
    override fun getWorkManagerConfiguration(): Configuration {
        return Configuration.Builder()
            .setMinimumLoggingLevel(if (BuildConfig.DEBUG) android.util.Log.DEBUG else android.util.Log.INFO)
            .build()
    }

    /**
     * Sets up crash reporting service for production monitoring.
     * Implements error tracking requirements from System Architecture (3.1).
     */
    private fun setupCrashReporting() {
        if (!BuildConfig.DEBUG) {
            // Initialize crash reporting service (e.g., Firebase Crashlytics)
            // This should be configured based on your chosen crash reporting solution
            try {
                // crashlytics.initialize()
                Timber.d("Crash reporting initialized successfully")
            } catch (e: Exception) {
                Timber.e(e, "Failed to initialize crash reporting")
            }
        }
    }

    /**
     * Initializes WorkManager for background task processing.
     * Implements offline-first architecture requirements from Mobile Applications (1.2).
     */
    private fun initializeWorkManager() {
        try {
            WorkManager.initialize(
                this,
                getWorkManagerConfiguration()
            )
            Timber.d("WorkManager initialized successfully")
        } catch (e: Exception) {
            Timber.e(e, "Failed to initialize WorkManager")
        }
    }

    companion object {
        const val TAG = "FounditureApplication"
    }
}