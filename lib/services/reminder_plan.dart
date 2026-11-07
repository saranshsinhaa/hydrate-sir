import '../copy/hargreaves.dart';
import '../core/hydration.dart';
import '../core/profile.dart';

enum ReminderKind { glass, followUp, snooze }

/// One notification to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.kind,
    required this.slot,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime at;
  final ReminderKind kind;

  /// Index of the glass in its day.
  final int slot;
  final String title;
  final String body;

  @override
  String toString() => '$kind#$id@$at';
}

/// Notification ids: glasses 1000+, follow-ups 5000+, snooze 9000.
abstract final class ReminderIds {
  static int glass(int day, int slot) => 1000 + day * 100 + slot;
  static int followUp(int day, int slot) => 5000 + day * 100 + slot;
  static const snooze = 9000;

  static bool isFollowUp(int id) => id >= 5000 && id < 9000;
}

/// Android allows about 500 alarms per app; stay well clear.
const _maxAlarms = 300;

/// Minutes after a reminder before Hargreaves asks again.
const followUpDelay = 15;

/// Plans every reminder from [now] for the next few days. Glasses already
/// taken today are skipped, so nobody is reminded of what they have drunk.
List<PlannedReminder> planReminders({
  required Profile profile,
  required DateTime now,
  required int takenToday,
  int days = 7,
}) {
  final h = Hargreaves.of(profile);
  final times = profile.glassTimes;
  final count = times.length;
  final askAgain =
      profile.askAgain && profile.intervalMinutes > followUpDelay * 2;
  final perDay = count * (askAgain ? 2 : 1);
  final horizon = days.clamp(2, (_maxAlarms ~/ perDay).clamp(2, days));
  final today = householdDay(now, profile.dayBoundaryMinutes);

  final out = <PlannedReminder>[];
  for (var d = 0; d < horizon; d++) {
    final day = DateTime(today.year, today.month, today.day + d);
    for (var i = 0; i < count; i++) {
      if (d == 0 && i < takenToday) continue;
      final at = DateTime(day.year, day.month, day.day, 0, times[i]);
      if (at.isAfter(now)) {
        out.add(
          PlannedReminder(
            id: ReminderIds.glass(d, i),
            at: at,
            kind: ReminderKind.glass,
            slot: i,
            title: h.reminderTitle(profile.glassSizeMl),
            body: h.reminderBody(index: i, count: count, minutes: times[i]),
          ),
        );
      }
      final again = at.add(const Duration(minutes: followUpDelay));
      if (askAgain && again.isAfter(now)) {
        out.add(
          PlannedReminder(
            id: ReminderIds.followUp(d, i),
            at: again,
            kind: ReminderKind.followUp,
            slot: i,
            title: h.followUpTitle,
            body: Hargreaves.followUpBody(times[i]),
          ),
        );
      }
    }
  }
  return out;
}
