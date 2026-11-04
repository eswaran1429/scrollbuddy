<p align="center">
  <img src="assets/images/logo.png" alt="ScrollBuddy mascot" width="160">
</p>

<h1 align="center">ScrollBuddy</h1>

<p align="center">
  Counts every reel and short you scroll on Android, live, so you can see what your scrolling actually adds up to.
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android-3DDC84">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.38-02569B">
  <img alt="Kotlin" src="https://img.shields.io/badge/Kotlin-2.2-7F52FF">
  <img alt="Status" src="https://img.shields.io/badge/status-in%20development-orange">
</p>

---

## What it does

ScrollBuddy watches the short-video viewers in Instagram, YouTube, Facebook and Snapchat and counts each new reel you swipe to. It shows the count in the app and in a small floating counter on top of the reels themselves.

- **Live reel counter** for Instagram Reels and YouTube Shorts (Facebook and Snapchat are experimental, see [Status](#status)).
- **Floating flip counter** over the reels viewer: split-flap digits that flip on every new reel, with the mascot peeking over the top. Drag it anywhere; its position is remembered.
- **Brain buddy** that changes from healthy → tired → cracking → fried as your daily count climbs. A visualization, not a diagnosis.
- **Today screen** with per-app counts, a 7-day sparkline per app, and a comparison with yesterday.
- **History** for 7 or 30 days: line chart, daily average, best day, and a streak of days under your limit.
- **Daily limit** with optional per-app limits and unlock modes (none, type-a-phrase, wait 30 s, strict).
- **Everything stays on your device.** No account, no server, no ads, no paid tier.

## Status

| Area | State |
|------|-------|
| Instagram Reels counting | Working, verified on a device |
| YouTube Shorts counting | Working, verified on a device |
| Facebook Reels, Snapchat Spotlight | Experimental: detection rules are unverified guesses |
| Floating flip counter | Working |
| Today, History, Limits, Settings screens | Working, data stored on device |
| Blocking reels at the limit | Not yet: the block screen exists as an in-app preview only |
| Persistent live-count notification | Not yet |
| Scroll Battles (compare with friends) | Not yet: needs a backend; the tab is hidden |

Verified on a Realme RMX3771 with YouTube 21.43. Other apps' UIs change between versions, so counting rules may need updating; see [`docs/SELECTORS.md`](docs/SELECTORS.md).

## How it works

Flutter can't watch other apps, so the counting runs in native Kotlin and Flutter is the UI on top.

```
┌──────────────── Flutter (Dart) ────────────────┐
│  Screens  ←  GetX controllers  ←  PlatformBridge │
└───────────────────────┬────────────────────────┘
        MethodChannel "scrollbuddy/control"
        EventChannel  "scrollbuddy/live_count"
┌───────────────────────▼────────────────────────┐
│ Android (Kotlin)                                │
│  ReelAccessibilityService ─► ReelDetector       │
│          │                       │              │
│          ▼                       ▼              │
│     CountBubble (overlay)   CounterStore (SQLite)│
└─────────────────────────────────────────────────┘
```

1. **`ReelAccessibilityService`** receives accessibility events from the four apps only (scoped in `accessibility_service_config.xml`).
2. It checks whether the **reels viewer** is on screen by looking for known view IDs among the *visible* views (`detect/Selectors.kt`).
3. **`ReelDetector`** (pure Kotlin, unit-tested) decides when you moved to a new reel:
   - **Instagram:** the reels pager sends a scroll event with the item index on every swipe.
   - **YouTube:** Shorts sends no per-swipe scroll event, so the service reads the list position (`collectionItemInfo.rowIndex`) of the Short in the middle of the screen.
4. **`CounterStore`** adds one to today's row in SQLite and notifies listeners. Flutter gets the new count over the EventChannel, and the overlay flips.

The native store is the single source of truth, so counting keeps working when the Flutter UI isn't open.

## Privacy

ScrollBuddy uses Android's Accessibility Service. This is a powerful permission, so it is used as narrowly as possible:

- It only listens to Instagram, YouTube, Facebook and Snapchat.
- It looks at view IDs and list positions to tell one reel from the next. It **never stores or sends** screen text, video content, usernames or messages.
- It does not read passwords or record the screen.
- Counts and settings are stored locally in an SQLite database on the device. Nothing leaves the phone.
- The app shows a full disclosure and asks for consent before it opens the Accessibility settings.

Debug builds log event metadata (event types, view IDs, list indexes, never text) to logcat under the tag `ScrollBuddy`, to help tune detection.

## Tech stack

- **Flutter 3.38 / Dart 3.10**: UI, with [GetX](https://pub.dev/packages/get) for state, [go_router](https://pub.dev/packages/go_router) for navigation, [fl_chart](https://pub.dev/packages/fl_chart) for charts, and the Poppins font.
- **Kotlin**: `AccessibilityService`, SQLite (`SQLiteOpenHelper`), a `TYPE_ACCESSIBILITY_OVERLAY` window for the floating counter (no "draw over other apps" permission needed).
- **Android minSdk 26** (Android 8.0).

## Project structure

```
lib/
  app/            app widget, router, theme, dependency setup
  core/           models, platform bridge, brain-state logic, shared widgets
  data/           GetX controllers (counts, settings)
  features/       onboarding, dashboard, history, limits, blocking, settings, battles
android/app/src/main/kotlin/com/example/scrollbuddy/
  bridge/         MethodChannel + EventChannel handlers
  detect/         ReelDetector, per-app Selectors
  overlay/        CountBubble (floating flip counter)
  service/        ReelAccessibilityService
  store/          CounterStore (SQLite)
docs/
  DECISIONS.md    design and architecture decisions
  SELECTORS.md    per-app detection rules and how to verify them
plan.md           full product and implementation plan
```

## Getting started

### Requirements

- Flutter 3.38 or newer (stable channel)
- Android SDK and a physical Android device (emulators don't have Instagram/YouTube set up for testing)

### Run

```bash
flutter pub get
flutter run
```

Then on the phone:

1. Go through onboarding and tap **Agree** on the disclosure.
2. Tap **Open settings** and turn on **ScrollBuddy** under *Settings → Accessibility → Installed apps*.
3. Open Instagram Reels or YouTube Shorts and swipe. The floating counter appears and the count goes up.

### Build an APK

```bash
flutter build apk --debug     # or --release
```

### Tests

```bash
flutter test                                   # Dart unit + widget tests
cd android && ./gradlew :app:testDebugUnitTest # Kotlin detector tests
```

### Tuning detection on a device

```bash
adb logcat -s ScrollBuddy:D
```

Open the reels viewer and swipe. The log shows whether the viewer was detected (`inViewer=true`), the scroll events received, and, for YouTube, the probed list position. Record what you find in [`docs/SELECTORS.md`](docs/SELECTORS.md) and update `detect/Selectors.kt`.

## Roadmap

- Block reels when the daily limit is reached (overlay + back navigation)
- Persistent notification with the live count
- Verify Facebook Reels and Snapchat Spotlight detection on devices
- Remote-updatable detection rules, so app updates don't need a new release
- OEM battery-optimisation guidance (Xiaomi, Oppo, Realme, Samsung, …)
- Scroll Battles with friends (daily totals only)

See [`plan.md`](plan.md) for the full plan and [`docs/DECISIONS.md`](docs/DECISIONS.md) for why things are built the way they are.

## Contributing

Issues and pull requests are welcome. The most useful contributions right now are detection reports from real devices: app name, app version, phone model, and whether the count matched the number of reels you swiped.

## Disclaimer

ScrollBuddy is an independent project and is not affiliated with, endorsed by, or connected to Instagram, Meta, YouTube, Google or Snap. All product names are trademarks of their respective owners.
