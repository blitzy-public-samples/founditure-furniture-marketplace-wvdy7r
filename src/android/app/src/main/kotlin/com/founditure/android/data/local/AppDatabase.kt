/*
 * Human Tasks:
 * 1. Add Room dependencies to app/build.gradle:
 *    implementation "androidx.room:room-runtime:2.5.0"
 *    implementation "androidx.room:room-ktx:2.5.0"
 *    kapt "androidx.room:room-compiler:2.5.0"
 * 2. Add schema export location in build.gradle:
 *    android {
 *        defaultConfig {
 *            javaCompileOptions {
 *                annotationProcessorOptions {
 *                    arguments += ["room.schemaLocation": "$projectDir/schemas"]
 *                }
 *            }
 *        }
 *    }
 */

package com.founditure.android.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.founditure.android.data.local.dao.FurnitureDao
import com.founditure.android.data.local.dao.UserDao
import com.founditure.android.data.local.entity.FurnitureEntity
import com.founditure.android.data.local.entity.UserEntity
import com.squareup.moshi.Moshi
import com.squareup.moshi.Types

/**
 * Room database class that serves as the main database for the Founditure Android application.
 * Implements offline-first architecture and provides access to DAOs for various entities.
 * 
 * Addresses requirements:
 * - Local Data Persistence (1.2 Scope/Core System Components/Mobile Applications)
 * - Data Management (1.2 Scope/Core System Components/Data Management)
 */
@Database(
    entities = [
        UserEntity::class,
        FurnitureEntity::class
    ],
    version = 1,
    exportSchema = true
)
@TypeConverters(AppDatabase.Converters::class)
abstract class AppDatabase : RoomDatabase() {

    /**
     * Provides access to UserDao for user-related database operations
     */
    abstract fun userDao(): UserDao

    /**
     * Provides access to FurnitureDao for furniture-related database operations
     */
    abstract fun furnitureDao(): FurnitureDao

    /**
     * Type converters for complex data types in the database
     */
    class Converters {
        private val moshi = Moshi.Builder().build()
        private val mapAdapter = moshi.adapter<Map<String, Any>>(
            Types.newParameterizedType(Map::class.java, String::class.java, Any::class.java)
        )

        @androidx.room.TypeConverter
        fun fromJson(value: String): Map<String, Any> {
            return mapAdapter.fromJson(value) ?: emptyMap()
        }

        @androidx.room.TypeConverter
        fun toJson(map: Map<String, Any>): String {
            return mapAdapter.toJson(map)
        }
    }

    companion object {
        private const val DATABASE_NAME = "founditure.db"

        @Volatile
        private var INSTANCE: AppDatabase? = null

        /**
         * Gets the singleton instance of the database.
         * Creates a new instance if one doesn't exist.
         *
         * @param context Application context
         * @return Database instance
         */
        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    DATABASE_NAME
                )
                .fallbackToDestructiveMigration() // Temporary migration strategy - replace with proper migrations in production
                .build()
                INSTANCE = instance
                instance
            }
        }
    }
}