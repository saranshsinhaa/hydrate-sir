import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/profile.dart';

/// Saves the user's particulars on the device.
class ProfileStore {
  ProfileStore(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'profile.v1';

  Profile load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const Profile();
    try {
      return Profile.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return const Profile();
    }
  }

  Future<void> save(Profile p) =>
      _prefs.setString(_key, jsonEncode(p.toJson()));

  Future<void> clear() => _prefs.remove(_key);
}
