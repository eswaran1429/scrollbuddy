import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

/// Link to the native Android side (counts, history, settings, accessibility status).
abstract class PlatformBridge {
  /// Emits today's counts now and on every change.
  Stream<DayCounts> liveCounts();

  Future<DayCounts> getToday();

  /// Past [days] days, oldest first, excluding today. Days without reels are included.
  Future<List<DayCounts>> getHistory(int days);

  Future<bool> isAccessibilityEnabled();

  Future<void> openAccessibilitySettings();

  /// Saved settings JSON, or null before the first save.
  Future<Map<String, dynamic>?> loadSettings();

  Future<void> saveSettings(Map<String, dynamic> json);

  /// Debug builds only: pretend [by] reels were watched in [app].
  Future<void> debugIncrement(TrackedApp app, [int by = 1]);

  Future<void> resetToday();

  /// Deletes all counts and settings on this device.
  Future<void> deleteAll();

  /// True once after the service opened the app because a reel limit was reached.
  Future<bool> takeBlockRequest();

  /// Called when the service asks for the block screen while the app is running.
  void setBlockRequestHandler(void Function() handler);

  /// Raises today's limits by [reels] (unlock on the block screen).
  Future<void> grantBonus(int reels);
}

/// Real implementation over the channels registered in Bridge.kt.
class MethodChannelBridge implements PlatformBridge {
  static const _control = MethodChannel('scrollbuddy/control');
  static const _live = EventChannel('scrollbuddy/live_count');

  @override
  Stream<DayCounts> liveCounts() =>
      _live.receiveBroadcastStream().map((e) => DayCounts.fromMap(Map<String, dynamic>.from(e as Map)));

  @override
  Future<DayCounts> getToday() async =>
      DayCounts.fromMap(Map<String, dynamic>.from(await _control.invokeMethod('getToday') as Map));

  @override
  Future<List<DayCounts>> getHistory(int days) async {
    final list = await _control.invokeListMethod<Map>('getHistory', {'days': days}) ?? const [];
    return [for (final m in list) DayCounts.fromMap(Map<String, dynamic>.from(m))];
  }

  @override
  Future<bool> isAccessibilityEnabled() async => await _control.invokeMethod<bool>('isAccessibilityEnabled') ?? false;

  @override
  Future<void> openAccessibilitySettings() => _control.invokeMethod('openAccessibilitySettings');

  @override
  Future<Map<String, dynamic>?> loadSettings() async {
    final raw = await _control.invokeMethod<String>('loadSettings');
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> json) =>
      _control.invokeMethod('saveSettings', {'json': jsonEncode(json)});

  @override
  Future<void> debugIncrement(TrackedApp app, [int by = 1]) =>
      _control.invokeMethod('debugIncrement', {'app': app.name, 'by': by});

  @override
  Future<void> resetToday() => _control.invokeMethod('resetToday');

  @override
  Future<void> deleteAll() => _control.invokeMethod('deleteAll');

  @override
  Future<bool> takeBlockRequest() async => await _control.invokeMethod<bool>('takeBlockRequest') ?? false;

  @override
  void setBlockRequestHandler(void Function() handler) => _control.setMethodCallHandler((call) async {
    if (call.method == 'blockRequested') handler();
  });

  @override
  Future<void> grantBonus(int reels) => _control.invokeMethod('grantBonus', {'reels': reels});
}
