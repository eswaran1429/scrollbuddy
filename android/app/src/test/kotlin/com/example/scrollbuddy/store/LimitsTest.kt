package com.example.scrollbuddy.store

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LimitsTest {
    private val counts = mapOf("instagram" to 30, "youtube" to 15)

    @Test
    fun noLimitNeverBlocks() {
        assertFalse(Limits().reached(counts, 0))
    }

    @Test
    fun limitUsesTotalOfAllApps() {
        assertTrue(Limits(dailyLimit = 45).reached(counts, 0))
        assertFalse(Limits(dailyLimit = 46).reached(counts, 0))
    }

    @Test
    fun bonusRaisesLimit() {
        assertFalse(Limits(dailyLimit = 45).reached(counts, 10))
    }
}
