package com.example.scrollbuddy.detect

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ReelDetectorTest {
    private val pagerApp = AppSelectors(
        key = "test",
        packageName = "test.pkg",
        viewerIds = listOf("viewer"),
        pagerIds = listOf("pager"),
    )
    private val noIndexApp = pagerApp.copy(pagerIds = emptyList())

    private fun scroll(t: Long, index: Int, inViewer: Boolean = true, id: String? = "pkg:id/pager") =
        EventSnapshot(isScroll = true, sourceViewId = id, fromIndex = index, toIndex = index, inViewer = inViewer, timeMs = t)

    private fun countAll(d: ReelDetector, events: List<EventSnapshot>) = events.count { d.onEvent(it) }

    @Test
    fun `counts each index change once`() {
        val d = ReelDetector(pagerApp)
        // Each swipe fires several scroll events with the same new index.
        val events = listOf(
            scroll(0, 0), scroll(50, 0),
            scroll(1000, 1), scroll(1050, 1), scroll(1100, 1),
            scroll(2000, 2), scroll(2040, 2),
        )
        assertEquals(2, countAll(d, events))
    }

    @Test
    fun `nothing counts outside the viewer and position resets`() {
        val d = ReelDetector(pagerApp)
        assertFalse(d.onEvent(scroll(0, 3, inViewer = false)))
        assertFalse(d.onEvent(scroll(100, 4, inViewer = false)))
        // Back in the viewer at index 0: baseline, no count.
        assertFalse(d.onEvent(scroll(1000, 0)))
        assertTrue(d.onEvent(scroll(2000, 1)))
    }

    @Test
    fun `first index past zero counts (user already swiped)`() {
        val d = ReelDetector(pagerApp)
        assertTrue(d.onEvent(scroll(0, 1)))
    }

    @Test
    fun `fast flings within min gap count once`() {
        val d = ReelDetector(pagerApp)
        d.onEvent(scroll(0, 0))
        val events = listOf(scroll(1000, 1), scroll(1100, 2), scroll(1200, 3))
        assertEquals(1, countAll(d, events))
    }

    @Test
    fun `scrolls from other views are ignored`() {
        val d = ReelDetector(pagerApp)
        d.onEvent(scroll(0, 0))
        assertFalse(d.onEvent(scroll(1000, 1, id = "pkg:id/comments_list")))
        // Unknown source id (e.g. no view ids) is still accepted.
        assertTrue(d.onEvent(scroll(2000, 2, id = null)))
    }

    @Test
    fun `without indexes one burst counts once`() {
        val d = ReelDetector(noIndexApp)
        val burst1 = listOf(scroll(0, -1), scroll(60, -1), scroll(120, -1))
        val burst2 = listOf(scroll(1500, -1), scroll(1560, -1))
        assertEquals(2, countAll(d, burst1 + burst2))
    }

    @Test
    fun `non-scroll events never count`() {
        val d = ReelDetector(pagerApp)
        assertFalse(d.onEvent(scroll(0, 5).copy(isScroll = false)))
    }
}
