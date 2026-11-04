import 'package:flutter_test/flutter_test.dart';
import 'package:scrollbuddy/core/history_stats.dart';
import 'package:scrollbuddy/core/models.dart';

DayCounts day(int offset, int total) =>
    DayCounts(date: DateTime(2026, 11, 1 + offset), perApp: {TrackedApp.instagram: total});

void main() {
  final past = [day(0, 120), day(1, 40), day(2, 80), day(3, 60)];

  test('average and best day use past days only', () {
    final s = computeStats(past, day(4, 5));
    expect(s.average, 75);
    expect(s.bestDay!.total, 40);
  });

  test('streak counts days at or under limit ending today', () {
    expect(computeStats(past, day(4, 50), limit: 80).streak, 4);
    expect(computeStats(past, day(4, 90), limit: 80).streak, 0);
  });

  test('no limit means no streak', () {
    expect(computeStats(past, day(4, 0)).streak, 0);
  });

  test('empty history', () {
    final s = computeStats(const [], day(0, 3));
    expect(s.average, 0);
    expect(s.bestDay, isNull);
  });
}
