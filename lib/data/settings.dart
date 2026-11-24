import 'package:flutter/material.dart' show ThemeMode;
import 'package:get/get.dart';

import '../core/models.dart';
import '../core/platform_bridge.dart';

enum UnlockMode {
  none('No unlock', 'Reels stay blocked until midnight'),
  task('Task', 'Type a short phrase to unlock'),
  wait('Wait', 'Wait 30 seconds, then unlock'),
  game('Mini-game', 'Calm the cat or pop bubbles to unlock'),
  strict('Strict', 'No unlock until the strict timer ends');

  const UnlockMode(this.label, this.description);

  final String label;
  final String description;
}

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
    this.moodIcon = true,
    this.unlockedRewards = const {},
    this.outfit,
    this.dressingRoomSeen = false,
    this.themeMode = ThemeMode.system,
  });

  final int? dailyLimit;
  final UnlockMode unlockMode;
  final DateTime? strictUntil;
  final Set<TrackedApp> trackedApps;
  final bool reducedMotion;
  final bool onboardingDone;

  final bool showOverlay;

  final int overlayAfter;

  final bool moodIcon;

  /// Reward names unlocked so far. Kept even when old good days drop out of history.
  final Set<String> unlockedRewards;

  /// Reward the cat wears while healthy, or null.
  final String? outfit;

  /// The outfits button pulses until the dressing room has been opened once.
  final bool dressingRoomSeen;

  final ThemeMode themeMode;

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
    bool? moodIcon,
    Set<String>? unlockedRewards,
    String? Function()? outfit,
    bool? dressingRoomSeen,
    ThemeMode? themeMode,
  }) => AppSettings(
    dailyLimit: dailyLimit != null ? dailyLimit() : this.dailyLimit,
    unlockMode: unlockMode ?? this.unlockMode,
    strictUntil: strictUntil != null ? strictUntil() : this.strictUntil,
    trackedApps: trackedApps ?? this.trackedApps,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    showOverlay: showOverlay ?? this.showOverlay,
    overlayAfter: overlayAfter ?? this.overlayAfter,
    moodIcon: moodIcon ?? this.moodIcon,
    unlockedRewards: unlockedRewards ?? this.unlockedRewards,
    outfit: outfit != null ? outfit() : this.outfit,
    dressingRoomSeen: dressingRoomSeen ?? this.dressingRoomSeen,
    themeMode: themeMode ?? this.themeMode,
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
    'moodIcon': moodIcon,
    'unlockedRewards': unlockedRewards.toList(),
    'outfit': outfit,
    'dressingRoomSeen': dressingRoomSeen,
    'themeMode': themeMode.name,
  };

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
      moodIcon: j['moodIcon'] as bool? ?? true,
      unlockedRewards: {...?(j['unlockedRewards'] as List?)?.cast<String>()},
      outfit: j['outfit'] as String?,
      dressingRoomSeen: j['dressingRoomSeen'] as bool? ?? false,
      themeMode: ThemeMode.values.asNameMap()[j['themeMode']] ?? ThemeMode.system,
    );
  }
}

class SettingsController extends GetxController {
  SettingsController(this._bridge);

  final PlatformBridge _bridge;
  final settings = const AppSettings().obs;

  AppSettings get _s => settings.value;

  set _s(AppSettings v) {
    settings.value = v;
    _bridge.saveSettings(v.toJson());
  }

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

  void setShowOverlay(bool on) => _s = _s.copyWith(showOverlay: on);

  void setOverlayAfter(int reels) => _s = _s.copyWith(overlayAfter: reels);

  void setMoodIcon(bool on) => _s = _s.copyWith(moodIcon: on);

  /// Adds newly earned rewards; returns the ones that were new.
  Set<String> unlockRewards(Iterable<String> names) {
    final fresh = names.toSet().difference(_s.unlockedRewards);
    if (fresh.isNotEmpty) _s = _s.copyWith(unlockedRewards: {..._s.unlockedRewards, ...fresh});
    return fresh;
  }

  void wearOutfit(String? name) => _s = _s.copyWith(outfit: () => name);

  void markDressingRoomSeen() {
    if (!_s.dressingRoomSeen) _s = _s.copyWith(dressingRoomSeen: true);
  }

  void setThemeMode(ThemeMode mode) => _s = _s.copyWith(themeMode: mode);

  void reset() => _s = AppSettings(
    onboardingDone: true,
    themeMode: _s.themeMode,
    unlockedRewards: _s.unlockedRewards,
    outfit: _s.outfit,
  );
}
