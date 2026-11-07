/// How Hargreaves addresses the user.
enum Address { sir, madam, name }

enum Exertion { leisurely, moderate, vigorous }

enum Climate { temperate, warm }

/// How reminders appear (DESIGN.md §9).
enum ReminderStyle {
  /// A notification in the panel.
  note,

  /// A full-screen reminder over the lock screen.
  door,
}

/// Everything the user tells Hargreaves. Times are minutes after midnight;
/// [sleepMinutes] may run past 1440 for people who retire after midnight.
class Profile {
  const Profile({
    this.address = Address.sir,
    this.name = '',
    this.weightKg = 70,
    this.age = 32,
    this.exertion = Exertion.moderate,
    this.climate = Climate.temperate,
    this.wakeMinutes = 7 * 60,
    this.sleepMinutes = 23 * 60,
    this.dailyGoalMl,
    this.glassSizeMl = 250,
    this.chime = true,
    this.askAgain = true,
    this.respectSilent = false,
    this.reminderStyle = ReminderStyle.note,
    this.onboarded = false,
    this.startedAt,
  });

  final Address address;
  final String name;
  final int weightKg;
  final int age;
  final Exertion exertion;
  final Climate climate;
  final int wakeMinutes;
  final int sleepMinutes;

  /// The user's own amount, or null to follow Hargreaves' suggestion.
  final int? dailyGoalMl;
  final int glassSizeMl;
  final bool chime;
  final bool askAgain;
  final bool respectSilent;
  final ReminderStyle reminderStyle;
  final bool onboarded;

  /// When the user accepted The Arrangements.
  final DateTime? startedAt;

  static const minWeight = 30, maxWeight = 200;
  static const minAge = 12, maxAge = 100;
  static const minGoal = 1000, maxGoal = 6000;
  static const earliestWake = 4 * 60;
  static const latestSleep = 26 * 60;
  static const minAwake = 6 * 60;
  static const glassSizes = [150, 200, 250, 300, 350, 500];

  Profile copyWith({
    Address? address,
    String? name,
    int? weightKg,
    int? age,
    Exertion? exertion,
    Climate? climate,
    int? wakeMinutes,
    int? sleepMinutes,
    int? Function()? dailyGoalMl,
    int? glassSizeMl,
    bool? chime,
    bool? askAgain,
    bool? respectSilent,
    ReminderStyle? reminderStyle,
    bool? onboarded,
    DateTime? startedAt,
  }) {
    return Profile(
      address: address ?? this.address,
      name: name ?? this.name,
      weightKg: weightKg ?? this.weightKg,
      age: age ?? this.age,
      exertion: exertion ?? this.exertion,
      climate: climate ?? this.climate,
      wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      dailyGoalMl: dailyGoalMl != null ? dailyGoalMl() : this.dailyGoalMl,
      glassSizeMl: glassSizeMl ?? this.glassSizeMl,
      chime: chime ?? this.chime,
      askAgain: askAgain ?? this.askAgain,
      respectSilent: respectSilent ?? this.respectSilent,
      reminderStyle: reminderStyle ?? this.reminderStyle,
      onboarded: onboarded ?? this.onboarded,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'address': address.name,
    'name': name,
    'weightKg': weightKg,
    'age': age,
    'exertion': exertion.name,
    'climate': climate.name,
    'wakeMinutes': wakeMinutes,
    'sleepMinutes': sleepMinutes,
    'dailyGoalMl': dailyGoalMl,
    'glassSizeMl': glassSizeMl,
    'chime': chime,
    'askAgain': askAgain,
    'respectSilent': respectSilent,
    'reminderStyle': reminderStyle.name,
    'onboarded': onboarded,
    'startedAt': startedAt?.millisecondsSinceEpoch,
  };

  /// Unknown or missing fields fall back to defaults, so older saves load.
  factory Profile.fromJson(Map<String, Object?> j) {
    const d = Profile();
    T pick<T extends Enum>(List<T> values, Object? v, T fallback) =>
        values.where((e) => e.name == v).firstOrNull ?? fallback;
    int intOr(Object? v, int fallback) => v is int ? v : fallback;
    bool boolOr(Object? v, bool fallback) => v is bool ? v : fallback;
    return Profile(
      address: pick(Address.values, j['address'], d.address),
      name: j['name'] is String ? j['name']! as String : d.name,
      weightKg: intOr(j['weightKg'], d.weightKg),
      age: intOr(j['age'], d.age),
      exertion: pick(Exertion.values, j['exertion'], d.exertion),
      climate: pick(Climate.values, j['climate'], d.climate),
      wakeMinutes: intOr(j['wakeMinutes'], d.wakeMinutes),
      sleepMinutes: intOr(j['sleepMinutes'], d.sleepMinutes),
      dailyGoalMl: j['dailyGoalMl'] is int ? j['dailyGoalMl']! as int : null,
      glassSizeMl: intOr(j['glassSizeMl'], d.glassSizeMl),
      chime: boolOr(j['chime'], d.chime),
      askAgain: boolOr(j['askAgain'], d.askAgain),
      respectSilent: boolOr(j['respectSilent'], d.respectSilent),
      reminderStyle: pick(
        ReminderStyle.values,
        j['reminderStyle'],
        d.reminderStyle,
      ),
      onboarded: boolOr(j['onboarded'], d.onboarded),
      startedAt: j['startedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(j['startedAt']! as int)
          : null,
    );
  }
}
