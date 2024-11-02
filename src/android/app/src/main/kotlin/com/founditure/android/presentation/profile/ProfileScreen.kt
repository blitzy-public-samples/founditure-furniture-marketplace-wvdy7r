/*
 * Human Tasks:
 * 1. Verify Coil image loading configuration in Application class
 * 2. Test accessibility features with TalkBack enabled
 * 3. Validate proper error tracking integration
 * 4. Ensure proper memory management for image loading
 * 5. Test offline functionality by disabling network connection
 */

package com.founditure.android.presentation.profile

import androidx.compose.foundation.layout.* // v1.5.0
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.* // v1.1.0
import androidx.compose.runtime.* // v1.5.0
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel // v1.0.0
import androidx.navigation.NavController
import coil.compose.AsyncImage // v2.4.0
import coil.request.ImageRequest
import com.founditure.android.R
import com.founditure.android.domain.model.User
import com.founditure.android.presentation.components.PointsBadge
import com.google.accompanist.swiperefresh.SwipeRefresh
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState

/**
 * Main composable for the profile screen. Implements user profile display with offline-first capabilities.
 * 
 * Addresses requirements:
 * - User profile management and data visualization (1.2 Scope/Core System Components/Backend Services)
 * - Points-based gamification engine display (1.1 System Overview)
 * - Offline-first architecture (1.2 Scope/Core System Components/Mobile Applications)
 *
 * @param navController Navigation controller for handling screen navigation
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
fun ProfileScreen(
    navController: NavController,
    modifier: Modifier = Modifier,
    viewModel: ProfileViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val swipeRefreshState = rememberSwipeRefreshState(uiState.isLoading)

    // Effect to load profile data on first composition
    LaunchedEffect(Unit) {
        // TODO: Replace with actual user ID from auth state
        viewModel.loadUserProfile("current_user_id")
    }

    // Effect to show error messages
    LaunchedEffect(uiState.error) {
        uiState.error?.let { error ->
            snackbarHostState.showSnackbar(
                message = error,
                duration = SnackbarDuration.Short
            )
            viewModel.clearError()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(text = stringResource(R.string.profile_title)) },
                actions = {
                    IconButton(onClick = { navController.navigate("settings") }) {
                        Icon(
                            painter = painterResource(id = R.drawable.ic_settings),
                            contentDescription = stringResource(R.string.settings_description)
                        )
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        SwipeRefresh(
            state = swipeRefreshState,
            onRefresh = { viewModel.refreshProfile() },
            modifier = modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                uiState.isLoading && uiState.user == null -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                uiState.user != null -> {
                    ProfileContent(
                        user = uiState.user!!,
                        points = uiState.points,
                        onEditClick = { navController.navigate("profile/edit") },
                        modifier = Modifier.fillMaxSize()
                    )
                }
                else -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = stringResource(R.string.profile_load_error),
                            style = MaterialTheme.typography.bodyLarge,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                }
            }
        }
    }
}

/**
 * Composable for the main profile content section.
 * Displays user information, points, and achievements.
 */
@Composable
private fun ProfileContent(
    user: User,
    points: com.founditure.android.domain.model.Points?,
    onEditClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        ProfileHeader(user = user)
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Points display
        points?.let { userPoints ->
            PointsBadge(
                points = userPoints,
                modifier = Modifier.padding(vertical = 8.dp)
            )
        }
        
        Spacer(modifier = Modifier.height(16.dp))

        // User information section
        Card(
            modifier = Modifier.fillMaxWidth(),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = user.fullName,
                    style = MaterialTheme.typography.titleLarge
                )
                Text(
                    text = user.email,
                    style = MaterialTheme.typography.bodyMedium
                )
                user.phoneNumber?.let { phone ->
                    Text(
                        text = phone,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Edit profile button
        Button(
            onClick = onEditClick,
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(
                painter = painterResource(id = R.drawable.ic_edit),
                contentDescription = null,
                modifier = Modifier.size(18.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(text = stringResource(R.string.edit_profile))
        }
    }
}

/**
 * Composable for the profile header section.
 * Displays user profile image and verification badge if applicable.
 */
@Composable
private fun ProfileHeader(
    user: User,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.size(120.dp),
        contentAlignment = Alignment.Center
    ) {
        AsyncImage(
            model = ImageRequest.Builder(LocalContext.current)
                .data(user.profileImageUrl)
                .crossfade(true)
                .build(),
            contentDescription = stringResource(R.string.profile_image_description),
            contentScale = ContentScale.Crop,
            placeholder = painterResource(id = R.drawable.ic_profile_placeholder),
            error = painterResource(id = R.drawable.ic_profile_placeholder),
            modifier = Modifier
                .fillMaxSize()
                .clip(MaterialTheme.shapes.circular)
        )

        if (user.isVerified) {
            Icon(
                painter = painterResource(id = R.drawable.ic_verified),
                contentDescription = stringResource(R.string.verified_badge_description),
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .size(24.dp)
                    .background(
                        color = MaterialTheme.colorScheme.surface,
                        shape = MaterialTheme.shapes.circular
                    )
                    .padding(4.dp)
            )
        }
    }
}