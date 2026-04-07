package com.adeeteya.classipod

import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var immersiveModeEnabled = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyImmersiveMode(enabled = false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "classipod/system_ui",
        ).setMethodCallHandler(::handleMethodCall)
    }

    override fun onResume() {
        super.onResume()
        if (immersiveModeEnabled) {
            applyImmersiveMode(enabled = true)
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && immersiveModeEnabled) {
            applyImmersiveMode(enabled = true)
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "setImmersiveMode") {
            result.notImplemented()
            return
        }

        val enabled = call.argument<Boolean>("enabled") ?: false
        applyImmersiveMode(enabled = enabled)
        result.success(null)
    }

    private fun applyImmersiveMode(enabled: Boolean) {
        immersiveModeEnabled = enabled
        WindowCompat.setDecorFitsSystemWindows(window, !enabled)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val insetsController = window.insetsController ?: return
            val systemBars =
                WindowInsets.Type.statusBars() or
                    WindowInsets.Type.navigationBars()

            if (enabled) {
                insetsController.hide(systemBars)
                insetsController.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            } else {
                insetsController.show(systemBars)
                insetsController.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_DEFAULT
            }
            return
        }

        @Suppress("DEPRECATION")
        val legacyFlags =
            if (enabled) {
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            } else {
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            }

        @Suppress("DEPRECATION")
        window.decorView.systemUiVisibility = legacyFlags
    }
}
