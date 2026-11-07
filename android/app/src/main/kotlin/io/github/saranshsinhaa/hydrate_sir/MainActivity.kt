package io.github.saranshsinhaa.hydrate_sir

import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Shows over the lock screen only while a reminder ("At the door") is open,
 * never for ordinary use of the app.
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyLockScreen(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        applyLockScreen(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hydrate_sir/lock_screen")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "release" -> {
                        setLockScreen(false)
                        if (call.argument<Boolean>("moveToBack") == true) moveTaskToBack(true)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun applyLockScreen(intent: Intent?) {
        // The notification plugin launches us with this action from a reminder.
        setLockScreen(intent?.action == "SELECT_NOTIFICATION")
    }

    private fun setLockScreen(on: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(on)
            setTurnScreenOn(on)
        }
    }
}
