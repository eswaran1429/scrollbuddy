package com.example.scrollbuddy.overlay

/** Lines the floating counter says when today's count hits certain numbers. */
object Milestones {
    private val fixed = mapOf(
        25 to listOf("25 reels. Thumb is warmed up.", "25 already? That was fast."),
        50 to listOf("50 reels. That's a whole sitcom episode.", "50! Your thumb wants a snack break."),
        100 to listOf("100 reels. Your thumb wants a union.", "Triple digits. The algorithm is thrilled."),
        150 to listOf("150. The algorithm sends its regards.", "150 reels. Remember daylight?"),
        200 to listOf("200 reels. Maybe touch some grass?", "200! That's a movie with no plot."),
    )

    private val hundreds = listOf(
        "%d reels. Legend or victim? You decide.",
        "%d. Your screen time report is sweating.",
        "%d reels. We're not mad, just impressed.",
    )

    fun lineFor(count: Int, limit: Int?): String? {
        if (limit != null && count == limit - 10) return "10 reels left. Make them good ones."
        fixed[count]?.let { return it.random() }
        if (count > 200 && count % 100 == 0) return hundreds.random().format(count)
        return null
    }
}
