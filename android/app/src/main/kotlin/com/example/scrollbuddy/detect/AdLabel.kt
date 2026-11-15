package com.example.scrollbuddy.detect

object AdLabel {
    val searchWords = listOf("Sponsored", "Ad")

    private val labels = setOf("sponsored", "ad", "paid partnership")
    private val separators = charArrayOf('·', '•', '|', '-', ':')

    fun matches(text: CharSequence?): Boolean {
        val t = text?.toString()?.trim()?.lowercase() ?: return false
        if (t in labels) return true
        val head = t.substringBefore(separators.firstOrNull { it in t } ?: return false).trim()
        return head in labels
    }
}
