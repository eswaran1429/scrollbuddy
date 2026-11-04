import 'package:flutter/material.dart';

/// The four apps ScrollBuddy can track.
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

/// Reel counts for one local calendar day.
class DayCounts {
  const DayCounts({required this.date, required this.perApp});

  /// Local date at midnight.
  final DateTime date;
  final Map<TrackedApp, int> perApp;

  int get total => perApp.values.fold(0, (a, b) => a + b);

  int of(TrackedApp app) => perApp[app] ?? 0;

  DayCounts increment(TrackedApp app, [int by = 1]) => DayCounts(date: date, perApp: {...perApp, app: of(app) + by});

  /// From the bridge format `{"date": "YYYY-MM-DD", "counts": {"instagram": 3, ...}}`.
  /// Unknown app keys are ignored.
  factory DayCounts.fromMap(Map<String, dynamic> m) {
    final counts = Map<String, dynamic>.from(m['counts'] as Map? ?? const {});
    return DayCounts(
      date: DateTime.parse(m['date'] as String),
      perApp: {
        for (final app in TrackedApp.values)
          if (counts[app.name] != null) app: (counts[app.name] as num).toInt(),
      },
    );
  }
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
