package com.example.scrollbuddy.detect

data class AppSelectors(
    val key: String,
    val packageName: String,
    val viewerIds: List<String>,
    val viewerDescriptions: List<String> = emptyList(),
    val pagerIds: List<String> = emptyList(),
    val minGapMs: Long = 400,
    val fallbackGapMs: Long = 900,
    val probePagerIndex: Boolean = false,
)

data class EventSnapshot(
    val isScroll: Boolean,
    val sourceViewId: String?,
    val fromIndex: Int,
    val toIndex: Int,
    val inViewer: Boolean,
    val timeMs: Long,
    val horizontal: Boolean = false,
)

class ReelDetector(private val app: AppSelectors) {
    private var maxIndex = NO_INDEX

    private var lastIndex = NO_INDEX

    private var away = false
    private var lastCountAt = Long.MIN_VALUE / 2

    fun leftViewer() {
        away = true
    }

    fun onEvent(e: EventSnapshot): Boolean {
        if (!e.inViewer) {
            away = true
            return false
        }
        if (!e.isScroll || e.horizontal) return false
        val id = e.sourceViewId
        if (app.pagerIds.isNotEmpty() && (id == null || app.pagerIds.none { id.contains(it) })) return false

        val index = if (e.toIndex >= 0) e.toIndex else e.fromIndex
        if (index >= 0) {
            if (away && index != lastIndex) maxIndex = NO_INDEX
            away = false
            lastIndex = index
            val furthest = maxIndex
            if (index > furthest) maxIndex = index
            if (furthest == NO_INDEX) return index > 0 && count(e.timeMs)
            if (index <= furthest) return false
            return count(e.timeMs)
        }
        return e.timeMs - lastCountAt >= app.fallbackGapMs && count(e.timeMs)
    }

    private fun count(now: Long): Boolean {
        if (now - lastCountAt < app.minGapMs) return false
        lastCountAt = now
        return true
    }

    private companion object {
        const val NO_INDEX = -1
    }
}
