package com.gatiella.symmeapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager
import android.os.Bundle

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.gatiella.symmeapp/screen_protection"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableScreenProtection" -> {
                    enableScreenProtection()
                    result.success("Screen protection enabled")
                }
                "disableScreenProtection" -> {
                    disableScreenProtection()
                    result.success("Screen protection disabled")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enable screen protection by default
        enableScreenProtection()
    }

    private fun enableScreenProtection() {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    private fun disableScreenProtection() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}