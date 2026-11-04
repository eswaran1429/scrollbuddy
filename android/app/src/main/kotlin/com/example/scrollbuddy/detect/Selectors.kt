package com.example.scrollbuddy.detect

/**
 * Instagram and YouTube are verified on a device (docs/SELECTORS.md, D-26).
 * Facebook and Snapchat are UNVERIFIED first guesses (D-24): replace them with device evidence.
 */
object Selectors {
    val all = listOf(
        AppSelectors(
            key = "instagram",
            packageName = "com.instagram.android",
            viewerIds = listOf("clips_viewer", "clips_video_container"),
            pagerIds = listOf("clips_viewer_view_pager"),
        ),
        AppSelectors(
            key = "youtube",
            packageName = "com.google.android.youtube",
            viewerIds = listOf("reel_recycler", "reel_player"),
            pagerIds = listOf("reel_recycler"),
            // Device log 2026-11-04 (YouTube 21.43): one scroll event per visit, no indexes.
            probePagerIndex = true,
        ),
        AppSelectors(
            key = "facebook",
            packageName = "com.facebook.katana",
            viewerIds = listOf("reels_viewer", "reel_viewer"),
            viewerDescriptions = listOf("Reels viewer"),
        ),
        AppSelectors(
            key = "snapchat",
            packageName = "com.snapchat.android",
            viewerIds = listOf("spotlight"),
            viewerDescriptions = listOf("Spotlight"),
        ),
    )

    val byPackage: Map<String, AppSelectors> = all.associateBy { it.packageName }
}
