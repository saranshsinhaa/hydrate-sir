import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/copy/hargreaves.dart';
import 'package:hydrate_sir/core/format.dart';
import 'package:hydrate_sir/core/hydration.dart';
import 'package:hydrate_sir/core/profile.dart';

void main() {
  const sir = Hargreaves(Address.sir);

  DayStatus day({required int totalMl, required int now}) => DayStatus(
    times: const Profile().glassTimes,
    totalMl: totalMl,
    goalMl: 2800,
    glassSizeMl: 250,
    nowMinutes: now,
    sleepMinutes: 23 * 60,
  );

  group('address', () {
    test('uses the chosen form', () {
      expect(sir.you, 'sir');
      expect(const Hargreaves(Address.madam).you, 'madam');
      expect(const Hargreaves(Address.name, name: ' Ada ').you, 'Ada');
    });

    test('falls back to sir when no name was given', () {
      expect(const Hargreaves(Address.name).you, 'sir');
    });
  });

  group('greeting', () {
    test('changes at 05:00, 12:00 and 18:00', () {
      String g(int h) => Hargreaves.greeting(DateTime(2026, 1, 1, h));
      expect(g(4), 'Good evening');
      expect(g(5), 'Good morning');
      expect(g(11), 'Good morning');
      expect(g(12), 'Good afternoon');
      expect(g(17), 'Good afternoon');
      expect(g(18), 'Good evening');
    });
  });

  group('today line', () {
    test('all glasses taken', () {
      expect(
        sir.todayLine(day(totalMl: 3000, now: 900)),
        'Every glass taken. Splendid, sir. That will be all for today.',
      );
    });

    test('several overdue, in words', () {
      expect(
        sir.todayLine(day(totalMl: 0, now: 10 * 60)),
        'Forgive me, sir, but three glasses remain untouched. '
        'Shall I bring one now?',
      );
    });

    test('one overdue names its time', () {
      expect(
        sir.todayLine(day(totalMl: 1250, now: 14 * 60 + 5)),
        'Your 13:49 glass is poured and waiting, sir.',
      );
    });

    test('before the first glass', () {
      expect(
        sir.todayLine(day(totalMl: 0, now: 6 * 60)),
        'Good morning, sir. Your first glass at 07:00.',
      );
    });

    test('on schedule', () {
      expect(
        sir.todayLine(day(totalMl: 250, now: 7 * 60 + 30)),
        'Your next glass at 08:22, sir. Do carry on.',
      );
    });

    test('evening with nothing left to bring', () {
      final s = DayStatus(
        times: const Profile().glassTimes,
        totalMl: 0,
        goalMl: 2800,
        glassSizeMl: 250,
        nowMinutes: 22 * 60 + 34,
        sleepMinutes: 23 * 60,
        startMinutes: 22 * 60 + 30,
      );
      expect(
        sir.todayLine(s),
        'That will be all for today, sir. Your first glass tomorrow at 07:00.',
      );
    });

    test('never nags after bedtime', () {
      expect(
        sir.todayLine(day(totalMl: 1000, now: 23 * 60 + 10)),
        'The hour grows late, sir. Perhaps one more before bed.',
      );
    });
  });

  group('cellar remark', () {
    test('picks by ratio of days met', () {
      String r(double? x) =>
          sir.cellarRemark(month: false, metRatio: x, worstDay: 'Wednesday');
      expect(r(null), contains('awaits its first entry'));
      expect(r(1), contains('immaculate week'));
      expect(r(0.7), contains('most creditable'));
      expect(r(0.5), contains('Of Wednesday, I shall say nothing'));
      expect(r(0.1), contains('another day'));
    });
  });

  test('reminder bodies leave the address to the title', () {
    for (final i in [0, 5, 11]) {
      final body = sir.reminderBody(index: i, count: 12, minutes: 600);
      expect(body, isNot(contains('sir')), reason: body);
    }
    expect(sir.reminderTitle(250), 'Your 250 ml, sir.');
  });

  group('voice rules', () {
    final lines = [
      sir.todayLine(day(totalMl: 0, now: 10 * 60)),
      sir.todayLine(day(totalMl: 3000, now: 900)),
      sir.reminderTitle(250),
      sir.reminderBody(index: 3, count: 12, minutes: 600),
      sir.followUpTitle,
      sir.burnQuestion(),
      sir.cellarRemark(month: true, metRatio: 0.2),
    ];

    test('no exclamation marks', () {
      for (final l in lines) {
        expect(l, isNot(contains('!')), reason: l);
      }
    });

    test('never says "we"', () {
      for (final l in lines) {
        expect(l, isNot(matches(RegExp(r"\b[Ww]e('ll)?\b"))), reason: l);
      }
    });
  });

  group('format', () {
    test('thousands are separated by a space', () {
      expect(spaced(800), '800');
      expect(spaced(2800), '2 800');
      expect(spaced(1234567), '1 234 567');
      expect(ml(2800), '2 800 ml');
    });

    test('times and gaps', () {
      expect(hm(7 * 60), '07:00');
      expect(hm(25 * 60 + 5), '01:05');
      expect(gap(82), '1 h 22 m');
      expect(gap(45), '45 m');
      expect(gap(120), '2 h');
    });

    test('dates', () {
      final d = DateTime(2026, 11, 7);
      expect(eyebrowDate(d), 'SAT 7 NOV');
      expect(proseDate(d), 'Saturday, 7 November');
    });

    test('waking hours in words', () {
      expect(Hargreaves.wakingHours(16 * 60), 'Sixteen waking hours');
      expect(
        Hargreaves.wakingHours(15 * 60 + 30),
        'Fifteen hours and 30 minutes awake',
      );
    });
  });
}
