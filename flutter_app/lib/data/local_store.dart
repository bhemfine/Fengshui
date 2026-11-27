import 'dart:convert';

import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On-device only key/value store (Android SharedPreferences in the app's
/// private folder; Android backup is off in the manifest). Holds checklist
/// answers, the last property type, the current home (facing, address, floor)
/// notification preferences, the household birth profiles, saved house
/// results and drafts, and the first-run complete flag.
///
/// This is not an encrypted database. "Delete my data" clears these keys.
/// TODO(phase-2): move to the encrypted drift database once it lands.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  static const _answersKey = 'home_checklist.answers.v1';
  static const _typeKey = 'home_checklist.type.v1';

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null; // e.g. widget tests without the plugin: run in memory.
    }
  }

  Future<Map<String, Answer>> loadAnswers(PropertyType t) async {
    final p = await _prefs();
    final raw = p?.getString('$_answersKey.${t.name}');
    if (raw == null) return {};
    try {
      final m = jsonDecode(raw) as Map<String, Object?>;
      return {
        for (final e in m.entries)
          if (Answer.values.any((a) => a.name == e.value))
            e.key: Answer.values.firstWhere((a) => a.name == e.value),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> saveAnswers(PropertyType t, Map<String, Answer> answers) async {
    final p = await _prefs();
    await p?.setString(
      '$_answersKey.${t.name}',
      jsonEncode({for (final e in answers.entries) e.key: e.value.name}),
    );
  }

  Future<void> clearAnswers(PropertyType t) async {
    final p = await _prefs();
    await p?.remove('$_answersKey.${t.name}');
  }

  Future<PropertyType?> loadPropertyType() async {
    final p = await _prefs();
    final v = p?.getString(_typeKey);
    for (final t in PropertyType.values) {
      if (t.name == v) return t;
    }
    return null;
  }

  Future<void> savePropertyType(PropertyType t) async {
    final p = await _prefs();
    await p?.setString(_typeKey, t.name);
  }

  Future<String?> loadString(String key) async {
    final p = await _prefs();
    return p?.getString(key);
  }

  Future<void> saveString(String key, String value) async {
    final p = await _prefs();
    await p?.setString(key, value);
  }

  Future<void> remove(String key) async {
    final p = await _prefs();
    await p?.remove(key);
  }

  Future<int?> loadInt(String key) async {
    final p = await _prefs();
    return p?.getInt(key);
  }

  Future<void> saveInt(String key, int value) async {
    final p = await _prefs();
    await p?.setInt(key, value);
  }

  Future<bool?> loadBool(String key) async {
    final p = await _prefs();
    return p?.getBool(key);
  }

  Future<void> saveBool(String key, bool value) async {
    final p = await _prefs();
    await p?.setBool(key, value);
  }

  /// Wipes every SharedPreferences key this app wrote.
  Future<void> clearAll() async {
    final p = await _prefs();
    await p?.clear();
  }
}
