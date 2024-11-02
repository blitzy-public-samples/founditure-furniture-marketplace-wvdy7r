/*
 * Human Tasks:
 * 1. Ensure Retrofit dependencies are added to app-level build.gradle:
 *    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
 *    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
 *    implementation 'com.squareup.retrofit2:adapter-rxjava3:2.9.0'
 * 2. Ensure RxJava3 dependencies are added:
 *    implementation 'io.reactivex.rxjava3:rxjava:3.0.0'
 *    implementation 'io.reactivex.rxjava3:rxandroid:3.0.0'
 */

package com.founditure.android.data.remote.api

import com.founditure.android.data.remote.dto.UserDto
import io.reactivex.rxjava3.core.Completable // version: 3.0.0
import io.reactivex.rxjava3.core.Single // version: 3.0.0
import retrofit2.http.Body
import retrofit2.http.POST // version: 2.9.0

/**
 * Retrofit service interface for authentication API endpoints.
 * 
 * Addresses requirements:
 * - Core authentication functionality (1.2 Scope/Core System Components/Backend Services)
 * - Offline-first architecture with auth state management (1.2 Scope/Mobile Applications)
 * - Secure authentication flows (7.1 Authentication and Authorization)
 */
interface AuthService {

    /**
     * Authenticates user with email and password.
     * Returns an observable authentication response containing user data and tokens.
     */
    @POST("auth/login")
    fun login(@Body request: LoginRequest): Single<AuthResponse>

    /**
     * Registers a new user account.
     * Returns an observable authentication response for the new user.
     */
    @POST("auth/register")
    fun register(@Body request: RegisterRequest): Single<AuthResponse>

    /**
     * Refreshes authentication token using refresh token.
     * Returns an observable response with new tokens.
     */
    @POST("auth/refresh")
    fun refreshToken(@Body request: RefreshTokenRequest): Single<AuthResponse>

    /**
     * Invalidates current authentication tokens.
     * Returns an observable completion of logout.
     */
    @POST("auth/logout")
    fun logout(): Completable

    /**
     * Initiates password reset process.
     * Returns an observable completion of password reset request.
     */
    @POST("auth/forgot-password")
    fun forgotPassword(@Body request: ForgotPasswordRequest): Completable

    /**
     * Resets password using reset token.
     * Returns an observable completion of password reset.
     */
    @POST("auth/reset-password")
    fun resetPassword(@Body request: ResetPasswordRequest): Completable
}

/**
 * Request body for login endpoint
 */
data class LoginRequest(
    val email: String,
    val password: String,
    val rememberMe: Boolean
)

/**
 * Request body for registration endpoint
 */
data class RegisterRequest(
    val email: String,
    val password: String,
    val fullName: String,
    val phoneNumber: String?
)

/**
 * Response data for authentication operations
 */
data class AuthResponse(
    val user: UserDto,
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Long
)

/**
 * Request body for token refresh endpoint
 */
data class RefreshTokenRequest(
    val refreshToken: String
)

/**
 * Request body for forgot password endpoint
 */
data class ForgotPasswordRequest(
    val email: String
)

/**
 * Request body for password reset endpoint
 */
data class ResetPasswordRequest(
    val token: String,
    val newPassword: String
)