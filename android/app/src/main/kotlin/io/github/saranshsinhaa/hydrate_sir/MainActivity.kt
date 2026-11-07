package io.github.saranshsinhaa.hydrate_sir

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File
import java.security.MessageDigest
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hydrate_sir/updates")
            .setMethodCallHandler(::handleUpdates)
    }

    // Updates: the installed version, a place to download to, and handing a
    // verified APK to Android's installer. Android itself refuses any update
    // not signed with the same key.
    private fun handleUpdates(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "appVersion" -> {
                val info = packageManager.getPackageInfo(packageName, 0)
                val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    info.longVersionCode
                } else {
                    @Suppress("DEPRECATION") info.versionCode.toLong()
                }
                result.success(mapOf("name" to info.versionName, "code" to code))
            }
            "downloadDir" -> {
                val dir = File(cacheDir, "updates").apply { mkdirs() }
                result.success(dir.absolutePath)
            }
            "canInstall" -> result.success(
                Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
                    packageManager.canRequestPackageInstalls()
            )
            "openInstallSettings" -> {
                startActivity(
                    Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        Uri.parse("package:$packageName"),
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
                result.success(null)
            }
            "install" -> {
                val file = File(call.argument<String>("path") ?: "")
                val expected = call.argument<String>("sha256")?.lowercase()
                if (!file.isFile || !file.canonicalPath.startsWith(File(cacheDir, "updates").canonicalPath)) {
                    result.error("missing", "No downloaded update to install", null)
                    return
                }
                if (expected != null && sha256(file) != expected) {
                    file.delete()
                    result.error("checksum", "The download does not match its checksum", null)
                    return
                }
                val uri = FileProvider.getUriForFile(this, "$packageName.updates", file)
                startActivity(
                    Intent(Intent.ACTION_VIEW)
                        .setDataAndType(uri, "application/vnd.android.package-archive")
                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                )
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun sha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(64 * 1024)
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                digest.update(buffer, 0, read)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
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
