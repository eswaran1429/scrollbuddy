package com.example.scrollbuddy.store

data class Limits(val dailyLimit: Int? = null) {
    fun reached(counts: Map<String, Int>, bonus: Int): Boolean =
        dailyLimit != null && counts.values.sum() >= dailyLimit + bonus
}
