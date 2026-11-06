import 'package:get/get.dart';

import '../core/models.dart';
import '../core/platform_bridge.dart';

enum UnlockMode {
  none('No unlock', 'Reels stay blocked until midnight'),
  task('Task', 'Type a short phrase to unlock'),
  wait('Wait', 'Wait 30 seconds, then unlock'),
  strict('Strict', 'No unlock until the strict timer ends');

  const UnlockMode(this.label, this.description);

  final String label;
  final String description;
}

/// User settings. One reel limit: the daily total across all tracked apps.
/// When it is set, reels are blocked once it is reached.
/// Saved as JSON in the native store (D-05) so the accessibility
/// service can read them (it uses `trackedApps`).
class AppSettings {
  const AppSettings({
    this.dailyLimit,
    this.unlockMode = UnlockMode.wait,
    this.strictUntil,
    this.trackedApps = const {...TrackedApp.values},
    this.reducedMotion = false,
    this.onboardingDone = false,
    this.showOverlay = true,
    this.overlayAfter = 0,
  });

  final int? dailyLimit;
  final UnlockMode unlockMode;
  final DateTime? strictUntil;
  final Set<TrackedApp> trackedApps;
  final bool reducedMotion;
  final bool onboardingDone;

  /// Floating counter over the reels viewer (read by the native service).
  final bool showOverlay;

  /// The floating counter appears once today's total reaches this. 0 = from the first reel.
  final int overlayAfter;

  bool strictActive(DateTime now) => strictUntil != null && now.isBefore(strictUntil!);

  AppSettings copyWith({
    int? Function()? dailyLimit,
    UnlockMode? unlockMode,
    DateTime? Function()? strictUntil,
    Set<TrackedApp>? trackedApps,
    bool? reducedMotion,
    bool? onboardingDone,
    bool? showOverlay,
    int? overlayAfter,
  }) => AppSettings(
    dailyLimit: dailyLimit != null ? dailyLimit() : this.dailyLimit,
    unlockMode: unlockMode ?? this.unlockMode,
    strictUntil: strictUntil != null ? strictUntil() : this.strictUntil,
    trackedApps: trackedApps ?? this.trackedApps,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    showOverlay: showOverlay ?? this.showOverlay,
    overlayAfter: overlayAfter ?? this.overlayAfter,
  );

  Map<String, dynamic> toJson() => {
    'dailyLimit': dailyLimit,
    'unlockMode': unlockMode.name,
    'strictUntil': strictUntil?.millisecondsSinceEpoch,
    'trackedApps': [for (final a in trackedApps) a.name],
    'reducedMotion': reducedMotion,
    'onboardingDone': onboardingDone,
    'showOverlay': showOverlay,
    'overlayAfter': overlayAfter,
  };

  /// Missing or unknown values fall back to defaults.
  factory AppSettings.fromJson(Map<String, dynamic> j) {
    TrackedApp? app(String name) => TrackedApp.values.asNameMap()[name];
    final tracked = j['trackedApps'] as List?;
    final strict = j['strictUntil'] as int?;
    return AppSettings(
      dailyLimit: j['dailyLimit'] as int?,
      unlockMode: UnlockMode.values.asNameMap()[j['unlockMode']] ?? UnlockMode.wait,
      strictUntil: strict == null ? null : DateTime.fromMillisecondsSinceEpoch(strict),
      trackedApps: tracked == null ? const {...TrackedApp.values} : {for (final n in tracked) ?app(n as String)},
      reducedMotion: j['reducedMotion'] as bool? ?? false,
      onboardingDone: j['onboardingDone'] as bool? ?? false,
      showOverlay: j['showOverlay'] as bool? ?? true,
      overlayAfter: j['overlayAfter'] as int? ?? 0,
    );
  }
}

class SettingsController extends GetxController {
  SettingsController(this._bridge);

  final PlatformBridge _bridge;
  final settings = const AppSettings().obs;

  AppSettings get _s => settings.value;

  /// Every change is saved to the native store.
  set _s(AppSettings v) {
    settings.value = v;
    _bridge.saveSettings(v.toJson());
  }

  /// Loads saved settings. Call once before the app starts.
  Future<void> load() async {
    final json = await _bridge.loadSettings();
    if (json != null) settings.value = AppSettings.fromJson(json);
  }

  void markOnboardingDone() => _s = _s.copyWith(onboardingDone: true);

  void setDailyLimit(int? limit) => _s = _s.copyWith(dailyLimit: () => limit);

  void setUnlockMode(UnlockMode mode) => _s = _s.copyWith(unlockMode: mode);

  void startStrict(DateTime until) => _s = _s.copyWith(strictUntil: () => until);

  void setTracked(TrackedApp app, bool on) =>
      _s = _s.copyWith(trackedApps: on ? {..._s.trackedApps, app} : ({..._s.trackedApps}..remove(app)));

  void setReducedMotion(bool on) => _s = _s.copyWith(reducedMotion: on);

  void setShowOverlay(bool on) => _s = _s.copyWith(showOverlay: on);

  void setOverlayAfter(int reels) => _s = _s.copyWith(overlayAfter: reels);

  /// Back to defaults after "Delete all data". Onboarding stays done.
  void reset() => _s = const AppSettings(onboardingDone: true);
}
