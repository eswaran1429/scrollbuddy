import 'package:flutter/material.dart';

class AppIcons {
  AppIcons._();

  /// Icon for a change category or scan step.
  static IconData category(String name) => switch (name) {
    'dns' => Icons.dns_outlined,
    'subdomains' => Icons.account_tree_outlined,
    'ports' => Icons.settings_ethernet_rounded,
    'ssl' => Icons.lock_outline_rounded,
    'technologies' => Icons.memory_rounded,
    'headers' => Icons.http_rounded,
    'exposed_resources' => Icons.folder_open_rounded,
    _ => Icons.change_circle_outlined,
  };
}
