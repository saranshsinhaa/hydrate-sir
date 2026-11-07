import 'profile.dart';

/// Hargreaves' suggested daily amount (docs/design.md §8).
int suggestedDailyMl({
  required int weightKg,
  required int age,
  required Exertion exertion,
  required Climate climate,
}) {
  final perKg = age < 30 ? 40 : (age <= 55 ? 35 : 30);
  final extra = switch (exertion) {
    Exertion.leisurely => 0,
    Exertion.moderate => 350,
    Exertion.vigorous => 700,
  };
  final warm = climate == Climate.warm ? 500 : 0;
  return roundTo50(weightKg * perKg + extra + warm);
}

int roundTo50(num ml) => (ml / 50).round() * 50;

extension ProfileMaths on Profile {
  int get suggestedMl => suggestedDailyMl(
    weightKg: weightKg,
    age: age,
    exertion: exertion,
    climate: climate,
  );

  /// The amount in force: the user's own, else the suggestion.
  int get goalMl => dailyGoalMl ?? suggestedMl;

  bool get goalAmended => dailyGoalMl != null && dailyGoalMl != suggestedMl;

  int get glassCount => (goalMl / glassSizeMl).ceil().clamp(1, 48);

  /// Last glass is served an hour before bed.
  int get lastGlassMinutes => sleepMinutes - 60;

  /// When each glass is brought, in minutes after midnight (may exceed 1440).
  List<int> get glassTimes =>
      glassTimesBetween(wakeMinutes, lastGlassMinutes, glassCount);

  /// Minutes between glasses, rounded.
  int get intervalMinutes => glassCount > 1
      ? ((lastGlassMinutes - wakeMinutes) / (glassCount - 1)).round()
      : 0;

  /// Days begin three hours before waking, so a late glass counts for the
  /// evening it belongs to.
  int get dayBoundaryMinutes => wakeMinutes - 3 * 60;
}

List<int> glassTimesBetween(int first, int last, int count) {
  if (count <= 1) return [first];
  final step = (last - first) / (count - 1);
  return [for (var i = 0; i < count; i++) (first + i * step).round()];
}

/// The calendar date a moment belongs to, given the day boundary.
DateTime householdDay(DateTime now, int boundaryMinutes) {
  final shifted = now.subtract(Duration(minutes: boundaryMinutes));
  return DateTime(shifted.year, shifted.month, shifted.day);
}

/// Minutes since the household day's midnight. After midnight but before the
/// boundary this runs past 1440.
int householdMinutes(DateTime now, int boundaryMinutes) {
  final m = now.hour * 60 + now.minute;
  return m < boundaryMinutes ? m + 1440 : m;
}

/// Start (inclusive) and end (exclusive) of the household day containing [now].
(DateTime, DateTime) householdDayRange(DateTime now, int boundaryMinutes) {
  final day = householdDay(now, boundaryMinutes);
  final start = day.add(Duration(minutes: boundaryMinutes));
  return (start, start.add(const Duration(days: 1)));
}

enum SlotState { upcoming, taken, overdue }

/// The day at a glance: how many glasses are taken and the state of each slot.
class DayStatus {
  DayStatus({
    required this.times,
    required this.totalMl,
    required this.goalMl,
    required this.glassSizeMl,
    required this.nowMinutes,
    required this.sleepMinutes,
    this.startMinutes = 0,
  });

  /// On the day the user began, glasses due before they set up the app are
  /// not counted as missed.
  final int startMinutes;

  final List<int> times;
  final int totalMl;
  final int goalMl;
  final int glassSizeMl;
  final int nowMinutes;
  final int sleepMinutes;

  int get glassCount => times.length;

  /// Logging is by volume: 500 ml fills two 250 ml glasses.
  int get taken => (totalMl ~/ glassSizeMl).clamp(0, glassCount);

  bool get allTaken => taken >= glassCount;

  bool get goalMet => totalMl >= goalMl;

  double get fraction => goalMl == 0 ? 0 : totalMl / goalMl;

  bool _overdue(int i) => times[i] <= nowMinutes && times[i] >= startMinutes;

  List<SlotState> get slots => [
    for (var i = 0; i < glassCount; i++)
      if (i < taken)
        SlotState.taken
      else if (_overdue(i))
        SlotState.overdue
      else
        SlotState.upcoming,
  ];

  List<int> get overdueTimes => [
    for (var i = taken; i < glassCount; i++)
      if (_overdue(i)) times[i],
  ];

  /// Next glass not yet taken and not yet due, if any.
  int? get nextTime {
    for (var i = taken; i < glassCount; i++) {
      if (times[i] > nowMinutes) return times[i];
    }
    return null;
  }

  bool get beforeFirstGlass => taken == 0 && nowMinutes < times.first;

  bool get pastBedtime => nowMinutes >= sleepMinutes;
}
