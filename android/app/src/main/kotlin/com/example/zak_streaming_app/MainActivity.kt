package com.example.zak_streaming_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "app.channel.shared.data"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val appLinkAction = intent?.action
        val appLinkData = intent?.data
        if (Intent.ACTION_VIEW == appLinkAction && appLinkData != null) {
            if (appLinkData.toString() == "https://zak.lodz.pl/play") {
                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, channel).invokeMethod("play", null)
            }
        }
    }
}
