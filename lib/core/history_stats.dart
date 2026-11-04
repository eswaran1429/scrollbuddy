import 'models.dart';

class HistoryStats {
  const HistoryStats({required this.average, required this.bestDay, required this.streak});

  /// Average reels per day over past days (today excluded, it is in progress).
  final int average;

  /// Past day with the fewest reels; null when there is no history.
  final DayCounts? bestDay;

  /// Consecutive days at or under the limit, ending today. 0 without a limit.
  final int streak;
}

HistoryStats computeStats(List<DayCounts> pastDays, DayCounts today, {int? limit}) {
  DayCounts? best;
  for (final d in pastDays) {
    if (best == null || d.total < best.total) best = d;
  }
  final average = pastDays.isEmpty
      ? 0
      : (pastDays.fold(0, (a, d) => a + d.total) / pastDays.length).round();

  var streak = 0;
  if (limit != null) {
    for (final d in [...pastDays, today].reversed) {
      if (d.total > limit) break;
      streak++;
    }
  }
  return HistoryStats(average: average, bestDay: best, streak: streak);
}
