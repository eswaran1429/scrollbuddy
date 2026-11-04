import 'dart:async';

import 'package:scrollbuddy/core/models.dart';
import 'package:scrollbuddy/core/platform_bridge.dart';

/// In-memory stand-in for the native store, for widget tests.
/// Keeps settings between `initDependencies` calls when the same instance is reused.
class FakePlatformBridge implements PlatformBridge {
  final _controller = StreamController<DayCounts>.broadcast();
  DayCounts _today = DayCounts(date: dateOnly(DateTime.now()), perApp: const {});
  Map<String, dynamic>? _settings;
  bool accessibilityEnabled = false;

  /// Past days returned by [getHistory], oldest first. Defaults to empty days.
  List<DayCounts>? history;

  @override
  Stream<DayCounts> liveCounts() async* {
    yield _today;
    yield* _controller.stream;
  }

  @override
  Future<DayCounts> getToday() async => _today;

  @override
  Future<List<DayCounts>> getHistory(int days) async {
    if (history != null) return history!;
    final today = dateOnly(DateTime.now());
    return [
      for (var i = days; i >= 1; i--)
        DayCounts(
          date: today.subtract(Duration(days: i)),
          perApp: const {},
        ),
    ];
  }

  @override
  Future<bool> isAccessibilityEnabled() async => accessibilityEnabled;

  /// Simulates the user turning the service on in system settings.
  @override
  Future<void> openAccessibilitySettings() async => accessibilityEnabled = true;

  @override
  Future<Map<String, dynamic>?> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(Map<String, dynamic> json) async => _settings = json;

  @override
  Future<void> debugIncrement(TrackedApp app, [int by = 1]) async {
    _today = _today.increment(app, by);
    _controller.add(_today);
  }

  @override
  Future<void> resetToday() async {
    _today = DayCounts(date: _today.date, perApp: const {});
    _controller.add(_today);
  }

  @override
  Future<void> deleteAll() async {
    _settings = null;
    await resetToday();
  }

  /// Set to simulate the service opening the app at the limit.
  bool blockRequested = false;
  int bonus = 0;

  @override
  Future<bool> takeBlockRequest() async {
    final r = blockRequested;
    blockRequested = false;
    return r;
  }

  @override
  void setBlockRequestHandler(void Function() handler) => _blockHandler = handler;

  void Function()? _blockHandler;

  /// Simulates the service opening the running app at the limit.
  void requestBlock() {
    blockRequested = true;
    _blockHandler?.call();
  }

  @override
  Future<void> grantBonus(int reels) async => bonus += reels;
}
