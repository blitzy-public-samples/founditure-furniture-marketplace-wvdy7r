/*
 * Human Tasks:
 * 1. Add the following permissions to AndroidManifest.xml:
 *    - android.permission.ACCESS_FINE_LOCATION
 *    - android.permission.ACCESS_COARSE_LOCATION
 *    - android.permission.FOREGROUND_SERVICE
 * 2. Add the service declaration to AndroidManifest.xml:
 *    <service android:name=".service.LocationService" android:foregroundServiceType="location" />
 * 3. Add dependency to app/build.gradle:
 *    implementation 'com.google.android.gms:play-services-location:21.0.1'
 * 4. Configure default privacy zones in app configuration
 */

package com.founditure.android.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.founditure.android.config.LocationConfig
import com.founditure.android.config.LocationConfig.LocationAccuracy
import com.founditure.android.config.LocationConfig.PrivacyLevel
import com.founditure.android.domain.model.Location
import com.founditure.android.util.LocationUtils
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

/**
 * Android service component that manages location tracking, updates, and privacy controls.
 * Implements requirements:
 * - Location Services (1.2 Scope/Core System Components/2. Backend Services/Location services)
 * - Privacy Controls (7.2.3 Privacy Controls)
 * - Offline-first Architecture (1.2 Scope/Core System Components/1. Mobile Applications)
 */
@AndroidEntryPoint
class LocationService : Service() {

    private val binder = LocationBinder()
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private val serviceScope = CoroutineScope(Dispatchers.Default)
    private val currentLocation = MutableStateFlow<Location?>(null)
    private var privacyLevel: PrivacyLevel = PrivacyLevel.APPROXIMATE

    companion object {
        private const val NOTIFICATION_CHANNEL_ID = "location_service_channel"
        private const val NOTIFICATION_ID = 1001
        private const val LOCATION_NOTIFICATION_TITLE = "Location Tracking Active"
        private const val LOCATION_NOTIFICATION_TEXT = "Founditure is tracking your location"
    }

    inner class LocationBinder : Binder() {
        fun getService(): LocationService = this@LocationService
    }

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        setupLocationCallback()
        createNotificationChannel()
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }

    override fun onDestroy() {
        super.onDestroy()
        stopLocationUpdates()
    }

    /**
     * Begins continuous location monitoring with specified accuracy.
     * Implements Location Services requirement.
     */
    fun startLocationUpdates(accuracy: LocationAccuracy) {
        try {
            val locationRequest = LocationConfig.getLocationRequest(accuracy)
            
            // Start foreground service with notification
            val notification = createNotification()
            startForeground(NOTIFICATION_ID, notification)

            // Request location updates
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                serviceScope.coroutineContext
            )
        } catch (e: SecurityException) {
            // Handle missing location permissions
            stopSelf()
        }
    }

    /**
     * Stops location monitoring and cleans up resources.
     * Implements Location Services requirement.
     */
    fun stopLocationUpdates() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
        currentLocation.value = null
        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    /**
     * Updates location privacy settings.
     * Implements Privacy Controls requirement.
     */
    fun updatePrivacyLevel(level: PrivacyLevel) {
        privacyLevel = level
        // Apply new privacy level to current location
        currentLocation.value?.let { location ->
            val privacySettings = LocationUtils.PrivacyZoneSettings(
                enabled = true,
                fuzzingRadiusKm = when(level) {
                    PrivacyLevel.EXACT -> 0.0
                    PrivacyLevel.APPROXIMATE -> 0.5
                    PrivacyLevel.AREA_ONLY -> 1.0
                },
                privacyLevel = level.name
            )
            val fuzzedLocation = LocationUtils.applyPrivacyZone(location, privacySettings)
            currentLocation.value = fuzzedLocation
        }
    }

    /**
     * Provides flow of location updates.
     * Implements Location Services and Offline-first Architecture requirements.
     */
    fun getLocationUpdates(): StateFlow<Location?> = currentLocation

    private fun setupLocationCallback() {
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { androidLocation ->
                    // Convert Android location to domain model
                    val location = Location(
                        id = UUID.randomUUID(),
                        furnitureId = UUID.randomUUID(), // Placeholder for actual furniture ID
                        latitude = androidLocation.latitude,
                        longitude = androidLocation.longitude,
                        address = "", // Address will be resolved asynchronously
                        privacyLevel = privacyLevel,
                        recordedAt = System.currentTimeMillis()
                    )

                    // Validate location
                    if (LocationUtils.isLocationValid(location)) {
                        // Apply privacy settings
                        val privacySettings = LocationUtils.PrivacyZoneSettings(
                            enabled = privacyLevel != PrivacyLevel.EXACT,
                            fuzzingRadiusKm = when(privacyLevel) {
                                PrivacyLevel.EXACT -> 0.0
                                PrivacyLevel.APPROXIMATE -> 0.5
                                PrivacyLevel.AREA_ONLY -> 1.0
                            },
                            privacyLevel = privacyLevel.name
                        )
                        val fuzzedLocation = LocationUtils.applyPrivacyZone(location, privacySettings)
                        
                        serviceScope.launch {
                            currentLocation.emit(fuzzedLocation)
                        }
                    }
                }
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Location Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Used for location tracking notifications"
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification() = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
        .setContentTitle(LOCATION_NOTIFICATION_TITLE)
        .setContentText(LOCATION_NOTIFICATION_TEXT)
        .setSmallIcon(android.R.drawable.ic_menu_mylocation)
        .setOngoing(true)
        .setCategory(NotificationCompat.CATEGORY_SERVICE)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .build()
}