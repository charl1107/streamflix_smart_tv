package com.streamflix.streamflix_tv

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val launchChannel = "com.streamflix.streamflix_tv/launch"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleLauncherIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleLauncherIntent(intent)
    }

    private fun handleLauncherIntent(intent: Intent) {
        if (intent.action != Intent.ACTION_MAIN) return

        val launchedFromLauncher = intent.hasCategory(Intent.CATEGORY_LAUNCHER) ||
            intent.hasCategory(Intent.CATEGORY_LEANBACK_LAUNCHER)
        if (!launchedFromLauncher) return

        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, launchChannel).invokeMethod("resetToHome", null)
        }
    }
}
