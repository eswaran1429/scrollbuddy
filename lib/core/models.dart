import 'package:flutter/material.dart';

enum TrackedApp {
  instagram('Instagram', Color(0xFFE1306C), Icons.camera_alt_outlined),
  youtube('YouTube', Color(0xFFFF3D3D), Icons.play_circle_outline),
  facebook('Facebook', Color(0xFF4A7CF0), Icons.facebook),
  snapchat('Snapchat', Color(0xFFFFC800), Icons.chat_bubble_outline);

  const TrackedApp(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

class DayCounts {
  const DayCounts({required this.date, required this.perApp, this.seconds = const {}});

  final DateTime date;
  final Map<TrackedApp, int> perApp;

  final Map<TrackedApp, int> seconds;

  int get total => perApp.values.fold(0, (a, b) => a + b);

  int get totalSeconds => seconds.values.fold(0, (a, b) => a + b);

  int of(TrackedApp app) => perApp[app] ?? 0;

  int secondsOf(TrackedApp app) => seconds[app] ?? 0;

  DayCounts increment(TrackedApp app, [int by = 1]) =>
      DayCounts(date: date, perApp: {...perApp, app: of(app) + by}, seconds: seconds);

  factory DayCounts.fromMap(Map<String, dynamic> m) {
    Map<TrackedApp, int> perApp(Object? raw) {
      final map = Map<String, dynamic>.from(raw as Map? ?? const {});
      return {
        for (final app in TrackedApp.values)
          if (map[app.name] != null) app: (map[app.name] as num).toInt(),
      };
    }

    return DayCounts(
      date: DateTime.parse(m['date'] as String),
      perApp: perApp(m['counts']),
      seconds: perApp(m['seconds']),
    );
  }
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
