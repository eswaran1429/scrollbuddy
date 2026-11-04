import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:scrollbuddy/app/app.dart';
import 'package:scrollbuddy/app/dependencies.dart';

import 'fake_platform_bridge.dart';
import 'widget_test.dart' show settle;

void main() {
  testWidgets('opened at the limit, the block screen shows and Close goes to Today', (tester) async {
    final bridge = FakePlatformBridge()..blockRequested = true;
    await bridge.saveSettings({'onboardingDone': true, 'dailyLimit': 10, 'blockingEnabled': true});
    Get.reset();
    await initDependencies(bridge: bridge);

    await tester.pumpWidget(const ScrollBuddyApp());
    await settle(tester);
    expect(find.text('Limit reached'), findsOneWidget);
    expect(find.text('Close preview'), findsNothing);

    await tester.tap(find.text('Close'));
    await settle(tester);
    expect(find.text('reels today'), findsOneWidget);
    expect(bridge.bonus, 0);
  });

  testWidgets('a repeat block reuses the open screen and keeps the countdown', (tester) async {
    final bridge = FakePlatformBridge()..blockRequested = true;
    await bridge.saveSettings({'onboardingDone': true, 'dailyLimit': 10, 'blockingEnabled': true});
    Get.reset();
    await initDependencies(bridge: bridge);

    await tester.pumpWidget(const ScrollBuddyApp());
    await settle(tester);
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
    await settle(tester);

    bridge.requestBlock();
    await settle(tester);
    expect(find.text('Limit reached', skipOffstage: false), findsOneWidget);
    expect(find.text('30s'), findsNothing);
  });
}
