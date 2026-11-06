import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:scrollbuddy/app/app.dart';
import 'package:scrollbuddy/app/dependencies.dart';

import 'fake_platform_bridge.dart';
import 'widget_test.dart' show settle;

void main() {
  testWidgets('floating counter "show after" choice is saved for the service', (tester) async {
    final bridge = FakePlatformBridge();
    await bridge.saveSettings({'onboardingDone': true});
    Get.reset();
    await initDependencies(bridge: bridge);

    await tester.pumpWidget(const ScrollBuddyApp());
    await settle(tester);
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);

    await tester.scrollUntilVisible(find.text('Show from the first reel'), 100);
    expect(find.text('Show from the first reel'), findsOneWidget);
    await settle(tester);
    await tester.ensureVisible(find.text('25')); // scrolls it to the top, clear of the floating nav
    await settle(tester);
    await tester.tap(find.text('25'));
    await settle(tester);

    expect(find.text('Show after 25 reels today'), findsOneWidget);
    expect((await bridge.loadSettings())!['overlayAfter'], 25);
    // Custom number.    await tester.ensureVisible(find.text('Custom'));    await settle(tester);    await tester.tap(find.text('Custom'));    await settle(tester);    await tester.enterText(find.byType(TextField), '7');    await tester.tap(find.text('Save'));    await settle(tester);    expect(find.text('Show after 7 reels today'), findsOneWidget);    expect(find.text('7'), findsOneWidget); // the Custom chip now shows the number    expect((await bridge.loadSettings())!['overlayAfter'], 7);
  });
}
