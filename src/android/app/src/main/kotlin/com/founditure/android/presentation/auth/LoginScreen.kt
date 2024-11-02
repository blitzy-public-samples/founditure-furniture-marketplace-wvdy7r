/*
 * Human Tasks:
 * 1. Ensure Material3 dependencies are added to app/build.gradle:
 *    implementation "androidx.compose.material3:material3:1.1.0"
 * 2. Configure proper theme colors in Theme.kt
 * 3. Add proper translations for strings in strings.xml
 * 4. Verify proper navigation setup in NavGraph.kt
 */

package com.founditure.android.presentation.auth

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.founditure.android.presentation.navigation.Screen
import com.founditure.android.util.ValidationUtils
import kotlinx.coroutines.flow.collectLatest

/**
 * Composable screen that implements the login interface.
 * 
 * Implements requirements:
 * - User registration and authentication (1.2 Scope/Included Features)
 * - Mobile-first platform (1.1 System Overview)
 * - Offline-first architecture (1.2 Scope/Core System Components/Mobile Applications)
 */
@Composable
fun LoginScreen(
    navController: NavController,
    viewModel: AuthViewModel = viewModel()
) {
    // State holders for form fields
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var rememberMe by remember { mutableStateOf(false) }
    var passwordVisible by remember { mutableStateOf(false) }
    var showError by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }
    
    // Focus manager for keyboard handling
    val focusManager = LocalFocusManager.current

    // Collect authentication state
    LaunchedEffect(key1 = true) {
        viewModel.authState.collectLatest { state ->
            when (state) {
                is AuthViewModel.AuthState.Authenticated -> {
                    // Navigate to home screen on successful authentication
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Auth.route) { inclusive = true }
                    }
                }
                is AuthViewModel.AuthState.Error -> {
                    showError = true
                    errorMessage = state.message
                }
                else -> {
                    // Handle other states if needed
                }
            }
        }
    }

    // Main scaffold with snackbar host
    Scaffold(
        snackbarHost = {
            SnackbarHost(hostState = LocalSnackbarHostState.current)
        }
    ) { paddingValues ->
        // Main content column
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Login form
            LoginForm(
                email = email,
                password = password,
                rememberMe = rememberMe,
                passwordVisible = passwordVisible,
                onEmailChange = { 
                    email = it
                    showError = false 
                },
                onPasswordChange = { 
                    password = it
                    showError = false 
                },
                onRememberMeChange = { rememberMe = it },
                onPasswordVisibilityChange = { passwordVisible = it },
                onLoginClick = {
                    // Validate inputs
                    when {
                        !ValidationUtils.validateEmail(email) -> {
                            showError = true
                            errorMessage = "Invalid email format"
                        }
                        !ValidationUtils.validatePassword(password) -> {
                            showError = true
                            errorMessage = "Invalid password format"
                        }
                        else -> {
                            focusManager.clearFocus()
                            viewModel.login(email, password, rememberMe)
                        }
                    }
                },
                onRegisterClick = {
                    navController.navigate(Screen.Register.route)
                },
                onForgotPasswordClick = {
                    navController.navigate(Screen.ForgotPassword.route)
                }
            )

            // Error message
            if (showError) {
                Text(
                    text = errorMessage,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(top = 8.dp)
                )
            }
        }
    }
}

/**
 * Composable function that renders the login form components.
 */
@Composable
private fun LoginForm(
    email: String,
    password: String,
    rememberMe: Boolean,
    passwordVisible: Boolean,
    onEmailChange: (String) -> Unit,
    onPasswordChange: (String) -> Unit,
    onRememberMeChange: (Boolean) -> Unit,
    onPasswordVisibilityChange: (Boolean) -> Unit,
    onLoginClick: () -> Unit,
    onRegisterClick: () -> Unit,
    onForgotPasswordClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Email field
        OutlinedTextField(
            value = email,
            onValueChange = onEmailChange,
            label = { Text("Email") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Email,
                imeAction = ImeAction.Next
            ),
            modifier = Modifier.fillMaxWidth()
        )

        // Password field
        OutlinedTextField(
            value = password,
            onValueChange = onPasswordChange,
            label = { Text("Password") },
            singleLine = true,
            visualTransformation = if (passwordVisible) 
                VisualTransformation.None 
            else 
                PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Done
            ),
            keyboardActions = KeyboardActions(
                onDone = { onLoginClick() }
            ),
            trailingIcon = {
                IconButton(
                    onClick = { onPasswordVisibilityChange(!passwordVisible) }
                ) {
                    Icon(
                        imageVector = if (passwordVisible) 
                            Icons.Filled.Visibility 
                        else 
                            Icons.Filled.VisibilityOff,
                        contentDescription = if (passwordVisible) 
                            "Hide password" 
                        else 
                            "Show password"
                    )
                }
            },
            modifier = Modifier.fillMaxWidth()
        )

        // Remember me checkbox
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Start,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Checkbox(
                checked = rememberMe,
                onCheckedChange = onRememberMeChange
            )
            Text(
                text = "Remember me",
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(start = 8.dp)
            )
        }

        // Login button
        Button(
            onClick = onLoginClick,
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp)
        ) {
            Text("Login")
        }

        // Register and forgot password links
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            TextButton(onClick = onRegisterClick) {
                Text("Create Account")
            }
            TextButton(onClick = onForgotPasswordClick) {
                Text("Forgot Password?")
            }
        }
    }
}