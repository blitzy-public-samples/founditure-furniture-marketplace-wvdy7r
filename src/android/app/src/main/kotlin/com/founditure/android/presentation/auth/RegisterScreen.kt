/*
 * Human Tasks:
 * 1. Ensure Material3 dependency is added to app/build.gradle:
 *    implementation "androidx.compose.material3:material3:1.1.0"
 * 2. Configure Hilt for dependency injection
 * 3. Add navigation-compose dependency:
 *    implementation "androidx.navigation:navigation-compose:2.7.0"
 * 4. Add hilt-navigation-compose dependency:
 *    implementation "androidx.hilt.navigation.compose:hilt-navigation-compose:1.0.0"
 */

package com.founditure.android.presentation.auth

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.founditure.android.presentation.navigation.Screen
import com.founditure.android.util.ValidationUtils
import kotlinx.coroutines.flow.collectLatest

/**
 * Composable screen component that implements the user registration interface.
 * 
 * Implements requirements:
 * - User registration and authentication (1.2 Scope/Included Features)
 * - Privacy controls (1.2 Scope/Included Features)
 * - Mobile-first platform (1.1 System Overview)
 */
@Composable
fun RegisterScreen(
    navController: NavController,
    viewModel: AuthViewModel = hiltViewModel()
) {
    // Form state using remember
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var fullName by remember { mutableStateOf("") }
    var phoneNumber by remember { mutableStateOf("") }
    
    // Validation state
    var emailError by remember { mutableStateOf<String?>(null) }
    var passwordError by remember { mutableStateOf<String?>(null) }
    var phoneError by remember { mutableStateOf<String?>(null) }
    
    // Form state data class
    val formState = RegisterFormState(
        email = email,
        password = password,
        fullName = fullName,
        phoneNumber = phoneNumber,
        isLoading = false,
        error = null
    )

    // Observe authentication state
    LaunchedEffect(key1 = true) {
        viewModel.authState.collectLatest { state ->
            when (state) {
                is AuthViewModel.AuthState.Authenticated -> {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Auth.route) { inclusive = true }
                    }
                }
                is AuthViewModel.AuthState.Error -> {
                    // Error handling will be managed in the form state
                }
                else -> Unit
            }
        }
    }

    // Main content
    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            RegisterForm(
                formState = formState,
                onEmailChange = { 
                    email = it
                    emailError = if (!ValidationUtils.validateEmail(it)) {
                        "Please enter a valid email address"
                    } else null
                },
                onPasswordChange = {
                    password = it
                    passwordError = if (!ValidationUtils.validatePassword(it)) {
                        "Password must be at least 8 characters with uppercase, lowercase, number and special character"
                    } else null
                },
                onFullNameChange = { fullName = it },
                onPhoneNumberChange = { 
                    phoneNumber = it
                    phoneError = if (it.isNotEmpty() && !ValidationUtils.validatePhoneNumber(it)) {
                        "Please enter a valid phone number"
                    } else null
                },
                onRegister = {
                    // Validate all fields before registration
                    when {
                        !ValidationUtils.validateEmail(email) -> {
                            emailError = "Please enter a valid email address"
                        }
                        !ValidationUtils.validatePassword(password) -> {
                            passwordError = "Invalid password format"
                        }
                        phoneNumber.isNotEmpty() && !ValidationUtils.validatePhoneNumber(phoneNumber) -> {
                            phoneError = "Invalid phone number format"
                        }
                        else -> {
                            viewModel.register(
                                email = email,
                                password = password,
                                fullName = fullName,
                                phoneNumber = phoneNumber.takeIf { it.isNotEmpty() }
                            )
                        }
                    }
                },
                emailError = emailError,
                passwordError = passwordError,
                phoneError = phoneError
            )

            Spacer(modifier = Modifier.height(16.dp))

            TextButton(
                onClick = { 
                    navController.navigate(Screen.Login.route) {
                        popUpTo(Screen.Register.route) { inclusive = true }
                    }
                }
            ) {
                Text("Already have an account? Log in")
            }
        }
    }
}

@Composable
private fun RegisterForm(
    formState: RegisterFormState,
    onEmailChange: (String) -> Unit,
    onPasswordChange: (String) -> Unit,
    onFullNameChange: (String) -> Unit,
    onPhoneNumberChange: (String) -> Unit,
    onRegister: () -> Unit,
    emailError: String?,
    passwordError: String?,
    phoneError: String?
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Email field
        OutlinedTextField(
            value = formState.email,
            onValueChange = onEmailChange,
            label = { Text("Email") },
            isError = emailError != null,
            supportingText = emailError?.let { { Text(it) } },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Email,
                imeAction = ImeAction.Next
            ),
            modifier = Modifier.fillMaxWidth()
        )

        // Password field
        OutlinedTextField(
            value = formState.password,
            onValueChange = onPasswordChange,
            label = { Text("Password") },
            visualTransformation = PasswordVisualTransformation(),
            isError = passwordError != null,
            supportingText = passwordError?.let { { Text(it) } },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Next
            ),
            modifier = Modifier.fillMaxWidth()
        )

        // Full name field
        OutlinedTextField(
            value = formState.fullName,
            onValueChange = onFullNameChange,
            label = { Text("Full Name") },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Text,
                imeAction = ImeAction.Next
            ),
            modifier = Modifier.fillMaxWidth()
        )

        // Phone number field (optional)
        OutlinedTextField(
            value = formState.phoneNumber ?: "",
            onValueChange = onPhoneNumberChange,
            label = { Text("Phone Number (Optional)") },
            isError = phoneError != null,
            supportingText = phoneError?.let { { Text(it) } },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Phone,
                imeAction = ImeAction.Done
            ),
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Register button
        Button(
            onClick = onRegister,
            enabled = !formState.isLoading &&
                     emailError == null &&
                     passwordError == null &&
                     phoneError == null &&
                     formState.email.isNotEmpty() &&
                     formState.password.isNotEmpty() &&
                     formState.fullName.isNotEmpty(),
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp)
        ) {
            if (formState.isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(24.dp),
                    color = MaterialTheme.colorScheme.onPrimary
                )
            } else {
                Text("Register")
            }
        }

        // Error message
        formState.error?.let { error ->
            Text(
                text = error,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier.padding(top = 8.dp)
            )
        }
    }
}

/**
 * Data class holding the registration form state
 */
data class RegisterFormState(
    val email: String,
    val password: String,
    val fullName: String,
    val phoneNumber: String?,
    val isLoading: Boolean,
    val error: String?
)