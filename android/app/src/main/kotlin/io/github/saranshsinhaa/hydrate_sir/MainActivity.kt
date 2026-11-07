package io.github.saranshsinhaa.hydrate_sir

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
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
        // Battery: whether Android may hold back reminders, and the way to
        // the settings page where the user can exempt us.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hydrate_sir/battery")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isExempt" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "openSettings" -> {
                        val intent = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", packageName, null),
                        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
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
