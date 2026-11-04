# DECISIONS.md

Decisions made while reviewing `plan.md` (2026-11-04). Where this file and `plan.md` disagree, this file wins.
Items marked **[confirm]** were picked as the simplest default and need a human yes/no before the phase that depends on them.

---

## D-01 — App name and package id **[confirm before release]**
- Name: **ScrollBuddy** (matches the existing Flutter project). "BrainGuard" in the original plan is dropped.
- Dev package id: `com.example.scrollbuddy` (already in `android/app/build.gradle.kts`).
- `com.example.*` cannot be published on Play, and changing `applicationId` after launch creates a different app. The final id (e.g. `com.<yourdomain>.scrollbuddy`) **must** be set before the first upload to any Play track (Phase 10 at the latest, ideally before Phase 8 so Firebase is registered once).
- Channel names: `scrollbuddy/control` (MethodChannel), `scrollbuddy/live_count` (EventChannel).

## D-02 — Use existing project, Android only
- Do not run `flutter create`; the project exists.
- Delete `ios/`, `linux/`, `macos/`, `web/`, `windows/` in Phase 0 (Android-only target).
- Set `minSdk = 26` explicitly in `android/app/build.gradle.kts` (do not rely on `flutter.minSdkVersion`).

## D-03 — Git
- Run `git init` in Phase 0 before any other change; commit per phase as `plan.md` §0 says.

## D-04 — Database ownership: native only
- Kotlin owns the SQLite DB (`SQLiteOpenHelper`, plain SQL, no Room). Kotlin owns schema and migrations.
- Flutter does **not** open the DB file. It reads through the MethodChannel: `getTodayCounts`, `getHistory(fromDate, toDate)`.
- Reason: data is tiny (≤ 30 days × 4 apps); sharing one file between Android's SQLite and `sqlite3_flutter_libs` adds locking/WAL/migration risk for no gain.
- Consequence: `drift` is removed from the stack.

## D-05 — Settings ownership: native only
- Everything the service needs (daily limit, per-app limits, tracked apps, unlock mode, strict-mode end time) is stored natively (SQLite `settings` table) and written via MethodChannel (`setLimits`, `setTrackedApps`, `setUnlockMode`, `startStrictMode`).
- `shared_preferences` is used only for Flutter-only UI preferences (e.g. reduced motion, onboarding done).
- Reason: Flutter's `shared_preferences` prefixes keys / may use DataStore, so the native service cannot read it reliably.

## D-06 — Foreground service: keep, type `specialUse`
- Keep `ForegroundTrackerService` for the live-count notification (MVP feature #4). On Android 14+ an ongoing notification without an FGS can be swiped away.
- Type: `specialUse`, with `<property android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE" android:value="Live reel counter shown while reel tracking is enabled"/>`. Requires a Play FGS declaration (add to `docs/PLAY_COMPLIANCE.md`).
- The FGS is started from `ReelAccessibilityService.onServiceConnected()` and stopped in `onUnbind()`/`onDestroy()`. Verify on device in Phase 1 that this start is allowed from the background on Android 12+.
- No `BootReceiver`: the system rebinds an enabled accessibility service after boot, which then starts the FGS. Re-add only if a device test shows it is needed.

## D-07 — Block screen: accessibility overlay, no `SYSTEM_ALERT_WINDOW`
- Use a `WindowManager` window of type `TYPE_ACCESSIBILITY_OVERLAY`, added from the accessibility service, then `performGlobalAction(GLOBAL_ACTION_BACK)`.
- Accessibility services may draw this window type without the overlay permission, so `SYSTEM_ALERT_WINDOW` and its onboarding screen are removed.

## D-08 — Accessibility service config
- `android:isAccessibilityTool="false"` (required by Play for non-accessibility use).
- `packageNames` limited to the four apps. Expected packages (verify in Phase 2): `com.instagram.android`, `com.google.android.youtube`, `com.facebook.katana`, `com.snapchat.android`.
- Event types: start with `typeViewScrolled|typeWindowContentChanged|typeWindowStateChanged`. Add `typeViewSelected` only if Phase 2 evidence needs it.
- User's per-app toggle is applied at runtime (ignore events in code; optionally `setServiceInfo` to narrow `packageNames`).

## D-09 — Reel signature source **[confirm]**
- Order of preference per app (set in selector JSON as `signatureSource`):
  1. `pagerIndex` — `fromIndex`/`toIndex`/`currentItem` from scroll events.
  2. `structure` — hash of view IDs + bounds of the visible item (often identical between reels, so may undercount).
  3. `contentHash` — in-memory hash of the visible reel item's text/content-description, **used only for comparison, never persisted, logged or transmitted**. Only the previous hash is kept in memory.
- Reason: a structural hash alone cannot tell two reels apart in a full-screen pager.
- Consequence: the disclosure must not say "does not read content"; it says content is not stored or sent (see `plan.md` §11).

## D-10 — First-reel counting rule
- Entering the reels viewer counts the **first reel once**, after it has been visible for `minDwellMs`.
- Each later signature change that dwells ≥ `minDwellMs` counts +1.
- Returning from background, rotation, or comment sheet with the **same** signature never counts.
- Leaving the viewer resets the signature, so re-entering counts the reel shown on entry (it is a new view).

## D-11 — Per-app accuracy fallback
- If Phase 2 shows an app cannot reach ±1 per 20 reels, ship it marked "beta" in the app list and exclude it from the MVP accuracy gate. Ship the MVP with the apps that pass. Record the evidence in `docs/SELECTORS.md`.

## D-12 — Brain state thresholds with a limit
- Without a limit: counts as in `plan.md` §9 (0–49, 50–99, 100–199, 200+).
- With a limit (ratio = count / limit): Healthy < 50 %, Tired 50–79 %, Cracking 80–99 %, Fried ≥ 100 %.

## D-13 — Strict mode wording
- Android cannot stop a user from disabling an accessibility service or uninstalling. Strict mode only blocks in-app unlock and in-app limit changes.
- UI copy must say this plainly. If the service is disabled during strict mode, show a warning on next app open.

## D-14 — Scroll Battles integrity
- Each `dailyScores` entry also stores `trackingActive: bool` and `lastHeartbeat: timestamp` (written by the same debounced sync).
- The leaderboard shows "tracking off" for friends whose heartbeat is older than 30 min or who have tracking disabled; such users cannot win that day.
- Client-written counts are trusted; cheating by editing traffic is accepted as out of scope for v1.

## D-15 — Battles data access
- Friend docs are written on **both** sides (`users/A/friends/B` and `users/B/friends/A`) by a Cloud Function on accept.
- Leaderboard reads each friend's `dailyScores/{date}/entries/{friendUid}` by doc id (no collection query), because Firestore rules can only check friendship per document.
- Date key: each user's own local date. Friends in other time zones are compared on their own "today". Accepted for v1.

## D-16 — Dependencies added per phase
- Phase 0 adds only: `get`, `go_router` (D-20).
- Others are added in the phase that first uses them: `fl_chart` (4), `shared_preferences` (4/5), `permission_handler` + `flutter_local_notifications` if needed (5), Firebase packages (8/9), `freezed`/`json_serializable` only when a model needs them.
- No codegen in v1.
- Dev/prod flavors with separate Firebase projects move from Phase 0 to Phase 8 (first Firebase use).

## D-17 — Brain visual placeholder
- Phase 4 ships a placeholder brain (Flutter `CustomPainter` or simple vector shapes) with 4 states and tweens. Original Rive artwork replaces it later when an artist delivers it; Phase 4 is not blocked on art.

## D-18 — Audience **[confirm]**
- Target audience: 13+ (not a children's app; not enrolled in Play Families). Reflect in the Play target-audience form and the privacy policy.

## D-19 — Out of scope for v1 (documented, not supported)
- Instagram Lite, Facebook Lite, YouTube ReVanced/Vanced and other forks.
- Reels/shorts watched in a browser (e.g. youtube.com/shorts).
- iOS.

## D-20 — GetX for state management (2026-11-04)
- State management uses **GetX** (`get`) instead of Riverpod: `CountsController`, `SettingsController`, `FriendsController`, registered in `lib/app/dependencies.dart` (`initDependencies()`), read with `Get.find`, rebuilt with `Obx`.
- Navigation stays on **go_router** (GetX routing and `GetMaterialApp` are not used). Snackbars and dialogs use Flutter's `ScaffoldMessenger` / `showDialog`.
- Screen-local UI state (history range, onboarding page, block countdown, chosen plan) stays in `StatefulWidget`.
- Tests call `Get.reset()` then `initDependencies()` in `setUp`.

## D-21 — Dark-only UI, BrainPal-inspired layout (2026-11-04) — **superseded by D-23**
- The app uses a single dark theme (`AppTheme.dark()`, `ThemeMode.dark`). This replaces plan.md §10 "respect system dark mode" for now. Add a light theme later if needed.
- Layout ideas (gradient pill buttons, big count, mood bubble, pill tabs) follow the reference screenshots in `assets/sample/`. Name, character art, copy text, colours and animations are ScrollBuddy's own (plan.md header rule): palette comes from `AppColors` (yellow/amber), the brain is our `BrainPainter`, and the ring around it is a limit-progress ring, not the reference's particle ring.
- `assets/sample/` holds screenshots of another app. It is not listed under `flutter: assets:` and must never be bundled.
- Shared UI widgets live in `lib/core/custom_widgets/`: `AppButton`, `AppIconButton`, `AppCard`, `PillTabs`, `SpeechBubble`, `AppTile`/`AppTileGroup`/`IconBadge`, `AppBottomNav`, `Wordmark`.

## D-22 — No premium tier (2026-11-04)
- ScrollBuddy has no subscription, paywall or Pro features. Blocking, strict mode, per-app limits and 30-day history are free for everyone.
- Removed: `AppSettings.isPro`, `setPro`, the paywall screen and `/paywall` route, `ProBanner`/`ProChip`, the locked-tab option on `PillTabs`. `AppColors.proGradient` renamed to `warmGradient` (still used by the Battles friend-code card).
- plan.md Phase 7 (Subscriptions) is dropped. No `purchases_flutter` / RevenueCat, no entitlement mirrored to native.
- Play Data Safety form: no purchase data.

## D-23 — "Calm light" UI (2026-11-04)
- Replaces D-21. The dark, sample-like look was too close to the reference app, so the UI was rebuilt in a different direction chosen by the owner: light and calm.
- Single light theme (`AppTheme.light()`, `ThemeMode.light`). A dark variant can be added later; plan.md §10 "respect system dark mode" is still open.
- Palette in `AppColors`: off-white `bg`, white `surface`, sage accent, lavender and peach as soft tints, coral for warnings. Cards are white with soft shadows (`AppShadows.sm`), no borders.
- Layout differences from the reference: greeting header instead of a logo bar, brain on a soft blob inside a limit ring, 2×2 per-app cards with 7-day sparklines, line chart (not bars) on History, tinted stat tiles, floating white pill nav, iOS-style segmented control, solid (not gradient) buttons. Speech bubble and gradient pills removed.
- `assets/sample/` must still never be bundled.

## D-24 — Native store + basic counting, no dummy data (2026-11-04)
- Implemented: Kotlin `CounterStore` (SQLite `scrollbuddy.db`: `daily_counts`, `settings` key/value), `Bridge` (MethodChannel `scrollbuddy/control`, EventChannel `scrollbuddy/live_count`), `ReelAccessibilityService` + pure `ReelDetector` with JVM tests. Dart uses `MethodChannelBridge`; the fake bridge now lives only in `test/`.
- All dummy data removed: no random history, no fake friends. Counts start at 0 and come only from the service (or the debug-only "add reels" button, which writes to the real store).
- Settings, including `onboardingDone`, are one JSON blob in the native `settings` table (instead of `shared_preferences` for UI-only flags, D-05): one store, and the service reads `trackedApps` from it.
- Detection rules in `detect/Selectors.kt` are **unverified guesses** (Instagram/YouTube view IDs; Facebook/Snapchat by content-description). They must be checked on a device and recorded in `docs/SELECTORS.md` (plan.md Phase 2). Expect Facebook and Snapchat to undercount or not count.
- Counting rule differs from D-10: the first item index seen in the viewer is a baseline and counts only if it is past item 0; entering the viewer on the first reel does not count until the next swipe. Revisit with device logs.
- Not yet: foreground notification service (D-06), blocking overlay, remote selector config.

## D-25 — Floating counter overlay + logo (2026-11-04)
- `overlay/CountBubble.kt`: dark pill with the logo and today's total, top-center over the reels viewer (idea from `assets/sample/flutter_07.png`; own colours and layout). `TYPE_ACCESSIBILITY_OVERLAY`, not focusable, not touchable, so the app underneath works normally. Pops on each new reel.
- Shown only while `ReelAccessibilityService` thinks the user is in a reels viewer and `showOverlay` is on (Settings → Display → Floating counter, default on). Because events only arrive from the 4 apps, a 1 s check of the active window hides it after leaving the app.
- Its visibility depends on the unverified viewer rules (D-24): if the viewer is not detected, the bubble will not show.
- Logo: `assets/images/logo.png` cropped to the face (no lightning bolt) into launcher icons (`mipmap-*/ic_launcher.png`), `drawable-nodpi/overlay_logo.png`, and `assets/images/logo_mark.png` (the only image bundled in Flutter). App label is now "ScrollBuddy".

## D-26 — YouTube Shorts counting via list position (2026-11-04)
- Device logs (Realme RMX3771, YouTube 21.43.523): the Shorts `reel_recycler` sends one `TYPE_VIEW_SCROLLED` per visit with no indexes, so the scroll-based rule never counted.
- `AppSelectors.probePagerIndex` (YouTube only): on any event in the viewer, at most every 250 ms, read `collectionItemInfo.rowIndex` of the pager child under the screen centre and feed it to `ReelDetector` as an indexed scroll. Verified: 5 swipes → rowIndex 0→5 → 5 counts.
- Viewer detection now only matches nodes that are visible on screen (Instagram keeps the hidden Reels tab in the tree, which showed the bubble on the home feed).
- Debug builds log event metadata (types, view IDs, indexes, never text) to logcat tag `ScrollBuddy`.

## D-27 — Flip counter, draggable (2026-11-04)
- Overlay redesigned as a split-flap counter (purple frame, ≥2 digit tiles, mascot peeking over the top). Changed digits flip (≈320 ms, `Camera.rotateX`); a new digit tile (99 → 100) appears without flipping. Replaces the D-25 pill.
- The overlay is now touchable (`FLAG_NOT_TOUCH_MODAL`, no `FLAG_NOT_TOUCHABLE`): drag to move. The window is only as big as the counter, so touches elsewhere still reach the app; taps on the counter itself do not. Position is clamped to the screen and saved in the native `settings` table (`overlay_position`), cleared by "Delete all data".
