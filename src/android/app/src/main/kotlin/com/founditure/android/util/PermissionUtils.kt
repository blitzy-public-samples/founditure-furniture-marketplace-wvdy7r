/**
 * Human Tasks:
 * 1. Ensure all required permissions are declared in AndroidManifest.xml
 * 2. Configure notification channels for Android 8.0+ in Application class
 * 3. Test permission flows on different Android versions (8.0+)
 * 4. Verify proper permission handling in the app's privacy policy
 * 5. Implement proper permission error handling in UI components
 */

package com.founditure.android.util

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

/**
 * Utility class for handling runtime permissions in the Founditure Android application.
 * Implements requirements from:
 * - Mobile Applications (1.2 Scope/Core System Components/1. Mobile Applications)
 * - Security Architecture (3.6 Security Architecture)
 */
object PermissionUtils {

    /**
     * Array of required permissions for the application's core functionality
     */
    private val REQUIRED_PERMISSIONS = arrayOf(
        Manifest.permission.CAMERA,
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_COARSE_LOCATION,
        Manifest.permission.READ_EXTERNAL_STORAGE,
        Manifest.permission.WRITE_EXTERNAL_STORAGE,
        Manifest.permission.POST_NOTIFICATIONS
    )

    /**
     * Checks if all required permissions are granted.
     * 
     * @param context The application context
     * @return Boolean indicating if all permissions are granted
     */
    fun hasRequiredPermissions(context: Context): Boolean {
        return REQUIRED_PERMISSIONS.all { permission ->
            ContextCompat.checkSelfPermission(
                context,
                permission
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    /**
     * Requests all required permissions at once.
     * Uses Location.LOCATION_PERMISSION_CODE from Constants.kt for request identification.
     * 
     * @param activity The activity requesting permissions
     */
    fun requestPermissions(activity: Activity) {
        val permissionsToRequest = REQUIRED_PERMISSIONS.filter { permission ->
            ContextCompat.checkSelfPermission(
                activity,
                permission
            ) != PackageManager.PERMISSION_GRANTED
        }.toTypedArray()

        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                activity,
                permissionsToRequest,
                Location.LOCATION_PERMISSION_CODE
            )
        }
    }

    /**
     * Checks if permission rationale should be shown for any permission.
     * This is typically used when the user has previously denied a permission.
     * 
     * @param activity The activity checking for rationale
     * @return Boolean indicating if rationale should be shown
     */
    fun shouldShowRationale(activity: Activity): Boolean {
        return REQUIRED_PERMISSIONS.any { permission ->
            ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)
        }
    }

    /**
     * Checks if a specific permission is granted.
     * Useful for checking individual permissions before performing specific actions.
     * 
     * @param context The application context
     * @param permission The specific permission to check
     * @return Boolean indicating if the permission is granted
     */
    fun checkSpecificPermission(context: Context, permission: String): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            permission
        ) == PackageManager.PERMISSION_GRANTED
    }
}