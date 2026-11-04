import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:scrollbuddy/app/app.dart';
import 'package:scrollbuddy/app/dependencies.dart';

import 'fake_platform_bridge.dart';
import 'widget_test.dart' show settle;

Future<void> toLimits(WidgetTester tester) async {
  Get.reset();
  await initDependencies(bridge: FakePlatformBridge());
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
}

void main() {
  testWidgets('per-app limit dialog saves without crashing on close', (tester) async {
    await toLimits(tester);
    await tester.tap(find.text('Instagram limit'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '30');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('30'), findsOneWidget);
  });
}
