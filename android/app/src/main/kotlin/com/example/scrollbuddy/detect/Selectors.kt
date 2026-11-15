package com.example.scrollbuddy.detect

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
