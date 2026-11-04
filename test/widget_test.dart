import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:scrollbuddy/app/app.dart';
import 'package:scrollbuddy/app/dependencies.dart';
import 'package:scrollbuddy/core/custom_widgets/app_bottom_nav/app_bottom_nav.dart';
import 'package:scrollbuddy/core/custom_widgets/app_tile/app_tile.dart';

import 'fake_platform_bridge.dart';

Future<void> settle(WidgetTester tester) async {
  // pumpAndSettle would hang on the brain's repeating breath animation.
  // 2.5 s covers the 1.8 s splash on first pump.
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() async {
    Get.reset();
    await initDependencies(bridge: FakePlatformBridge());
  });

  testWidgets('declining disclosure reaches dashboard with tracking off', (tester) async {
    await tester.pumpWidget(const ScrollBuddyApp());
    await settle(tester);

    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await settle(tester);

    expect(find.text('Agree'), findsOneWidget);
    await tester.tap(find.text('No thanks'));
    await settle(tester);

    await tester.tap(find.text('Continue without tracking'));
    await settle(tester);

    expect(find.text('Tracking is off'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('reels today'), 200);
    expect(find.text('reels today'), findsOneWidget);
  });

  testWidgets('agreeing and enabling accessibility turns tracking on', (tester) async {
    await tester.pumpWidget(const ScrollBuddyApp());
    await settle(tester);

    await tester.tap(find.text('Get started'));
    await settle(tester);
    await tester.tap(find.text('Agree'));
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    await tester.tap(find.text('Open settings'));
    await settle(tester);
    expect(find.text('Tracking is on'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    await tester.tap(find.text('Not now'));
    await settle(tester);

    expect(find.text('reels today'), findsOneWidget);
    expect(find.text('Tracking is off'), findsNothing);
  });

  testWidgets('bottom nav opens each tab', (tester) async {
    await tester.pumpWidget(const ScrollBuddyApp());
    await settle(tester);
    await tester.tap(find.text('Get started'));
    await settle(tester);
    await tester.tap(find.text('No thanks'));
    await settle(tester);
    await tester.tap(find.text('Continue without tracking'));
    await settle(tester);

    for (final (tab, expected) in [('History', '7 days'), ('Settings', 'Tracking is off')]) {
      await tester.tap(find.descendant(of: find.byType(AppBottomNav), matching: find.text(tab)));
      await settle(tester);
      expect(find.text(expected), findsOneWidget, reason: tab);
    }
  });

  testWidgets('limits: blocking, strict mode and block preview are all free', (tester) async {
    await tester.pumpWidget(const ScrollBuddyApp());
    await settle(tester);
    await tester.tap(find.text('Get started'));
    await settle(tester);
    await tester.tap(find.text('No thanks'));
    await settle(tester);
    await tester.tap(find.text('Continue without tracking'));
    await settle(tester);

    await tester.tap(find.byTooltip('Limits'));
    await settle(tester);
    expect(find.text('Daily reel limit'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    expect(find.text('100'), findsOneWidget);

    // Blocking switch works without any purchase.
    final blocking = find.descendant(
      of: find.widgetWithText(AppTile, 'Block reels at limit'),
      matching: find.byType(Switch),
    );
    await tester.scrollUntilVisible(blocking, 200);
    await tester.tap(blocking);
    await settle(tester);
    expect(tester.widget<Switch>(blocking).value, isTrue);

    await tester.scrollUntilVisible(find.text('Strict'), 200);
    await tester.ensureVisible(find.text('Strict'));
    await settle(tester);
    await tester.tap(find.text('Strict'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Start strict mode'), 200);
    expect(find.text('Start strict mode'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Preview block screen'), 200);
    await tester.ensureVisible(find.text('Preview block screen'));
    await settle(tester);
    await tester.tap(find.text('Preview block screen'));
    await settle(tester);
    expect(find.text('Limit reached'), findsOneWidget);
    await tester.tap(find.text('Close preview'));
    await settle(tester);
  });

  testWidgets('history 30-day tab opens without paywall', (tester) async {
    await tester.pumpWidget(const ScrollBuddyApp());
    await settle(tester);
    await tester.tap(find.text('Get started'));
    await settle(tester);
    await tester.tap(find.text('No thanks'));
    await settle(tester);
    await tester.tap(find.text('Continue without tracking'));
    await settle(tester);

    await tester.tap(find.descendant(of: find.byType(AppBottomNav), matching: find.text('History')));
    await settle(tester);
    await tester.tap(find.text('30 days'));
    await settle(tester);
    expect(find.text('History'), findsWidgets);
    expect(find.text('REELS PER DAY'), findsOneWidget);
  });

  testWidgets('dashboard fits on a narrow 360dp phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ScrollBuddyApp());
    await settle(tester);
    await tester.tap(find.text('Get started'));
    await settle(tester);
    await tester.tap(find.text('No thanks'));
    await settle(tester);
    await tester.tap(find.text('Continue without tracking'));
    await settle(tester);

    await tester.scrollUntilVisible(find.textContaining('not a diagnosis'), 200);
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash animates, then continues to onboarding', (tester) async {
    await tester.pumpWidget(const ScrollBuddyApp());
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Every reel, counted.'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
    await settle(tester);
    expect(find.text('Every reel, counted.'), findsNothing);
    expect(find.text('Get started'), findsOneWidget);
  });
}
