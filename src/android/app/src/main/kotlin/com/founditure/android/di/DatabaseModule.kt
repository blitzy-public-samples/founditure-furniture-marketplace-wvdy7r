/*
 * Human Tasks:
 * 1. Add Hilt dependencies to app/build.gradle:
 *    implementation "com.google.dagger:hilt-android:2.44"
 *    kapt "com.google.dagger:hilt-android-compiler:2.44"
 * 2. Add Room dependencies to app/build.gradle:
 *    implementation "androidx.room:room-runtime:2.5.0"
 *    implementation "androidx.room:room-ktx:2.5.0"
 *    kapt "androidx.room:room-compiler:2.5.0"
 */

package com.founditure.android.di

import android.content.Context
import com.founditure.android.data.local.AppDatabase
import com.founditure.android.data.local.dao.UserDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Dagger Hilt module that provides database-related dependencies for dependency injection.
 * 
 * Addresses requirements:
 * - Local Data Persistence (1.2 Scope/Core System Components/Mobile Applications)
 * - Data Management (1.2 Scope/Core System Components/Data Management)
 */
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    /**
     * Provides singleton instance of Room database.
     * Uses application context to ensure proper lifecycle management.
     *
     * @param context Application context injected by Hilt
     * @return Singleton instance of AppDatabase
     */
    @Provides
    @Singleton
    fun provideAppDatabase(
        @ApplicationContext context: Context
    ): AppDatabase {
        return AppDatabase.getDatabase(context)
    }

    /**
     * Provides UserDao instance for database operations related to users.
     * UserDao is scoped to Singleton to ensure consistent database access.
     *
     * @param database The AppDatabase instance
     * @return UserDao instance for user-related database operations
     */
    @Provides
    @Singleton
    fun provideUserDao(database: AppDatabase): UserDao {
        return database.userDao()
    }
}