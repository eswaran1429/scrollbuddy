package com.example.scrollbuddy.detect

/** Per-app detection rules. See [Selectors] for current values. */
data class AppSelectors(
    val key: String,
    val packageName: String,
    /** Substrings of view IDs that mean "the reels viewer is on screen". */
    val viewerIds: List<String>,
    /** Substrings of content descriptions that mean the same (checked in memory only, never stored). */
    val viewerDescriptions: List<String> = emptyList(),
    /**
     * Substrings of the pager's view ID. When set, only scroll events from that pager count
     * (events without an ID come from other lists, e.g. sideways carousels). Empty = any source.
     */
    val pagerIds: List<String> = emptyList(),
    /** Ignore a second count within this many ms (fast flings, event storms). */
    val minGapMs: Long = 400,
    /** When the event has no item index, one swipe sends a burst; count once per this gap. */
    val fallbackGapMs: Long = 900,
    /**
     * The pager sends no scroll event per swipe (YouTube Shorts). Instead, on content changes,
     * read the list position (`collectionItemInfo.rowIndex`) of the item under the screen centre.
     */
    val probePagerIndex: Boolean = false,
)

/** Simplified accessibility event, so the detector can be unit-tested on the JVM. */
data class EventSnapshot(
    val isScroll: Boolean,
    val sourceViewId: String?,
    val fromIndex: Int,
    val toIndex: Int,
    val inViewer: Boolean,
    val timeMs: Long,
    /** The scroll moved more sideways than up/down (carousels, tab swipes). */
    val horizontal: Boolean = false,
)

/**
 * Decides whether an event means "user moved to a new reel".
 *
 * Rules (basic version, plan.md §8.2):
 * - Outside the reels viewer nothing counts, and the current position is forgotten.
 * - Sideways scrolls and scrolls from other lists never count (reels are swiped up/down).
 * - With item indexes: count when the index changes. The first index seen is a baseline;
 *   it counts only if it is past the first item (the user already swiped).
 * - Without indexes: count one scroll burst per [AppSelectors.fallbackGapMs].
 */
class ReelDetector(private val app: AppSelectors) {
    private var lastIndex = NO_INDEX
    private var lastCountAt = Long.MIN_VALUE / 2

    fun onEvent(e: EventSnapshot): Boolean {
        if (!e.inViewer) {
            lastIndex = NO_INDEX
            return false
        }
        if (!e.isScroll || e.horizontal) return false
        val id = e.sourceViewId
        if (app.pagerIds.isNotEmpty() && (id == null || app.pagerIds.none { id.contains(it) })) return false

        val index = if (e.toIndex >= 0) e.toIndex else e.fromIndex
        if (index >= 0) {
            val previous = lastIndex
            lastIndex = index
            if (previous == NO_INDEX) return index > 0 && count(e.timeMs)
            if (index == previous) return false
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
