package io.timon.compose

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Photo
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

@Composable
fun App() {
    MaterialTheme {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = Color.Black
        ) {
            BenchmarkScreen()
        }
    }
}

@Composable
fun BenchmarkScreen() {
    val opacity = remember { Animatable(0f) }
    val scale = remember { Animatable(0.5f) }

    LaunchedEffect(Unit) {
        launch {
            opacity.animateTo(
                targetValue = 1f,
                animationSpec = tween(durationMillis = 1000, easing = LinearEasing)
            )
        }
        launch {
            scale.animateTo(
                targetValue = 1f,
                animationSpec = tween(durationMillis = 1000, easing = LinearEasing)
            )
        }
    }

    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        AnimatedIcon(Icons.Default.Photo, opacity.value, scale.value)
        Spacer(modifier = Modifier.height(25.dp))
        AnimatedIcon(Icons.Default.CameraAlt, opacity.value, scale.value)
        Spacer(modifier = Modifier.height(25.dp))
        AnimatedIcon(Icons.Default.Star, opacity.value, scale.value)
    }
}

@Composable
fun AnimatedIcon(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    opacity: Float,
    scale: Float
) {
    Box(
        modifier = Modifier
            .size((100 * scale).dp)
            .background(
                color = Color.Blue.copy(alpha = 0.3f),
                shape = RoundedCornerShape(12.dp)
            )
            .border(2.dp, Color.White, RoundedCornerShape(12.dp)),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier
                .size(60.dp)
                .graphicsLayer {
                    this.alpha = opacity
                    this.scaleX = scale
                    this.scaleY = scale
                },
            tint = Color.White
        )
    }
}

@Preview
@Composable
fun Preview() {
    App()
}
