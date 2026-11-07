import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/core/ledger.dart';

void main() {
  test('design example week: 3 of 6 met, best run 2', () {
    // S M T W T F (Saturday is today and excluded)
    final s = ledgerStats([2750, 3000, 3000, 2000, 3000, 2750], 2800);
    expect(s.days, 6);
    expect(s.metDays, 3);
    expect(s.bestRun, 2);
    expect(s.averageMl, 2750);
    expect(s.worstIndex, 3); // Wednesday
    expect(s.metRatio, 0.5);
  });

  test('a new user is not judged on days before they began', () {
    final s = ledgerStats([0, 0, 0, 0, 2900, 3000], 2800);
    expect(s.days, 2);
    expect(s.metDays, 2);
    expect(s.metRatio, 1);
    expect(s.worstIndex, isNull);
  });

  test('an empty book has no ratio', () {
    final s = ledgerStats([0, 0, 0], 2800);
    expect(s.metRatio, isNull);
    expect(s.days, 0);
  });

  test('a missed day after starting still counts', () {
    final s = ledgerStats([3000, 0, 3000], 2800);
    expect(s.days, 3);
    expect(s.metDays, 2);
    expect(s.bestRun, 1);
    expect(s.worstIndex, 1);
  });
}
