import 'models.dart';

/// Outfits the cat earns for days spent under the limit.
enum Reward {
  sunglasses('Sunglasses', 1),
  bowtie('Bow tie', 2),
  scarf('Scarf', 3),
  headphones('Headphones', 5),
  crown('Crown', 7),
  partyhat('Party hat', 10);

  const Reward(this.label, this.daysNeeded);

  final String label;

  /// Good days needed to unlock.
  final int daysNeeded;

  String get asset => 'assets/images/reward_$name.png';

  static Reward? byName(String? name) => name == null ? null : Reward.values.asNameMap()[name];
}

/// Past days that stayed at or under the limit, starting from the first day with any reels
/// (earlier empty days are before the app was used). Without a limit nothing counts.
int goodDays(List<DayCounts> past, int? limit) {
  if (limit == null) return 0;
  final start = past.indexWhere((d) => d.total > 0);
  if (start < 0) return 0;
  return past.skip(start).where((d) => d.total <= limit).length;
}

/// Rewards earned with [days] good days.
Set<Reward> earnedRewards(int days) => {
  for (final r in Reward.values)
    if (days >= r.daysNeeded) r,
};
