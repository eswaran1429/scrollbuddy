# plan.md — Reel Scroll Tracker App (BrainPal-style) in Flutter

> **Working title:** `ScrollBuddy`
> **Package id:** `com.example.scrollbuddy` (dev only — final id must be set before first Play upload, see `docs/DECISIONS.md` D-01)
> **Decisions:** `docs/DECISIONS.md` overrides this file where they disagree.
> **Target:** Android only (Flutter UI + native Kotlin Accessibility Service)
> **Reference app:** BrainPal (`com.brainrot.android`) — used for feature inspiration only. Do **not** copy its name, icon, artwork, copy text, or animations. Create original branding and assets.

---

## 0. How Claude Code should use this file

1. Read this whole file and `docs/DECISIONS.md` before writing code.
2. Work **phase by phase** (Section 7). Finish and verify one phase before starting the next.
3. After each phase: run `flutter analyze`, `flutter test`, and the Android build (`flutter build apk --debug`). Fix everything before moving on.
4. Commit after every phase with a message like `phase-3: reel counter engine`.
5. If something here is ambiguous or a decision is missing, choose the simplest option, write the decision in `docs/DECISIONS.md`, and continue.
6. Tick the checkboxes in this file as tasks are completed.

---

## 1. Product summary

An app that **counts every short-form video ("reel"/"short") the user scrolls** across Instagram, YouTube, Facebook and Snapchat, in real time, and makes the cost of scrolling visible and actionable.

### Core features (MVP)

| # | Feature | Description |
|---|---------|-------------|
| 1 | **Reel counter** | Live per-app and total daily reel count using an Android Accessibility Service. |
| 2 | **Brain state visual** | An animated brain/avatar that degrades as the daily count rises (healthy → tired → cracking → fried). |
| 3 | **Dashboard & history** | Today's count, per-app breakdown, 7/30-day charts, streaks, best day. |
| 4 | **Persistent live counter** | Foreground-service notification showing the current count. |
| 5 | **Limits & blocking** | Set a daily reel cap; when hit, block further reels/shorts with a full-screen overlay. |
| 6 | **Unlock challenges** | Optional friction to unlock after limit (task/wait). Also a **strict mode** where it cannot be unlocked until the timer ends. |
| 7 | **Scroll Battles** | Add friends, compare daily counts. Lower count wins. |

### Non-goals (v1)

- iOS (no API exists to count reels inside other apps; Screen Time APIs cannot do this).
- Reading or storing any video content, captions, usernames, or messages.
- Tracking apps other than the four listed.

---

## 2. Hard constraints and honest caveats

- **Flutter cannot run an Accessibility Service.** The detection engine must be written in **native Kotlin** and bridged to Flutter via `MethodChannel` / `EventChannel`. Flutter owns the UI; Kotlin owns detection, blocking and the foreground service.
- **Third-party app UIs change.** View IDs and structure inside Instagram/YouTube/etc. change between versions. Detection selectors must live in a **remote-updatable JSON config** (with a bundled fallback) so a fix does not need an app release.
- **Do not hardcode view IDs from memory.** Discover them on a real device (Layout Inspector / `uiautomator dump` / Accessibility Scanner) and record the findings in `docs/SELECTORS.md`.
- **Google Play policy:** Accessibility API use requires a prominent in-app disclosure, explicit consent before enabling, a Permissions Declaration Form, and `android:isAccessibilityTool="false"` in the service config. See Section 11.
- **OEM battery killers** (Xiaomi, Oppo, Vivo, Samsung, etc.) can kill the service. Build a guidance flow for this (Phase 8).

---

## 3. Tech stack

### Flutter (UI layer)
- Flutter stable, Dart 3.x, null safety, `flutter_lints`
> Add each package in the phase that first needs it, not all in Phase 0 (D-16).

- State management: **GetX** (`get`; controllers + `Obx`, no GetX routing — D-20)
- Navigation: `go_router`
- Local storage: none for counts/history (read from native via MethodChannel, D-04); `shared_preferences` only for Flutter-only UI prefs (D-05)
- Charts: `fl_chart`
- Animation: placeholder `CustomPainter` brain first; `rive` when original artwork exists (D-17)
- Models: `freezed` + `json_serializable` only if a model needs them
- Backend SDKs: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`, `firebase_remote_config`, `firebase_crashlytics`, `firebase_analytics`
- Notifications: `flutter_local_notifications`
- Permissions helpers: `permission_handler`
- i18n: `flutter_localizations` + `intl` (English first, ARB-based)

### Android native (Kotlin)
- `AccessibilityService` subclass (detection + blocking trigger)
- Foreground `Service`, type `specialUse` (live notification), started by the accessibility service (D-06)
- `WindowManager` window of type `TYPE_ACCESSIBILITY_OVERLAY` for the block screen — no `SYSTEM_ALERT_WINDOW` (D-07)
- Plain SQLite (`SQLiteOpenHelper`) owned by Kotlin; Flutter reads via MethodChannel (D-04)
- Day rollover handled in `CounterStore` on each write (compare local date); no `BootReceiver` unless a device test needs it (D-06)
- Min SDK 26 (set explicitly), target SDK = latest required by Play

### Backend (Scroll Battles only)
- Firebase Auth (Google sign-in + anonymous → linked)
- Cloud Firestore
- Cloud Functions (TypeScript) for friend codes, leaderboards cleanup, validation

---

## 4. Architecture

```
┌──────────────────────────── Flutter (Dart) ─────────────────────────────┐
│  UI (screens/widgets)                                                    │
│     ↕ GetX controllers (Obx)                                             │
│  Repositories ── PlatformBridge (counts/history) ── Firestore (battles)  │
│     ↕                                                                    │
│  Platform bridge: MethodChannel "scrollbuddy/control"                     │
│                   EventChannel  "scrollbuddy/live_count"                  │
└───────────────────────────────────┬──────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼──────────────────────────────────────┐
│ Android native (Kotlin)                                                  │
│  ReelAccessibilityService ──► ReelDetector (per-app strategies)          │
│          │                         │                                     │
│          │                         ▼                                     │
│          │                   CounterStore (SQLite, source of truth)      │
│          │                         │                                     │
│          ▼                         ▼                                     │
│   BlockController ◄──── LimitEvaluator      ForegroundTrackerService     │
│   (overlay / GLOBAL_ACTION_BACK)            (notification, EventChannel) │
└──────────────────────────────────────────────────────────────────────────┘
```

**Key rule:** the **native side is the source of truth** for counts. It must keep counting correctly even if the Flutter engine is not running. Flutter reads from the same store and subscribes to live updates when the UI is open.

---

## 5. Data model

### Local (SQLite, written by Kotlin, read by Flutter)

```
reel_events        -- optional raw log, trimmed after 7 days
  id INTEGER PK
  app_package TEXT        -- e.g. instagram | youtube | facebook | snapchat
  ts_utc INTEGER
  local_date TEXT         -- YYYY-MM-DD in user's timezone at event time

daily_counts       -- aggregate, source for UI
  local_date TEXT
  app_key TEXT            -- instagram | youtube | facebook | snapchat
  count INTEGER
  PRIMARY KEY (local_date, app_key)

settings           -- native SQLite table, written via MethodChannel (D-05)
  daily_limit INTEGER NULL
  per_app_limits JSON
  tracked_apps JSON
  strict_mode_until INTEGER NULL
  unlock_mode TEXT        -- none | task | wait | strict
  heartbeat_ts INTEGER    -- last time the service processed an event
```

Decision (D-04): Kotlin owns the DB file, schema and migrations via a small `CounterStore`. Flutter never opens the file; it calls `getTodayCounts` / `getHistory` over the MethodChannel and uses the EventChannel only for the live number.

### Firestore (Scroll Battles)

```
users/{uid}
  displayName, photoUrl, friendCode (unique, 8 chars), createdAt

users/{uid}/friends/{friendUid}
  status: "pending" | "accepted", createdAt

dailyScores/{yyyy-MM-dd}/entries/{uid}     // date = the user's own local date (D-15)
  count: number, updatedAt: timestamp   // only the total, never per-app content
  trackingActive: bool, lastHeartbeat: timestamp   // D-14
```

Security rules: a user may write only their own `dailyScores` entry and may read entries only of accepted friends. Friend docs are written on both sides by a Cloud Function; the leaderboard reads each friend's entry by doc id (no collection query), since rules check friendship per document. Include rules in `firebase/firestore.rules` with emulator tests.

---

## 6. Project structure

```
scrollbuddy/
├── plan.md
├── docs/
│   ├── DECISIONS.md
│   ├── SELECTORS.md            # discovered view IDs/structures per app + version
│   └── PLAY_COMPLIANCE.md
├── lib/
│   ├── main.dart
│   ├── app/                    # app widget, router, theme
│   ├── core/                   # constants, utils, platform bridge, errors
│   ├── data/                   # repositories, remote config
│   └── features/
│       ├── onboarding/         # disclosure, permissions, app selection
│       ├── dashboard/          # today's count, brain, per-app breakdown
│       ├── history/            # charts, streaks
│       ├── limits/             # caps, strict mode, unlock settings
│       ├── blocking/           # unlock challenge screens
│       ├── battles/            # friends, leaderboard
│       └── settings/
├── android/app/src/main/kotlin/com/example/scrollbuddy/
│   ├── MainActivity.kt
│   ├── bridge/                 # MethodChannel + EventChannel handlers
│   ├── service/
│   │   ├── ReelAccessibilityService.kt
│   │   └── ForegroundTrackerService.kt
│   ├── detect/
│   │   ├── ReelDetector.kt     # interface
│   │   ├── InstagramDetector.kt
│   │   ├── YouTubeDetector.kt
│   │   ├── FacebookDetector.kt
│   │   ├── SnapchatDetector.kt
│   │   └── SelectorConfig.kt   # loads remote/bundled JSON
│   ├── block/
│   │   ├── BlockController.kt
│   │   └── BlockOverlay.kt
│   └── store/CounterStore.kt
├── android/app/src/main/res/xml/accessibility_service_config.xml
├── assets/selectors/selectors_default.json
├── assets/rive/                # original brain animation
├── functions/                  # Firebase Cloud Functions (TS)
└── firebase/                   # rules, emulator config
```

---

## 7. Implementation phases

### Phase 0 — Scaffold
- [ ] `git init`; first commit of the existing project (D-03)
- [ ] Project already exists (`scrollbuddy`); do not run `flutter create`. Delete `ios/`, `linux/`, `macos/`, `web/`, `windows/` (D-02)
- [ ] Set `minSdk = 26` explicitly in `android/app/build.gradle.kts`
- [ ] Add only `get` and `go_router`; keep `flutter_lints` (D-16, D-20)
- [ ] Set up theme (dark-first), app shell, `go_router`, GetX controllers (`initDependencies()`)
- [ ] Create remaining `docs/` files and the folder structure above
- ~~Flavors `dev` / `prod`~~ → moved to Phase 8 (D-16)

**Done when:** app launches to an empty dashboard; `flutter analyze` is clean.

### Phase 1 — Native bridge and foreground service
- [x] Create `MethodChannel("scrollbuddy/control")` with: `isAccessibilityEnabled`, `openAccessibilitySettings`, `startTracking`, `stopTracking`, `getTodayCounts`, `getHistory`, `setLimits`, `setTrackedApps` (no overlay-permission methods, D-07)
- [x] Create `EventChannel("scrollbuddy/live_count")` that streams `{total, perApp:{...}}`
- [x] Native `CounterStore` (SQLite) as single source of truth (D-04)
- [ ] Implement `ForegroundTrackerService` with a persistent low-priority notification showing the current count
- [ ] Add Android 13+ notification permission flow and `foregroundServiceType="specialUse"` + subtype property (D-06)
- [ ] Verify on device: FGS can be started from `ReelAccessibilityService.onServiceConnected()` on Android 12+
- [x] Dart side: `PlatformBridge` class + GetX controllers, with a fake implementation for tests

**Done when:** tapping a debug button increments a counter in Kotlin and the Flutter UI and notification both update live.

### Phase 2 — Selector discovery (manual + documented)
> This phase needs a **real Android device** with the four apps installed. If Claude Code has no device access, generate a small debug tool and ask the human to run it and paste results.

- [ ] Build a **debug-only "Inspector" mode** in the accessibility service: when enabled, it logs (to a local file, never remote) the view-ID tree, class names, scroll event types and `fromIndex/toIndex/scrollY` for the foreground app
- [ ] Human records: opening Reels/Shorts in each app, scrolling 10 reels, and exports the log
- [ ] Analyse logs and fill `docs/SELECTORS.md` with: package name, app version, the container node that identifies "inside the reels viewer", and which event reliably fires once per reel change
- [ ] Produce `assets/selectors/selectors_default.json` (schema in Section 8)

**Done when:** for each of the four apps there is a written, evidence-backed rule for "in reels viewer" and "reel changed", or the app is marked "beta" with evidence of why (D-11).

### Phase 3 — Reel counting engine
- [x] `accessibility_service_config.xml`: restrict `packageNames` to the four apps; request only needed event types (`typeViewScrolled`, `typeWindowContentChanged`, `typeWindowStateChanged`; add `typeViewSelected` only if Phase 2 needs it); set `canRetrieveWindowContent=true`, `isAccessibilityTool="false"`; do **not** request gestures/keylogging (D-08)
- [x] `ReelAccessibilityService.onAccessibilityEvent` → route by package to the matching `ReelDetector`
- [ ] Implement counting rules (Section 8) including dedupe, debounce and dwell
- [ ] `CounterStore` increments `daily_counts` atomically; handle local-midnight rollover and timezone change
- [ ] Emit live updates to the EventChannel + notification (rate-limited to ≤ 2 updates/sec)
- [x] Unit tests (JVM) for the detector logic using recorded/synthetic event sequences

**Done when:** on a real device, scrolling 20 reels in each app yields a count within ±1 of the true number, with no double counting on app switch, rotation or backgrounding.

### Phase 4 — Dashboard, history and brain visual
- [ ] Dashboard: big live count, per-app chips, "vs yesterday" delta, brain visual
- [ ] Brain state mapping (Section 9) driven by total daily count (or % of limit if a limit is set, D-12)
- [ ] Placeholder brain (`CustomPainter`) with smooth transitions between 4 states; swap to original Rive artwork when available (D-17)
- [ ] History screen: 7/30-day bar chart (`fl_chart`), best day, current "under-limit" streak
- [ ] Empty/loading/error states; pull-to-refresh not required (live stream)

**Done when:** brain visibly changes state as the count crosses thresholds, with no jank (profile mode ≥ 55 fps).

### Phase 5 — Onboarding and permissions (Play-compliant)
- [ ] Screen 1: value proposition
- [ ] Screen 2: **Prominent disclosure** before any Accessibility prompt (exact wording in Section 11), with explicit **Agree / No thanks** buttons
- [ ] Screen 3: select which of the four apps to track (only show installed ones)
- [ ] Screen 4: deep-link to Accessibility settings, detect when enabled (poll `isAccessibilityEnabled` on resume), show step-by-step help with screenshots/illustrations
- [ ] Screen 5: notification permission (no overlay permission needed, D-07)
- [ ] Handle revocation gracefully: dashboard shows a "Tracking is off — fix" banner

**Done when:** a fresh install can reach a working tracked state, and declining the disclosure never opens Accessibility settings.

### Phase 6 — Limits, blocking and unlock modes
- [ ] Limits UI: daily total cap and optional per-app caps
- [ ] `LimitEvaluator` in Kotlin; fires when a counter reaches the cap
- [ ] `BlockController`: on limit reached **while inside the reels viewer**, show a `TYPE_ACCESSIBILITY_OVERLAY` window and navigate away (`performGlobalAction(GLOBAL_ACTION_BACK)` or `HOME`) (D-07). Do not block the rest of the host app (e.g., Instagram DMs/feed must stay usable). Verify per app where BACK lands (e.g., YouTube may go to the previous short)
- [ ] Unlock modes:
  - `none` — no unlock until midnight
  - `task` — complete a small friction task (e.g., type a phrase, short breathing exercise, simple puzzle)
  - `wait` — countdown before the unlock button activates
  - `strict` — **cannot be unlocked in-app until the timer ends**; also prevent turning off the limit in-app during strict mode. Copy must state that Android still lets the user disable the service or uninstall; warn on next open if they did (D-13)
- [ ] Persist strict-mode end time natively so it survives app/Flutter restarts and reboots
- [ ] Optional "bonus reels" after unlock (e.g., +10) tracked separately

**Done when:** hitting the cap reliably blocks reels in each app without breaking other parts of the host app; strict mode survives force-stop of ScrollBuddy and reboot.

### Phase 7 — ~~Subscriptions~~ (removed, D-22)
No premium tier. All features are free; nothing to build in this phase.

### Phase 8 — Reliability and OEM hardening
- [ ] Detect when the service has been killed (heartbeat timestamp in store) and show a recovery prompt
- [ ] Request ignore-battery-optimizations only with clear explanation
- [ ] Device-specific guidance screens for common OEMs (autostart, lock-in-recents) — content in a local JSON
- [ ] Verify after reboot that the system rebinds the accessibility service and it restarts the FGS; add a `BootReceiver` only if a device fails this (D-06)
- [ ] Set up flavors `dev` / `prod` with separate Firebase projects (moved from Phase 0, D-16)
- [ ] Remote Config for `selectors.json`: Flutter fetches on app open, validates schema, passes it to native via MethodChannel; native persists it to a file and uses it until the next update; fall back to bundled copy on any error; log which version is active
- [ ] Add a "Report a counting issue" button that attaches app versions + selector version (no content)

**Done when:** service survives a 24h soak test on at least two different OEMs.

### Phase 9 — Scroll Battles
- [ ] Firebase Auth (Google sign-in; anonymous allowed until first battle)
- [ ] Profile with unique friend code; add friend by code / share link
- [ ] Friend requests (pending/accepted) via Cloud Function to prevent enumeration; on accept the function writes friend docs on both sides (D-15)
- [ ] Sync **only the daily total** plus `trackingActive` / `lastHeartbeat` to `dailyScores` (debounced, e.g., every 5 min + on app background) (D-14)
- [ ] Leaderboard: today, lower is better; read each friend's entry by doc id; show winner crown, tie handling, and yesterday's result; friends with tracking off or heartbeat > 30 min old show "tracking off" and cannot win (D-14)
- [ ] Push notification: "Your friend passed you" (optional, opt-in) via FCM
- [ ] Firestore rules + emulator tests; rate limiting on friend requests
- [ ] Block/remove friend; account deletion deletes all server data

**Done when:** two test accounts can befriend each other and see each other's live daily totals; rules tests pass.

### Phase 10 — Polish and release
- [ ] Settings: tracked apps, notification style, reset today, export data (CSV), delete all data, privacy policy / terms links
- [ ] Accessibility (a11y) pass for our own UI: semantics, contrast, text scaling
- [ ] Crashlytics + analytics (no content, no per-reel identifiers)
- [ ] Release build: R8/ProGuard rules, app signing, versioning, adaptive icon, splash
- [ ] Play listing assets (original), data-safety form answers, Accessibility Permissions Declaration video
- [ ] Closed testing track → production

---

## 8. Reel detection details (the hardest part)

### 8.1 Selector config schema (`selectors_default.json`)

```json
{
  "schemaVersion": 1,
  "configVersion": "2026.11.04-1",
  "apps": {
    "instagram": {
      "package": "REPLACE_FROM_PHASE_2",
      "inReelsViewer": { "anyViewIdContains": ["REPLACE_FROM_PHASE_2"] },
      "reelChanged": {
        "signatureSource": "pagerIndex | structure | contentHash",
        "pagerViewId": "REPLACE_FROM_PHASE_2",
        "minDwellMs": 400
      }
    },
    "youtube": { "...": "same shape" },
    "facebook": { "...": "same shape" },
    "snapchat": { "...": "same shape" }
  }
}
```

All values marked `REPLACE_FROM_PHASE_2` must be filled from device evidence, not guessed.

### 8.2 Counting algorithm (per app detector)

1. Ignore events whose package is not tracked or whose tracking toggle is off.
2. Determine `inReelsViewer` by checking the active window's node tree for the configured container. If false → reset the "current reel" state and return.
3. Compute a **reel signature** for the currently visible reel:
   Source chosen per app by `signatureSource` (D-09):
   - `pagerIndex` (preferred): pager `fromIndex/toIndex` or `currentItem` change from the event.
   - `structure`: in-memory hash of child bounds + view IDs of the visible item. Often identical between reels in a full-screen pager, so it may undercount.
   - `contentHash`: in-memory hash of the visible reel item's text/content-description, used only to compare with the previous reel. Only the previous hash is kept. **Never persist, log or transmit node text, descriptions, usernames or the hash.**
4. If the signature differs from the previous one **and** the new reel has been visible for ≥ `minDwellMs` (debounce fast flings), increment the count by 1 and store the signature as current.
5. First reel (D-10): entering the viewer counts the first reel once, after `minDwellMs`. Leaving the viewer resets the signature. Do not increment on returning from background to the same reel, screen rotation, or comment-sheet open/close.
6. Rate-limit: ignore more than N increments per second (configurable) to guard against event storms.
7. Walk the node tree efficiently: bounded depth, reuse lookups, always `recycle()`/release nodes on older API levels, avoid work on every event (early exit when package/event type does not match).

### 8.3 Test strategy for detection
- Keep detectors **pure Kotlin** (input: simplified event + node snapshot model; output: increment or not) so they can be unit-tested on the JVM with recorded sequences from Phase 2.
- Maintain a `testdata/events/*.json` library of recorded sequences per app/version.
- Add a manual QA checklist in `docs/QA.md` (scroll 20 reels, fast fling, slow scroll, open comments, switch apps, rotate, lock screen, etc.).

---

## 9. Brain states (configurable)

Driven by `count` (or `count / limit` when a limit is set). Thresholds stored in a constant file and tweakable via Remote Config.

| State | Default range | Visual |
|-------|---------------|--------|
| Healthy | 0–49 | Bright, smiling, glowing |
| Tired | 50–99 | Slightly dull, yawning |
| Cracking | 100–199 | Visible cracks, worried face |
| Fried | 200+ | Heavily damaged, smoking/grey |

With a limit set (ratio = count / limit, D-12): Healthy < 50 %, Tired 50–79 %, Cracking 80–99 %, Fried ≥ 100 %.

Requirements: smooth tween between states, a subtle haptic on state change, and a reduced-motion setting.

---

## 10. UX notes

- Tone: playful but not shaming. Never use medical claims ("brain damage" is metaphorical — label it clearly as a visualization, not a diagnosis).
- All features are free: no paywall, no locked features, no upsell banners (D-22).
- Blocking overlay should be calm, show the count, and offer the unlock path in the user's chosen mode.
- Respect system dark mode; high-contrast color for the live count.
- Never block system UI, phone calls, or emergency features.

---

## 11. Google Play compliance (do not skip)

Create `docs/PLAY_COMPLIANCE.md` and implement:

1. **Prominent in-app disclosure** shown before requesting Accessibility access. It must state what is accessed, why, and what is **not** collected. Suggested copy (adapt, keep meaning):
   > "ScrollBuddy uses Android's Accessibility Service to detect when you scroll between reels or shorts in the apps you select (Instagram, YouTube, Facebook, Snapchat). This is used only to count reels and, if you turn it on, to block them after your limit. To tell one reel from the next, ScrollBuddy briefly looks at what is on screen in the reels viewer, but it never stores or sends any of it. It does not read your messages or passwords and does not record your screen. Counts are stored on your device. If you join Scroll Battles, only your daily total is shared with friends."
2. Explicit consent action (button) and an easy way to decline; no dark patterns.
3. **Accessibility Permissions Declaration Form** + a short demo video showing the disclosure, the permission flow, and the core feature.
4. Data Safety form must match actual behavior (local counts; optional account + daily total for Battles; analytics/crash data).
5. `accessibility_service_config.xml` scoped to the four package names only, `isAccessibilityTool="false"`; no `canPerformGestures` or unrelated capabilities unless strictly required by blocking.
6. Do not use the Accessibility API to bypass other apps' security, auto-click, or collect personal data.
7. Provide a privacy policy URL, account/data deletion flow (in-app and web link).
8. No `SYSTEM_ALERT_WINDOW`: the block screen uses `TYPE_ACCESSIBILITY_OVERLAY` + `GLOBAL_ACTION_BACK` (D-07).
9. Foreground service type `specialUse` declaration in Play Console (D-06).
10. Target audience 13+, not in Play Families (D-18).

---

## 12. Testing

| Level | What | Tools |
|-------|------|-------|
| Unit (Dart) | Brain-state mapper, streak logic, limit logic, repositories | `flutter_test`, `mocktail` |
| Unit (Kotlin) | Detectors, LimitEvaluator, midnight rollover | JUnit, recorded event JSONs |
| Widget | Dashboard, limits, onboarding gating | `flutter_test` golden/widget tests |
| Integration | Onboarding → tracking → limit → block (with fake bridge) | `integration_test` |
| Backend | Firestore rules, friend-request function | Firebase Emulator Suite |
| Manual | Real-device counting accuracy and soak tests | `docs/QA.md` checklist |

CI (GitHub Actions): `flutter analyze`, `flutter test`, Kotlin unit tests, debug APK build.

---

## 13. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Host app UI changes break detection | Remote-updatable selector JSON, version logging, monitoring of count anomalies, in-app issue report |
| Play rejects Accessibility usage | Strict adherence to Section 11, narrow package scope, clear demo video |
| Service killed by OEM | Foreground service, heartbeat, recovery UI, OEM guides |
| Double/under counting | Pure-Kotlin detectors with recorded sequences, dwell + dedupe, QA checklist |
| Users bypass blocking by disabling the service | Detect disabled service, show warning; strict mode copy sets expectations honestly (Android cannot fully prevent a user from disabling an accessibility service) |
| Backend abuse in battles | Server-side validation, rules, rate limits, friend-code entropy |
| Winning battles by turning tracking off | `trackingActive` + heartbeat in score entry; "tracking off" users cannot win (D-14) |
| An app cannot be counted accurately | Ship it as "beta", exclude from MVP accuracy gate (D-11) |

---

## 14. Definition of done (MVP)

- [ ] Accurate live counting (±1 per 20 reels) on at least 2 devices for every app not marked "beta" (D-11)
- [ ] Final `applicationId` set (D-01)
- [ ] Brain visual, dashboard and 7-day history working offline
- [ ] Limits + blocking + at least `none`, `task`, `strict` unlock modes
- [ ] Scroll Battles with two real accounts
- [ ] Play-compliant disclosure and complete compliance docs
- [ ] `flutter analyze` clean, tests green, release build signed

---

## 15. First prompt to give Claude Code

> Read `plan.md` and `docs/DECISIONS.md` fully. Start with **Phase 0** and **Phase 1** only. Use the existing Flutter project; set up git, folder structure and Phase 0 dependencies, then implement the native Kotlin bridge, MethodChannel/EventChannel, and the foreground service with a live notification driven by a debug increment button. Write `docs/DECISIONS.md` for any choices you make. Run `flutter analyze` and `flutter build apk --debug`, fix all issues, tick the completed checkboxes in `plan.md`, and stop for review before Phase 2.