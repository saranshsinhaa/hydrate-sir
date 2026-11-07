/// Figures for The Cellar Book. Only complete days count (docs/design.md §6).
class LedgerStats {
  const LedgerStats({
    required this.days,
    required this.metDays,
    required this.averageMl,
    required this.bestRun,
    required this.worstIndex,
  });

  /// Complete days considered.
  final int days;
  final int metDays;
  final int averageMl;

  /// Longest streak of consecutive days that met the goal.
  final int bestRun;

  /// Index of the lowest day, for "Of Wednesday, I shall say nothing".
  final int? worstIndex;

  double? get metRatio => days == 0 ? null : metDays / days;
}

/// [totals] are complete days, oldest first. Days before the first record
/// are dropped so a new user isn't judged on days before they began.
LedgerStats ledgerStats(List<int> totals, int goalMl) {
  final firstRecorded = totals.indexWhere((t) => t > 0);
  if (firstRecorded < 0) {
    return const LedgerStats(
      days: 0,
      metDays: 0,
      averageMl: 0,
      bestRun: 0,
      worstIndex: null,
    );
  }
  final days = totals.sublist(firstRecorded);
  var run = 0, best = 0, met = 0, worst = 0;
  for (var i = 0; i < days.length; i++) {
    if (days[i] >= goalMl) {
      met++;
      run++;
      if (run > best) best = run;
    } else {
      run = 0;
    }
    if (days[i] < days[worst]) worst = i;
  }
  final avg = days.fold<int>(0, (a, b) => a + b) ~/ days.length;
  return LedgerStats(
    days: days.length,
    metDays: met,
    averageMl: avg,
    bestRun: best,
    worstIndex: days[worst] < goalMl ? worst + firstRecorded : null,
  );
}
