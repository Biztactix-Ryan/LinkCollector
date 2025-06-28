package com.linkcapture.link_capture

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        // The receive_sharing_intent plugin will handle the intent
        // This is just to ensure the intent is properly received
        intent?.let {
            println("MainActivity received intent: ${it.action}")
            println("Intent type: ${it.type}")
            println("Intent data: ${it.dataString}")
            println("Intent text: ${it.getStringExtra(Intent.EXTRA_TEXT)}")
        }
    }
}
