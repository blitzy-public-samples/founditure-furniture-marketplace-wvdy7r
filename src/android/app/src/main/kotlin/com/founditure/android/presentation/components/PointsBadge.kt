/*
 * Human Tasks:
 * 1. Verify that the animation duration and easing curves match the design system specifications
 * 2. Test the component's accessibility with TalkBack enabled
 * 3. Validate color contrast ratios in both light and dark themes
 */

package com.founditure.android.presentation.components

import androidx.compose.animation.animateIntAsState // v1.5.0
import androidx.compose.foundation.layout.Row // v1.5.0
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon // v1.1.0
import androidx.compose.material3.Surface // v1.1.0
import androidx.compose.material3.Text // v1.1.0
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.founditure.android.R
import com.founditure.android.domain.model.Points
import com.founditure.android.presentation.theme.Primary
import com.founditure.android.presentation.theme.FounditureTypography

/**
 * A reusable Jetpack Compose UI component that displays user points in a visually appealing badge format.
 * Supports both light and dark themes with animations for points changes.
 * 
 * Addresses requirements:
 * - Points System (1.2 Scope/Core System Components/Backend Services)
 * - Points-based gamification engine (1.1 System Overview)
 *
 * @param points The Points domain model containing the user's point information
 * @param showWeekly Flag to toggle between displaying weekly or total points
 * @param modifier Optional Modifier for customizing the badge's layout
 */
@Composable
fun PointsBadge(
    points: Points,
    showWeekly: Boolean = false,
    modifier: Modifier = Modifier
) {
    // Animate points value changes for smooth transitions
    val animatedPoints by animateIntAsState(
        targetValue = if (showWeekly) points.weeklyPoints else points.totalPoints,
        label = "Points Animation"
    )

    Surface(
        modifier = modifier,
        color = Primary,
        shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp),
        shadowElevation = 2.dp
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Points icon
            Icon(
                painter = painterResource(id = R.drawable.ic_points),
                contentDescription = null,
                modifier = Modifier.size(16.dp),
                tint = androidx.compose.ui.graphics.Color.White
            )

            // Animated points value
            Text(
                text = formatPoints(animatedPoints),
                style = FounditureTypography.labelMedium,
                color = androidx.compose.ui.graphics.Color.White,
                modifier = Modifier.padding(start = 4.dp)
            )
        }
    }
}

/**
 * Helper function to format points value with appropriate suffix (K for thousands, M for millions).
 *
 * @param points The points value to format
 * @return Formatted string representation of the points value
 */
private fun formatPoints(points: Int): String {
    return when {
        points >= 1_000_000 -> String.format("%.1fM", points / 1_000_000.0)
        points >= 1_000 -> String.format("%.1fK", points / 1_000.0)
        else -> points.toString()
    }
}