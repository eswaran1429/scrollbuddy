import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:scrollbuddy/app/app.dart';
import 'package:scrollbuddy/app/dependencies.dart';
import 'package:scrollbuddy/core/models.dart';
import 'package:scrollbuddy/data/settings.dart';

import 'fake_platform_bridge.dart';

Future<void> settle(WidgetTester tester) async {
  // 2.5 s covers the 1.8 s splash on first pump.
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  test('AppSettings survives a JSON round trip', () {
    final s = AppSettings(
      dailyLimit: 80,
      unlockMode: UnlockMode.task,
      strictUntil: DateTime(2026, 11, 4, 22, 30),
      trackedApps: const {TrackedApp.instagram, TrackedApp.youtube},
      reducedMotion: true,
      overlayAfter: 25,
      onboardingDone: true,
    );
    final back = AppSettings.fromJson(s.toJson());
    expect(back.toJson(), s.toJson());
  });

  test('AppSettings.fromJson ignores unknown values and fills defaults', () {
    final s = AppSettings.fromJson({
      'trackedApps': ['instagram', 'tiktok'],
      'unlockMode': 'nope',
    });
    expect(s.trackedApps, {TrackedApp.instagram});
    expect(s.unlockMode, UnlockMode.wait);
    expect(s.onboardingDone, isFalse);
  });

  test('DayCounts.fromMap reads the bridge format', () {
    final d = DayCounts.fromMap({
      'date': '2026-11-04',
      'counts': {'instagram': 3, 'youtube': 2, 'unknown': 9},
    });
    expect(d.date, DateTime(2026, 11, 4));
    expect(d.total, 5);
  });

  testWidgets('settings and onboarding persist across app restarts', (tester) async {
    final bridge = FakePlatformBridge();
    Get.reset();
    await initDependencies(bridge: bridge);
    await tester.pumpWidget(const ScrollBuddyApp());
    await settle(tester);

    await tester.tap(find.text('Get started'));
    await settle(tester);
    await tester.tap(find.text('No thanks'));
    await settle(tester);
    await tester.tap(find.text('Continue without tracking'));
    await settle(tester);
    Get.find<SettingsController>().setDailyLimit(75);

    // "Restart": new controllers and app, same native store.
    await tester.pumpWidget(const SizedBox());
    Get.reset();
    await initDependencies(bridge: bridge);
    await tester.pumpWidget(const ScrollBuddyApp());
    await settle(tester);

    expect(find.text('Get started'), findsNothing);
    expect(find.text('reels today'), findsOneWidget);
    expect(Get.find<SettingsController>().settings.value.dailyLimit, 75);
  });
}
