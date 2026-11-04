package com.example.scrollbuddy.store

/** Limit settings the service needs to decide when to block (saved by Flutter). */
data class Limits(
    val blockingEnabled: Boolean = false,
    val dailyLimit: Int? = null,
    val perApp: Map<String, Int> = emptyMap(),
) {
    /**
     * True when reels in [appKey] should be blocked: blocking is on and today's total
     * or that app's count has reached its limit. [bonus] reels unlocked today raise both.
     */
    fun reached(counts: Map<String, Int>, appKey: String, bonus: Int): Boolean {
        if (!blockingEnabled) return false
        val total = counts.values.sum()
        if (dailyLimit != null && total >= dailyLimit + bonus) return true
        val appLimit = perApp[appKey] ?: return false
        return (counts[appKey] ?: 0) >= appLimit + bonus
    }
}
