/*
 * Human Tasks:
 * 1. Configure proper image upload permissions in AndroidManifest.xml
 * 2. Set up Firebase Storage configuration for image uploads
 * 3. Verify proper ProGuard rules for Coil image loading library
 * 4. Configure analytics events for profile edit actions
 * 5. Set up proper error tracking for profile operations
 */

package com.founditure.android.presentation.profile

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage // version: 2.4.0
import com.founditure.android.domain.model.User
import com.founditure.android.presentation.theme.FounditureTheme
import com.founditure.android.util.ValidationUtils
import kotlinx.coroutines.launch

/**
 * Main composable for the profile editing screen.
 * Implements requirements:
 * - User Management (1.2 Scope/Core System Components/Backend Services)
 * - Privacy Controls (7.2.3 Privacy Controls)
 * - Input Validation (7.3.3 Security Controls)
 *
 * @param navController Navigation controller for screen navigation
 */
@Composable
fun EditProfileScreen(
    navController: NavController,
    viewModel: ProfileViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    
    // Form state management
    var formState by remember { mutableStateOf(ProfileFormState()) }
    
    // Initialize form state with user data when available
    LaunchedEffect(uiState.user) {
        uiState.user?.let { user ->
            formState = ProfileFormState(
                fullName = user.fullName,
                email = user.email,
                phoneNumber = user.phoneNumber ?: ""
            )
        }
    }

    // Image picker launcher
    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { formState = formState.copy(selectedImageUri = it) }
    }

    FounditureTheme {
        Scaffold(
            topBar = {
                SmallTopAppBar(
                    title = { Text("Edit Profile") },
                    navigationIcon = {
                        IconButton(onClick = { navController.navigateUp() }) {
                            Icon(
                                imageVector = Icons.Default.ArrowBack,
                                contentDescription = "Back"
                            )
                        }
                    }
                )
            }
        ) { paddingValues ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            ) {
                // Main content
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Profile image section
                    ProfileImageSection(
                        currentImageUrl = uiState.user?.profileImageUrl,
                        onImageSelected = { imagePickerLauncher.launch("image/*") }
                    )

                    // Form fields
                    ProfileFormFields(
                        formState = formState,
                        onFormStateChange = { formState = it }
                    )

                    // Save button
                    Button(
                        onClick = {
                            scope.launch {
                                if (validateForm(formState)) {
                                    val updatedUser = uiState.user?.copy(
                                        fullName = formState.fullName,
                                        email = formState.email,
                                        phoneNumber = formState.phoneNumber.takeIf { it.isNotBlank() }
                                    )
                                    
                                    updatedUser?.let {
                                        if (viewModel.updateUserProfile(it)) {
                                            navController.navigateUp()
                                        }
                                    }
                                }
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(56.dp),
                        enabled = !uiState.isLoading
                    ) {
                        if (uiState.isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(24.dp),
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                        } else {
                            Text("Save Changes")
                        }
                    }
                }

                // Error dialog
                uiState.error?.let { error ->
                    AlertDialog(
                        onDismissRequest = { viewModel.clearError() },
                        title = { Text("Error") },
                        text = { Text(error) },
                        confirmButton = {
                            TextButton(onClick = { viewModel.clearError() }) {
                                Text("OK")
                            }
                        }
                    )
                }
            }
        }
    }
}

/**
 * Composable for profile image display and upload functionality.
 * Implements image selection and preview.
 */
@Composable
private fun ProfileImageSection(
    currentImageUrl: String?,
    onImageSelected: () -> Unit
) {
    Card(
        modifier = Modifier
            .size(120.dp)
            .clickable(onClick = onImageSelected),
        shape = CircleShape
    ) {
        AsyncImage(
            model = currentImageUrl,
            contentDescription = "Profile Image",
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop,
            fallback = painterResource(R.drawable.ic_profile_placeholder)
        )
    }
}

/**
 * Composable for profile form input fields.
 * Implements input validation and real-time error feedback.
 */
@Composable
private fun ProfileFormFields(
    formState: ProfileFormState,
    onFormStateChange: (ProfileFormState) -> Unit
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Full name field
        OutlinedTextField(
            value = formState.fullName,
            onValueChange = { 
                onFormStateChange(formState.copy(
                    fullName = it,
                    errors = formState.errors - "fullName"
                ))
            },
            label = { Text("Full Name") },
            modifier = Modifier.fillMaxWidth(),
            isError = formState.errors.containsKey("fullName"),
            supportingText = {
                formState.errors["fullName"]?.let { Text(it) }
            }
        )

        // Email field
        OutlinedTextField(
            value = formState.email,
            onValueChange = { 
                onFormStateChange(formState.copy(
                    email = it,
                    errors = formState.errors - "email"
                ))
            },
            label = { Text("Email") },
            keyboardType = KeyboardType.Email,
            modifier = Modifier.fillMaxWidth(),
            isError = formState.errors.containsKey("email"),
            supportingText = {
                formState.errors["email"]?.let { Text(it) }
            }
        )

        // Phone number field
        OutlinedTextField(
            value = formState.phoneNumber,
            onValueChange = { 
                onFormStateChange(formState.copy(
                    phoneNumber = it,
                    errors = formState.errors - "phoneNumber"
                ))
            },
            label = { Text("Phone Number (Optional)") },
            keyboardType = KeyboardType.Phone,
            modifier = Modifier.fillMaxWidth(),
            isError = formState.errors.containsKey("phoneNumber"),
            supportingText = {
                formState.errors["phoneNumber"]?.let { Text(it) }
            }
        )
    }
}

/**
 * Data class representing the form state for profile editing.
 * Implements form validation state management.
 */
private data class ProfileFormState(
    val fullName: String = "",
    val email: String = "",
    val phoneNumber: String = "",
    val selectedImageUri: Uri? = null,
    val errors: Map<String, String> = emptyMap()
) {
    val isValid: Boolean
        get() = errors.isEmpty() &&
                fullName.isNotBlank() &&
                email.isNotBlank()
}

/**
 * Validates form input and updates error state.
 * Implements input validation requirements.
 */
private fun validateForm(formState: ProfileFormState): Boolean {
    val errors = mutableMapOf<String, String>()
    
    if (formState.fullName.isBlank()) {
        errors["fullName"] = "Full name is required"
    }
    
    if (!ValidationUtils.validateEmail(formState.email)) {
        errors["email"] = "Invalid email address"
    }
    
    if (formState.phoneNumber.isNotBlank() && !ValidationUtils.validatePhoneNumber(formState.phoneNumber)) {
        errors["phoneNumber"] = "Invalid phone number"
    }
    
    formState = formState.copy(errors = errors)
    return errors.isEmpty()
}