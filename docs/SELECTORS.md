# SELECTORS.md

Per-app rules used by `ReelAccessibilityService` (`android/app/src/main/kotlin/com/example/scrollbuddy/detect/Selectors.kt`).

**Status: Instagram and YouTube verified on a device (D-26); Facebook and Snapchat are still unverified guesses (D-24).** Replace each row with evidence from a real device: app version, a `uiautomator dump` or Layout Inspector capture of the reels viewer, and a log of scroll events while swiping 10 reels.

| App | Package | "In reels viewer" (view ID / description contains) | Pager view ID | Verified |
|-----|---------|------------------------------------------------------|---------------|----------|
| Instagram | `com.instagram.android` | `clips_viewer`, `clips_video_container` (visible nodes only) | `clips_viewer_view_pager` (ViewPager, scroll events carry from/to index) | yes, 2026-11-04 (RMX3771) |
| YouTube | `com.google.android.youtube` 21.43.523 | `reel_recycler` | `reel_recycler` (RecyclerView). No per-swipe scroll events, so `probePagerIndex`: `collectionItemInfo.rowIndex` of the child under screen centre | yes, 2026-11-04 (RMX3771) |
| Facebook | `com.facebook.katana` | `reels_viewer`, `reel_viewer`; desc "Reels viewer" | any | no |
| Snapchat | `com.snapchat.android` | `spotlight`; desc "Spotlight" | any | no |

## How to check on a phone
1. Install the debug build, turn on ScrollBuddy in Settings → Accessibility.
2. Open the app's Reels/Shorts, run `adb shell uiautomator dump /sdcard/v.xml && adb pull /sdcard/v.xml`.
3. Search the XML for `resource-id` values on the full-screen pager / video container. Note the app version (`adb shell dumpsys package <pkg> | grep versionName`).
4. Swipe 20 reels and compare with the Today count. Record the result here.
