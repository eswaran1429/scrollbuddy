import 'package:flutter_test/flutter_test.dart';
import 'package:scrollbuddy/core/format.dart';
import 'package:scrollbuddy/core/models.dart';

void main() {
  test('watchTime formats seconds', () {
    expect(watchTime(0), '0m');
    expect(watchTime(30), '<1m');
    expect(watchTime(12 * 60 + 40), '12m');
    expect(watchTime(65 * 60), '1h 05m');
  });

  test('DayCounts reads seconds from the bridge and keeps them on increment', () {
    final d = DayCounts.fromMap({
      'date': '2026-11-06',
      'counts': {'instagram': 3},
      'seconds': {'instagram': 95, 'youtube': 20, 'tiktok': 5},
    });
    expect(d.totalSeconds, 115);
    expect(d.secondsOf(TrackedApp.youtube), 20);
    expect(d.increment(TrackedApp.instagram).secondsOf(TrackedApp.instagram), 95);
  });
}
