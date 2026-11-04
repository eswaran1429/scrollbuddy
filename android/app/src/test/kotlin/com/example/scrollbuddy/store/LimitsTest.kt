package com.example.scrollbuddy.store

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LimitsTest {
    private val counts = mapOf("instagram" to 30, "youtube" to 15)

    @Test
    fun blockingOffNeverBlocks() {
        assertFalse(Limits(blockingEnabled = false, dailyLimit = 10).reached(counts, "instagram", 0))
    }

    @Test
    fun dailyLimitUsesTotalOfAllApps() {
        val l = Limits(blockingEnabled = true, dailyLimit = 45)
        assertTrue(l.reached(counts, "youtube", 0))
        assertFalse(Limits(blockingEnabled = true, dailyLimit = 46).reached(counts, "youtube", 0))
    }

    @Test
    fun perAppLimitOnlyBlocksThatApp() {
        val l = Limits(blockingEnabled = true, perApp = mapOf("instagram" to 30))
        assertTrue(l.reached(counts, "instagram", 0))
        assertFalse(l.reached(counts, "youtube", 0))
    }

    @Test
    fun bonusRaisesLimits() {
        val l = Limits(blockingEnabled = true, dailyLimit = 45, perApp = mapOf("instagram" to 30))
        assertFalse(l.reached(counts, "instagram", 10))
        assertTrue(l.reached(counts, "instagram", 0))
    }
}
