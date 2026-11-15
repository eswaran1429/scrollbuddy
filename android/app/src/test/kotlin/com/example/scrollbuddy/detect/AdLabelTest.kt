package com.example.scrollbuddy.detect

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AdLabelTest {
    @Test
    fun `matches bare labels in any case`() {
        assertTrue(AdLabel.matches("Sponsored"))
        assertTrue(AdLabel.matches(" sponsored "))
        assertTrue(AdLabel.matches("Ad"))
        assertTrue(AdLabel.matches("AD"))
        assertTrue(AdLabel.matches("Paid partnership"))
    }

    @Test
    fun `matches a label followed by a separator`() {
        assertTrue(AdLabel.matches("Ad · 0:15"))
        assertTrue(AdLabel.matches("Sponsored • Shop now"))
    }

    @Test
    fun `ignores captions and words that only contain the label`() {
        assertFalse(AdLabel.matches(null))
        assertFalse(AdLabel.matches(""))
        assertFalse(AdLabel.matches("Add"))
        assertFalse(AdLabel.matches("Add to cart"))
        assertFalse(AdLabel.matches("Adventure time"))
        assertFalse(AdLabel.matches("not sponsored lol"))
        assertFalse(AdLabel.matches("This is not an ad · trust me"))
        assertFalse(AdLabel.matches("Sponsored by nobody, just love this"))
    }
}
