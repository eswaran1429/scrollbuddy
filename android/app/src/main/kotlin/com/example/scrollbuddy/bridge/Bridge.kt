package com.example.scrollbuddy.bridge

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import com.example.scrollbuddy.MainActivity
import com.example.scrollbuddy.service.ReelAccessibilityService
import com.example.scrollbuddy.store.CounterStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** MethodChannel "scrollbuddy/control" + EventChannel "scrollbuddy/live_count" (D-01). */
class Bridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val store = CounterStore.get(activity)
    private val main = Handler(Looper.getMainLooper())
    private val control = MethodChannel(messenger, "scrollbuddy/control")
    private val live = EventChannel(messenger, "scrollbuddy/live_count")

    fun register() {
        control.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> result.success(isServiceEnabled())
                "openAccessibilitySettings" -> {
                    activity.startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "getToday" -> result.success(day(CounterStore.today()))
                "getHistory" -> {
                    val days = call.argument<Int>("days") ?: 7
                    result.success(store.history(days).map { (date, _) -> day(date) })
                }
                "loadSettings" -> result.success(store.settingsJson())
                "saveSettings" -> {
                    store.saveSettingsJson(call.argument<String>("json") ?: "{}")
                    result.success(null)
                }
                "debugIncrement" -> {
                    val app = call.argument<String>("app")
                    if (app == null) {
                        result.error("args", "app missing", null)
                    } else {
                        store.increment(app, call.argument<Int>("by") ?: 1)
                        result.success(null)
                    }
                }
                "resetToday" -> {
                    store.resetToday()
                    result.success(null)
                }
                "takeBlockRequest" -> {
                    result.success(MainActivity.blockRequested)
                    MainActivity.blockRequested = false
                }
                "grantBonus" -> {
                    store.addBonus(call.argument<Int>("reels") ?: 0)
                    result.success(null)
                }
                "deleteAll" -> {
                    store.deleteAll()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        live.setStreamHandler(object : EventChannel.StreamHandler {
            private var listener: CounterStore.Listener? = null

            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                val l = CounterStore.Listener { _ ->
                    main.post { sink.success(day(CounterStore.today())) }
                }
                listener = l
                store.addListener(l)
                sink.success(day(CounterStore.today()))
            }

            override fun onCancel(arguments: Any?) {
                listener?.let(store::removeListener)
                listener = null
            }
        })
    }

    /** Asks Flutter to open the block screen (app already running). */
    fun notifyBlock() {
        main.post { control.invokeMethod("blockRequested", null) }
    }

    private fun isServiceEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            activity.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        val me = ComponentName(activity, ReelAccessibilityService::class.java)
        return enabled.split(':').any { ComponentName.unflattenFromString(it) == me }
    }

    /** One day for Flutter: reel counts and seconds in reels, per app. */
    private fun day(date: String) =
        mapOf("date" to date, "counts" to store.countsFor(date), "seconds" to store.secondsFor(date))
}
