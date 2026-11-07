import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/copy/curiosities.dart';
import 'package:hydrate_sir/copy/hargreaves.dart';
import 'package:hydrate_sir/core/profile.dart';

void main() {
  final all = [...kindWords, ...curiosities];

  test('there is plenty on the tray', () {
    expect(kindWords.length, greaterThanOrEqualTo(25));
    expect(curiosities.length, greaterThanOrEqualTo(40));
    expect(kindWords.toSet().length, kindWords.length, reason: 'no repeats');
    expect(curiosities.toSet().length, curiosities.length);
  });

  test('Hargreaves voice: no exclamations, no "we", no address', () {
    for (final line in all) {
      expect(line, isNot(contains('!')), reason: line);
      expect(line, isNot(matches(RegExp(r"\b[Ww]e('ll)?\b"))), reason: line);
      expect(line, isNot(matches(RegExp(r'\b(sir|madam)\b'))), reason: line);
      expect(line.trim(), line, reason: 'stray spaces: $line');
      expect(line, matches(RegExp(r'[.?]$')), reason: 'ends a sentence: $line');
    }
  });

  test('a day of glasses brings no repeated kind word or curiosity', () {
    final day = DateTime(2026, 11, 8);
    final g = [for (var i = 0; i < 12; i++) Hargreaves.garnish(day, i, 12)];
    expect(g.map((x) => x.kind).toSet().length, 12);
    expect(g.map((x) => x.fact).toSet().length, 12);
  });

  test('curiosities carry on from one day to the next', () {
    final today = Hargreaves.garnish(DateTime(2026, 11, 8), 11, 12);
    final tomorrow = Hargreaves.garnish(DateTime(2026, 11, 9), 0, 12);
    expect(
      curiosities.indexOf(tomorrow.fact),
      (curiosities.indexOf(today.fact) + 1) % curiosities.length,
    );
  });

  test('the reminder letter holds the line, a kind word and a curiosity', () {
    const h = Hargreaves(Address.madam);
    final letter = h.reminderLetter(
      index: 3,
      count: 12,
      minutes: 600,
      day: DateTime(2026, 11, 8),
    );
    expect(letter, startsWith('Forgive the intrusion. Glass 4 of 12'));
    expect(letter, contains('\n\nA curiosity: '));
    expect(kindWords.any(letter.contains), isTrue);
  });
}
