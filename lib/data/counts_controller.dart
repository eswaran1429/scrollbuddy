import 'dart:async';

import 'package:get/get.dart';

import '../core/models.dart';
import '../core/platform_bridge.dart';

/// Live counts, history and tracking status from the native side.
class CountsController extends GetxController {
  CountsController(this.bridge);

  final PlatformBridge bridge;

  /// Days of history loaded (30-day view). Today is not included.
  static const historyDays = 29;

  final today = DayCounts(date: dateOnly(DateTime.now()), perApp: const {}).obs;

  /// Past days, oldest first, excluding today.
  final past = <DayCounts>[].obs;
  final historyLoading = true.obs;
  final accessibilityEnabled = false.obs;

  StreamSubscription<DayCounts>? _sub;

  DayCounts? get yesterday => past.lastOrNull;

  /// Last [n] past days.
  List<DayCounts> lastDays(int n) => past.length <= n ? past : past.sublist(past.length - n);

  @override
  void onInit() {
    super.onInit();
    _sub = bridge.liveCounts().listen(_onLive);
    loadHistory();
    refreshAccessibility();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _onLive(DayCounts d) {
    final dayChanged = d.date != today.value.date;
    today.value = d;
    // Midnight passed while the app was open: yesterday is now history.
    if (dayChanged) loadHistory();
  }

  Future<void> loadHistory() async {
    historyLoading.value = true;
    past.assignAll(await bridge.getHistory(historyDays));
    historyLoading.value = false;
  }

  /// Called on app resume; user may have toggled the service in system settings.
  Future<void> refreshAccessibility() async => accessibilityEnabled.value = await bridge.isAccessibilityEnabled();

  /// Opens system settings. Status is re-checked now and again when the app resumes.
  Future<void> openAccessibilitySettings() async {
    await bridge.openAccessibilitySettings();
    await refreshAccessibility();
  }

  void debugIncrement(TrackedApp app, [int by = 1]) => bridge.debugIncrement(app, by);

  void resetToday() => bridge.resetToday();

  Future<void> deleteAll() async {
    await bridge.deleteAll();
    await loadHistory();
  }
}
