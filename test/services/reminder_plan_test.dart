import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/core/hydration.dart';
import 'package:hydrate_sir/core/profile.dart';
import 'package:hydrate_sir/services/reminder_plan.dart';

void main() {
  const profile = Profile(onboarded: true); // 12 glasses, 07:00–22:00

  List<PlannedReminder> plan({
    Profile p = profile,
    required DateTime now,
    int taken = 0,
    int days = 7,
  }) => planReminders(profile: p, now: now, takenToday: taken, days: days);

  test('before waking: a full day of glasses and follow-ups', () {
    final r = plan(now: DateTime(2026, 11, 7, 6), days: 1 + 1);
    final today = r.where((x) => x.at.day == 7).toList();
    expect(today.where((x) => x.kind == ReminderKind.glass).length, 12);
    expect(today.where((x) => x.kind == ReminderKind.followUp).length, 12);
    expect(today.first.at, DateTime(2026, 11, 7, 7));
    expect(today.first.body, contains('first glass'));
    expect(today.first.body, contains('A curiosity: '));
  });

  test('glasses already taken are not reminded', () {
    final r = plan(now: DateTime(2026, 11, 7, 6), taken: 3, days: 2);
    final todayGlasses = r.where(
      (x) => x.kind == ReminderKind.glass && x.at.day == 7,
    );
    expect(todayGlasses.map((x) => x.slot), [for (var i = 3; i < 12; i++) i]);
  });

  test('only future reminders, but a pending follow-up is kept', () {
    // 07:10: the 07:00 glass has fired, its 07:15 follow-up has not.
    final r = plan(now: DateTime(2026, 11, 7, 7, 10), days: 2);
    expect(r.every((x) => x.at.isAfter(DateTime(2026, 11, 7, 7, 10))), isTrue);
    expect(
      r.any((x) => x.kind == ReminderKind.followUp && x.slot == 0),
      isTrue,
    );
    expect(
      r.any(
        (x) => x.kind == ReminderKind.glass && x.slot == 0 && x.at.day == 7,
      ),
      isFalse,
    );
  });

  test('ask-again off means no follow-ups', () {
    final r = plan(
      p: profile.copyWith(askAgain: false),
      now: DateTime(2026, 11, 7, 6),
    );
    expect(r.where((x) => x.kind == ReminderKind.followUp), isEmpty);
  });

  test('follow-ups are skipped when glasses are too close together', () {
    final crowded = profile.copyWith(glassSizeMl: 150, dailyGoalMl: () => 6000);
    final r = plan(p: crowded, now: DateTime(2026, 11, 7, 6));
    expect(r.where((x) => x.kind == ReminderKind.followUp), isEmpty);
  });

  test('stays under the alarm limit and keeps ids unique', () {
    final crowded = profile.copyWith(glassSizeMl: 150, dailyGoalMl: () => 6000);
    for (final p in [profile, crowded]) {
      final r = plan(p: p, now: DateTime(2026, 11, 7, 6));
      expect(r.length, lessThanOrEqualTo(300));
      expect(r.map((x) => x.id).toSet().length, r.length);
    }
  });

  test('plans several days ahead so reminders continue unattended', () {
    final r = plan(now: DateTime(2026, 11, 7, 23, 30));
    final days = r.map((x) => x.at.day).toSet();
    expect(days.length, greaterThanOrEqualTo(6));
  });

  test('late glass after midnight belongs to the previous day', () {
    final owl = profile.copyWith(wakeMinutes: 10 * 60, sleepMinutes: 26 * 60);
    final r = plan(p: owl, now: DateTime(2026, 11, 8, 0, 30), days: 2);
    final first = r.firstWhere((x) => x.kind == ReminderKind.glass);
    // Last glass of 7 Nov is at 01:00 on 8 Nov.
    expect(first.at, DateTime(2026, 11, 8, 1));
    expect(first.slot, owl.glassCount - 1);
  });

  test('copy addresses the user and names the glass size', () {
    final r = plan(
      p: profile.copyWith(address: Address.madam, glassSizeMl: 300),
      now: DateTime(2026, 11, 7, 6),
      days: 2,
    );
    expect(r.first.title, 'Your 300 ml, madam.');
    expect(
      r.firstWhere((x) => x.kind == ReminderKind.followUp).title,
      'If I might, madam',
    );
  });
}
