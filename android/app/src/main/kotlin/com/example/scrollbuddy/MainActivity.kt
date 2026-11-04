package com.example.scrollbuddy

import com.example.scrollbuddy.bridge.Bridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Bridge(this, flutterEngine.dartExecutor.binaryMessenger).register()
    }
}
