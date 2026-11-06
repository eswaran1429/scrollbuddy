package com.example.scrollbuddy.store

/** The daily reel limit (saved by Flutter). Setting a limit turns blocking on. */
data class Limits(val dailyLimit: Int? = null) {
    /** True when today's total across all apps has reached the limit plus [bonus] unlocked reels. */
    fun reached(counts: Map<String, Int>, bonus: Int): Boolean =
        dailyLimit != null && counts.values.sum() >= dailyLimit + bonus
}
