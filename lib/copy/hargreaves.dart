import '../core/format.dart';
import '../core/hydration.dart';
import '../core/profile.dart';
import 'curiosities.dart';

/// Everything Hargreaves says that depends on circumstance (docs/design.md §7).
/// Fixed screen copy lives beside it in `lib/copy/`.
class Hargreaves {
  const Hargreaves(this.address, {this.name = ''});

  factory Hargreaves.of(Profile p) => Hargreaves(p.address, name: p.name);

  final Address address;
  final String name;

  /// "sir", "madam" or the user's name.
  String get you => switch (address) {
    Address.sir => 'sir',
    Address.madam => 'madam',
    Address.name => name.trim().isEmpty ? 'sir' : name.trim(),
  };

  /// "Sir" for the start of a line.
  String get You => capitalise(you); // ignore: non_constant_identifier_names

  static String greeting(DateTime now) {
    final h = now.hour;
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String salutation(DateTime now) => '${greeting(now)}, $you.';

  String todayLine(DayStatus s) {
    if (s.allTaken) {
      return 'Every glass taken. Splendid, $you. That will be all for today.';
    }
    if (s.pastBedtime) {
      return s.goalMet
          ? 'The agreed amount is served. Do rest well, $you.'
          : 'The hour grows late, $you. Perhaps one more before bed.';
    }
    final overdue = s.overdueTimes;
    if (overdue.length >= 2) {
      return 'Forgive me, $you, but ${inWords(overdue.length)} glasses '
          'remain untouched. Shall I bring one now?';
    }
    if (overdue.length == 1) {
      return 'Your ${hm(overdue.first)} glass is poured and waiting, $you.';
    }
    if (s.beforeFirstGlass) {
      return 'Good morning, $you. Your first glass at ${hm(s.times.first)}.';
    }
    final next = s.nextTime;
    if (next != null) {
      return 'Your next glass at ${hm(next)}, $you. Do carry on.';
    }
    return 'That will be all for today, $you. Your first glass tomorrow '
        'at ${hm(s.times.first)}.';
  }

  /// "A glass of 250 ml, twelve times daily".
  static String regimen(int glassMl, int count) =>
      'A glass of $glassMl ml, ${inWords(count)} times daily';

  /// The amended note under the daily amount on The Arrangements.
  String amendNote({required bool amended, required int suggestedMl}) => amended
      ? 'Amended from my ${ml(suggestedMl)}. Very good, $you.'
      : 'Do correct me, $you, should you know better.';

  /// "Sixteen waking hours" / "Fifteen hours and 30 minutes awake".
  static String wakingHours(int awakeMinutes) {
    final h = awakeMinutes ~/ 60, m = awakeMinutes % 60;
    final s = m == 0
        ? '${inWords(h)} waking hours'
        : '${inWords(h)} hours and $m minutes awake';
    return capitalise(s);
  }

  // Reminders (docs/design.md §9).

  String reminderTitle(int glassMl) => 'Your $glassMl ml, $you.';

  String reminderBody({
    required int index,
    required int count,
    required int minutes,
  }) {
    if (index == 0) {
      return 'Good morning. Your first glass, before the household stirs.';
    }
    if (index == count - 1) {
      return 'The last glass of the evening. Then, to bed.';
    }
    return 'Forgive the intrusion. Glass ${index + 1} of $count is poured '
        'and waiting.';
  }

  /// The kind word and curiosity for a glass on a given day.
  static ({String kind, String fact}) garnish(
    DateTime day,
    int slot,
    int count,
  ) {
    final seq = Garnish.sequence(day, slot, count);
    return (kind: Garnish.kindWord(seq), fact: Garnish.curiosity(seq));
  }

  /// The full reminder: the usual line, a kind word, and a curiosity.
  String reminderLetter({
    required int index,
    required int count,
    required int minutes,
    required DateTime day,
  }) {
    final g = garnish(day, index, count);
    final lead = reminderBody(index: index, count: count, minutes: minutes);
    return '$lead ${g.kind}\n\nA curiosity: ${g.fact}';
  }

  String get followUpTitle => 'If I might, $you';

  static const rehearsalBody =
      'A rehearsal. This is how I shall announce '
      'myself when a glass is due.';

  static String followUpBody(int minutes) =>
      'Your ${hm(minutes)} glass remains untouched. I trust all is well.';

  String get halfwayPraise =>
      "Half the day's water by noon. Most commendable, $you.";

  // The Cellar Book (docs/design.md §7).

  /// [metRatio] is null when there are no complete days yet.
  String cellarRemark({
    required bool month,
    required double? metRatio,
    String? worstDay,
    bool todayRecorded = false,
  }) {
    final span = month ? 'month' : 'week';
    if (metRatio == null) {
      return todayRecorded
          ? "Today's glasses go into the book tonight, $you."
          : 'The Cellar Book awaits its first entry, $you.';
    }
    if (metRatio >= 1) {
      return 'An immaculate $span, $you. I am almost moved.';
    }
    if (metRatio >= 0.7) {
      return 'A most creditable $span, $you, with but a few lapses.';
    }
    if (metRatio >= 0.4) {
      return worstDay == null
          ? 'A respectable $span, $you.'
          : 'A respectable $span, $you. Of $worstDay, I shall say nothing.';
    }
    return 'A quieter $span, $you. Tomorrow is, as ever, another day.';
  }

  String get batteryNote =>
      'Forgive me, $you, but your telephone keeps a battery warden who may '
      'hold me at the door when I am due.';

  String get batteryExplain =>
      'To save power, Android sometimes delays my reminders by many minutes, '
      'or quite forgets them. If you will exempt me, $you, I shall arrive '
      'punctually.';

  String burnQuestion() =>
      'Burn the Cellar Book, $you? Every record shall be lost to the flames.';

  String reviseGoalQuestion({required int suggested, required int current}) =>
      'Shall I revise the daily amount to ${ml(suggested)}, or keep your '
      '${ml(current)}?';
}
