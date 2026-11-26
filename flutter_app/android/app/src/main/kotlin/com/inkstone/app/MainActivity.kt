package com.inkstone.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Receives text shared from other apps (listing links). Held in memory only.
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var initialText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialText = sharedText(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.inkstone.app/share").also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "initialText") {
                    result.success(initialText)
                    initialText = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val text = sharedText(intent) ?: return
        channel?.invokeMethod("sharedText", text)
    }

    private fun sharedText(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND || intent.type != "text/plain") return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)
    }
}
