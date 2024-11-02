/*
 * Human Tasks:
 * 1. Ensure Dagger Hilt dependencies are added to app/build.gradle:
 *    implementation "com.google.dagger:hilt-android:2.44"
 *    kapt "com.google.dagger:hilt-android-compiler:2.44"
 * 2. Add @HiltAndroidApp annotation to Application class
 * 3. Configure Hilt plugin in app/build.gradle:
 *    id 'dagger.hilt.android.plugin'
 */

package com.founditure.android.di

import com.founditure.android.data.repository.UserRepository
import com.founditure.android.data.repository.FurnitureRepository
import com.founditure.android.data.repository.MessageRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Dagger Hilt module that provides dependency injection bindings for all repository implementations.
 * Follows clean architecture patterns and implements offline-first principles.
 *
 * Addresses requirements:
 * - Data Management (1.2 Scope/Core System Components/Data Management)
 * - Offline-first Architecture (1.2 Scope/Core System Components/Mobile Applications)
 */
@Module
@InstallIn(SingletonComponent::class)
object RepositoryModule {

    /**
     * Provides singleton instance of UserRepository.
     * Ensures consistent user data management across the application.
     *
     * @param repository UserRepository instance created by Hilt
     * @return Singleton scoped UserRepository
     */
    @Provides
    @Singleton
    fun provideUserRepository(repository: UserRepository): UserRepository {
        return repository
    }

    /**
     * Provides singleton instance of FurnitureRepository.
     * Manages furniture data with offline-first capabilities.
     *
     * @param repository FurnitureRepository instance created by Hilt
     * @return Singleton scoped FurnitureRepository
     */
    @Provides
    @Singleton
    fun provideFurnitureRepository(repository: FurnitureRepository): FurnitureRepository {
        return repository
    }

    /**
     * Provides singleton instance of MessageRepository.
     * Handles real-time messaging with offline support.
     *
     * @param repository MessageRepository instance created by Hilt
     * @return Singleton scoped MessageRepository
     */
    @Provides
    @Singleton
    fun provideMessageRepository(repository: MessageRepository): MessageRepository {
        return repository
    }
}