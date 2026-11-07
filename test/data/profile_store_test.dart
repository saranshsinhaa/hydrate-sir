import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/core/profile.dart';
import 'package:hydrate_sir/data/profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a fresh install loads the defaults', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ProfileStore(await SharedPreferences.getInstance());
    final p = store.load();
    expect(p.onboarded, isFalse);
    expect(p.weightKg, 70);
  });

  test('round-trips every field', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ProfileStore(await SharedPreferences.getInstance());
    final p = Profile(
      address: Address.name,
      name: 'Ada',
      weightKg: 61,
      age: 45,
      exertion: Exertion.vigorous,
      climate: Climate.warm,
      wakeMinutes: 6 * 60 + 30,
      sleepMinutes: 25 * 60,
      dailyGoalMl: 3100,
      glassSizeMl: 300,
      chime: false,
      askAgain: false,
      respectSilent: true,
      reminderStyle: ReminderStyle.door,
      onboarded: true,
      startedAt: DateTime(2026, 11, 7, 22, 30),
    );
    await store.save(p);
    expect(store.load().toJson(), p.toJson());
  });

  test('corrupt or partial data falls back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      'profile.v1': '{"weightKg": 80, "address": "duke"}',
    });
    final store = ProfileStore(await SharedPreferences.getInstance());
    final p = store.load();
    expect(p.weightKg, 80);
    expect(p.address, Address.sir);

    SharedPreferences.setMockInitialValues({'profile.v1': 'not json'});
    final broken = ProfileStore(await SharedPreferences.getInstance());
    expect(broken.load().weightKg, 70);
  });
}
