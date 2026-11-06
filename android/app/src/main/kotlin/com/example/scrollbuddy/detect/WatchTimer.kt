package com.example.scrollbuddy.detect

/**
 * Adds up time spent in a reels viewer. Call [tick] regularly while watching and [stop]
 * when the viewer is left. Gaps between calls are capped at [maxGapMs], so a missed
 * stop (e.g. the screen turned off between checks) never adds a long stretch.
 * Returns whole seconds to save as (appKey, seconds), or null when nothing is due yet.
 */
class WatchTimer(private val maxGapMs: Long = 2_000, private val flushMs: Long = 10_000) {
    private var appKey: String? = null
    private var lastMs = 0L
    private var pendingMs = 0L

    fun tick(app: String, nowMs: Long): Pair<String, Int>? {
        if (app != appKey) {
            val out = stop(nowMs)
            appKey = app
            lastMs = nowMs
            return out
        }
        accrue(nowMs)
        if (pendingMs < flushMs) return null
        return take(app)
    }

    fun stop(nowMs: Long): Pair<String, Int>? {
        val app = appKey ?: return null
        accrue(nowMs)
        appKey = null
        return take(app).also { pendingMs = 0 }
    }

    private fun accrue(nowMs: Long) {
        pendingMs += (nowMs - lastMs).coerceIn(0, maxGapMs)
        lastMs = nowMs
    }

    /** Whole seconds; the remainder carries over to the next save. */
    private fun take(app: String): Pair<String, Int>? {
        val seconds = (pendingMs / 1000).toInt()
        pendingMs -= seconds * 1000L
        return if (seconds > 0) app to seconds else null
    }
}
