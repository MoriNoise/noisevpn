package com.noise.vpn.noisevpn

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Tells Dart where the Xray binary that flutter_vless bundles
        // (libxray.so) lives, so ping tests can run in parallel on one core.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "noisevpn/native")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "nativeLibraryDir" -> result.success(applicationInfo.nativeLibraryDir)
                    else -> result.notImplemented()
                }
            }
    }
}
