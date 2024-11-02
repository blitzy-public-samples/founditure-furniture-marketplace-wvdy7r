/*
 * Human Tasks:
 * 1. Verify Dagger Hilt dependencies in app/build.gradle:
 *    implementation "com.google.dagger:hilt-android:2.48"
 *    kapt "com.google.dagger:hilt-android-compiler:2.48"
 * 2. Ensure ViewModelComponent is properly configured in Hilt setup
 * 3. Verify all required use cases are provided by their respective modules
 */

package com.founditure.android.di

import com.founditure.android.domain.usecase.auth.LoginUseCase
import com.founditure.android.domain.usecase.auth.RegisterUseCase
import com.founditure.android.domain.usecase.furniture.CreateFurnitureUseCase
import com.founditure.android.domain.usecase.furniture.GetFurnitureListUseCase
import com.founditure.android.presentation.auth.AuthViewModel
import com.founditure.android.presentation.furniture.FurnitureViewModel
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.components.ViewModelComponent
import dagger.hilt.android.scopes.ViewModelScoped

/**
 * Dagger Hilt module providing ViewModel dependency injection bindings.
 * 
 * Addresses requirements:
 * - Native Android application with dependency injection for ViewModels (1.2 Scope/Core System Components/1. Mobile Applications)
 * - ViewModel dependency management for UI and business logic integration (3.2.1 Mobile Client Architecture/Business Logic Layer)
 */
@Module
@InstallIn(ViewModelComponent::class)
object ViewModelModule {

    /**
     * Provides AuthViewModel instance with required dependencies.
     * Implements authentication ViewModel binding requirement.
     *
     * @param loginUseCase Use case for handling user login operations
     * @param registerUseCase Use case for handling user registration operations
     * @return Configured AuthViewModel instance
     */
    @Provides
    @ViewModelScoped
    fun provideAuthViewModel(
        loginUseCase: LoginUseCase,
        registerUseCase: RegisterUseCase
    ): AuthViewModel {
        return AuthViewModel(
            loginUseCase = loginUseCase,
            registerUseCase = registerUseCase
        )
    }

    /**
     * Provides FurnitureViewModel instance with required dependencies.
     * Implements furniture management ViewModel binding requirement.
     *
     * @param getFurnitureListUseCase Use case for retrieving furniture listings
     * @param createFurnitureUseCase Use case for creating new furniture listings
     * @return Configured FurnitureViewModel instance
     */
    @Provides
    @ViewModelScoped
    fun provideFurnitureViewModel(
        getFurnitureListUseCase: GetFurnitureListUseCase,
        createFurnitureUseCase: CreateFurnitureUseCase
    ): FurnitureViewModel {
        return FurnitureViewModel(
            getFurnitureListUseCase = getFurnitureListUseCase,
            createFurnitureUseCase = createFurnitureUseCase
        )
    }
}