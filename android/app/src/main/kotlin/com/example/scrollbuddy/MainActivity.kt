package com.example.scrollbuddy

import android.content.Intent
import android.os.Bundle
import com.example.scrollbuddy.bridge.Bridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var bridge: Bridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = Bridge(this, flutterEngine.dartExecutor.binaryMessenger).also { it.register() }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        takeBlockExtra(intent)
    }

    // The service opens this activity when a reel limit is reached (singleTop: reuses it).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        takeBlockExtra(intent)
        if (blockRequested) bridge?.notifyBlock()
    }

    private fun takeBlockExtra(intent: Intent?) {
        if (intent?.getBooleanExtra(EXTRA_BLOCK, false) == true) {
            blockRequested = true
            intent.removeExtra(EXTRA_BLOCK)
        }
    }

    companion object {
        const val EXTRA_BLOCK = "scrollbuddy.block"

        /** Set when the block screen should open; Flutter reads and clears it. */
        @Volatile
        var blockRequested = false
    }
}
