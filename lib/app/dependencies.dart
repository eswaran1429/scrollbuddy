import 'package:get/get.dart';

import '../core/platform_bridge.dart';
import '../data/counts_controller.dart';
import '../data/settings.dart';
import '../features/battles/battles_data.dart';

Future<void> initDependencies({PlatformBridge? bridge}) async {
  final b = bridge ?? MethodChannelBridge();
  await Get.put(SettingsController(b)).load();
  Get.put(CountsController(b));
  Get.put(FriendsController());
}
