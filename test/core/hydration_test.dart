import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/core/hydration.dart';
import 'package:hydrate_sir/core/profile.dart';

void main() {
  group('suggestedDailyMl', () {
    int s(int w, int a, Exertion e, Climate c) =>
        suggestedDailyMl(weightKg: w, age: a, exertion: e, climate: c);

    test('design example: 70 kg, 32, moderate, temperate is 2 800', () {
      expect(s(70, 32, Exertion.moderate, Climate.temperate), 2800);
    });

    test('per-kg rate depends on age band', () {
      expect(s(70, 29, Exertion.leisurely, Climate.temperate), 2800);
      expect(s(70, 30, Exertion.leisurely, Climate.temperate), 2450);
      expect(s(70, 55, Exertion.leisurely, Climate.temperate), 2450);
      expect(s(70, 56, Exertion.leisurely, Climate.temperate), 2100);
    });

    test('exertion and climate add on top', () {
      expect(s(70, 32, Exertion.vigorous, Climate.warm), 2450 + 700 + 500);
    });

    test('rounds to the nearest 50 ml', () {
      expect(s(61, 40, Exertion.leisurely, Climate.temperate), 2150); // 2135
      expect(s(63, 40, Exertion.leisurely, Climate.temperate), 2200); // 2205
    });
  });

  group('Profile maths', () {
    const p = Profile();

    test('goal follows the suggestion until amended', () {
      expect(p.goalMl, 2800);
      expect(p.goalAmended, isFalse);
      final amended = p.copyWith(dailyGoalMl: () => 3000);
      expect(amended.goalMl, 3000);
      expect(amended.goalAmended, isTrue);
      expect(amended.copyWith(dailyGoalMl: () => null).goalMl, 2800);
    });

    test('design example: twelve glasses 07:00 to 22:00, every 82 minutes', () {
      expect(p.glassCount, 12);
      expect(p.glassTimes.first, 7 * 60);
      expect(p.glassTimes.last, 22 * 60);
      expect(p.intervalMinutes, 82);
    });

    test('glass count rounds up', () {
      expect(p.copyWith(glassSizeMl: 300).glassCount, 10); // 9.33
      expect(p.copyWith(glassSizeMl: 500).glassCount, 6); // 5.6
    });

    test('a single glass is served at waking', () {
      final one = p.copyWith(dailyGoalMl: () => 1000, glassSizeMl: 500);
      expect(glassTimesBetween(420, 1320, 1), [420]);
      expect(one.glassCount, 2);
    });

    test('times may run past midnight for late sleepers', () {
      final owl = p.copyWith(wakeMinutes: 10 * 60, sleepMinutes: 25 * 60);
      expect(owl.glassTimes.last, 24 * 60);
    });
  });

  group('household day', () {
    test('a glass at 00:30 counts for the evening before', () {
      final day = householdDay(DateTime(2026, 11, 8, 0, 30), 4 * 60);
      expect(day, DateTime(2026, 11, 7));
      expect(householdMinutes(DateTime(2026, 11, 8, 0, 30), 240), 1470);
    });

    test('after the boundary it is the new day', () {
      expect(
        householdDay(DateTime(2026, 11, 8, 4), 240),
        DateTime(2026, 11, 8),
      );
      expect(householdMinutes(DateTime(2026, 11, 8, 9, 15), 240), 555);
    });

    test('range spans 24 hours from the boundary', () {
      final (start, end) = householdDayRange(DateTime(2026, 11, 8, 1), 240);
      expect(start, DateTime(2026, 11, 7, 4));
      expect(end, DateTime(2026, 11, 8, 4));
    });
  });

  group('DayStatus', () {
    DayStatus status({required int totalMl, required int now}) => DayStatus(
      times: const Profile().glassTimes,
      totalMl: totalMl,
      goalMl: 2800,
      glassSizeMl: 250,
      nowMinutes: now,
      sleepMinutes: 23 * 60,
    );

    test('design example at 14:05 with five glasses', () {
      final s = status(totalMl: 1250, now: 14 * 60 + 5);
      expect(s.taken, 5);
      expect(s.slots.take(5), everyElement(SlotState.taken));
      expect(s.overdueTimes.length, 1); // 13:49
      expect(s.slots.last, SlotState.upcoming);
    });

    test('a large glass fills more than one slot', () {
      expect(status(totalMl: 500, now: 0).taken, 2);
      expect(status(totalMl: 499, now: 0).taken, 1);
    });

    test('taken never exceeds the number of glasses', () {
      expect(status(totalMl: 9000, now: 0).taken, 12);
      expect(status(totalMl: 9000, now: 0).allTaken, isTrue);
    });

    test('next time skips glasses already due', () {
      final s = status(totalMl: 0, now: 8 * 60);
      expect(s.nextTime, 7 * 60 + 82);
      expect(s.beforeFirstGlass, isFalse);
      expect(status(totalMl: 0, now: 6 * 60).beforeFirstGlass, isTrue);
    });
  });

  group('first day', () {
    test('glasses due before setting up are not missed', () {
      final s = DayStatus(
        times: const Profile().glassTimes,
        totalMl: 0,
        goalMl: 2800,
        glassSizeMl: 250,
        nowMinutes: 22 * 60 + 34,
        sleepMinutes: 23 * 60,
        startMinutes: 22 * 60 + 30,
      );
      expect(s.overdueTimes, isEmpty);
      expect(s.slots, everyElement(SlotState.upcoming));
    });

    test('glasses due after setting up still count', () {
      final s = DayStatus(
        times: const Profile().glassTimes,
        totalMl: 0,
        goalMl: 2800,
        glassSizeMl: 250,
        nowMinutes: 12 * 60,
        sleepMinutes: 23 * 60,
        startMinutes: 9 * 60,
      );
      expect(s.overdueTimes, [9 * 60 + 44, 11 * 60 + 5]);
    });
  });
}
