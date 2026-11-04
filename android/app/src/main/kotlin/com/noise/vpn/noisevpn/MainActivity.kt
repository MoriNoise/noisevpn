package com.noise.vpn.noisevpn

import android.app.ActivityManager
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "noisevpn/native")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Where flutter_vless's bundled Xray (libxray.so) lives, for parallel ping.
                    "nativeLibraryDir" -> result.success(applicationInfo.nativeLibraryDir)
                    // Launchable apps for per-app proxy. Reading labels is slow, so off the UI thread.
                    "installedApps" -> Thread {
                        val apps = try {
                            val pm = packageManager
                            val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                            pm.queryIntentActivities(launcher, 0)
                                .map { it.activityInfo.applicationInfo }
                                .distinctBy { it.packageName }
                                .filter { it.packageName != packageName }
                                .map { mapOf("package" to it.packageName, "label" to pm.getApplicationLabel(it).toString()) }
                                .sortedBy { (it["label"] ?: "").lowercase() }
                        } catch (e: Exception) {
                            null
                        }
                        Handler(Looper.getMainLooper()).post {
                            if (apps == null) result.error("apps", "Couldn't read installed apps", null)
                            else result.success(apps)
                        }
                    }.start()
                    // flutter_vless runs its VPN service in a separate process and only reports
                    // state by broadcast, which can be missed. This is the ground truth.
                    "vpnServiceRunning" -> {
                        val am = getSystemService(ACTIVITY_SERVICE) as ActivityManager
                        @Suppress("DEPRECATION") // still returns the caller's own services
                        val running = am.getRunningServices(Int.MAX_VALUE).any {
                            it.service.className == "com.github.tfox.flutter_vless.xray.service.XrayVPNService"
                        }
                        result.success(running)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
