import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/save_data.dart';

/// The single gateway to on-disk save data (schema: SAVE_MODEL.md).
/// Everything is one JSON document under one key.
class PersistenceService {
  PersistenceService(this._prefs);

  final SharedPreferences _prefs;

  static const _saveKey = 'save';
  static const _quarantineKey = 'save_unreadable';

  /// Loads the save, falling back to defaults if none exists. A save that
  /// fails to parse (corruption, or a future schema version) is moved to a
  /// quarantine key rather than silently overwritten, so a newer app build
  /// can still recover it.
  SaveData load() {
    final raw = _prefs.getString(_saveKey);
    if (raw == null) return const SaveData();
    try {
      return SaveData.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on Exception {
      _prefs.setString(_quarantineKey, raw);
      return const SaveData();
    }
  }

  Future<void> save(SaveData data) =>
      _prefs.setString(_saveKey, jsonEncode(data.toJson()));
}
