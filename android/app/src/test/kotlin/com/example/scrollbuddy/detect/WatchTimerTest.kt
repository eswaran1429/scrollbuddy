package com.example.scrollbuddy.detect

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WatchTimerTest {
    @Test
    fun savesEveryTenSecondsWhileWatching() {
        val t = WatchTimer()
        assertNull(t.tick("instagram", 0))
        for (ms in 1_000L..9_000L step 1_000) assertNull(t.tick("instagram", ms))
        assertEquals("instagram" to 10, t.tick("instagram", 10_000))
    }

    @Test
    fun stopSavesWhatIsLeft() {
        val t = WatchTimer()
        t.tick("youtube", 0)
        t.tick("youtube", 1_000)
        assertEquals("youtube" to 2, t.stop(2_500)) // 2.5 s → 2 whole seconds
        assertNull(t.stop(5_000)) // already stopped
    }

    @Test
    fun longGapIsCapped() {
        val t = WatchTimer()
        t.tick("instagram", 0)
        assertEquals("instagram" to 2, t.stop(60_000)) // screen off for a minute counts 2 s, not 60
    }

    @Test
    fun switchingAppsSavesThePreviousApp() {
        val t = WatchTimer()
        t.tick("instagram", 0)
        t.tick("instagram", 1_000)
        t.tick("instagram", 2_000)
        assertEquals("instagram" to 3, t.tick("youtube", 3_000))
        assertEquals("youtube" to 1, t.stop(4_000))
    }
}
