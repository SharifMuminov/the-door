import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// Thin, crash-proof wrapper around SharedPreferences.
///
/// If preferences cannot be opened, it falls back to "nothing saved"
/// and every write becomes a no-op.
class GameStorage {
  GameStorage._(this._prefs);

  /// A storage that never persists anything (tests, or a broken platform).
  factory GameStorage.memory() => GameStorage._(null);

  static Future<GameStorage> open() async {
    try {
      return GameStorage._(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('GameStorage: preferences unavailable ($e)');
      return GameStorage._(null);
    }
  }

  final SharedPreferences? _prefs;

  // ---------------------------------------------------------------- progress

  /// The last room the player reached, or null if there is no save.
  int? get savedLevel =>
      _read(() => _prefs?.getInt(GameStorageKeys.currentLevel));

  bool get hasSave => savedLevel != null;

  Set<int> get completedLevels {
    final raw =
        _read(() => _prefs?.getStringList(GameStorageKeys.completedLevels)) ??
        const <String>[];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Set<String> get endingsSeen =>
      (_read(() => _prefs?.getStringList(GameStorageKeys.endingsSeen)) ??
              const <String>[])
          .toSet();

  Future<void> saveCurrentLevel(int level) =>
      _write((p) => p.setInt(GameStorageKeys.currentLevel, level));

  Future<void> markLevelCompleted(int level) {
    final levels = {...completedLevels, level}.map((l) => '$l').toList()
      ..sort();
    return _write(
      (p) => p.setStringList(GameStorageKeys.completedLevels, levels),
    );
  }

  Future<void> markEndingSeen(String ending) {
    final endings = {...endingsSeen, ending}.toList()..sort();
    return _write((p) => p.setStringList(GameStorageKeys.endingsSeen, endings));
  }

  /// The saved in-room snapshot (JSON), or null.
  String? get roomProgress =>
      _read(() => _prefs?.getString(GameStorageKeys.roomProgress));

  Future<void> saveRoomProgress(String json) =>
      _write((p) => p.setString(GameStorageKeys.roomProgress, json));

  Future<void> clearRoomProgress() =>
      _write((p) => p.remove(GameStorageKeys.roomProgress));

  /// Clears progress but keeps settings and discovered endings.
  Future<void> resetProgress() async {
    await _write((p) => p.remove(GameStorageKeys.currentLevel));
    await _write((p) => p.remove(GameStorageKeys.completedLevels));
    await clearRoomProgress();
  }

  // ---------------------------------------------------------------- settings

  bool get soundEnabled =>
      _read(() => _prefs?.getBool(GameStorageKeys.soundEnabled)) ?? true;

  bool get vibrationEnabled =>
      _read(() => _prefs?.getBool(GameStorageKeys.vibrationEnabled)) ?? true;

  Future<void> setSoundEnabled(bool value) =>
      _write((p) => p.setBool(GameStorageKeys.soundEnabled, value));

  Future<void> setVibrationEnabled(bool value) =>
      _write((p) => p.setBool(GameStorageKeys.vibrationEnabled, value));

  /// Language code ('en', 'uz'), or null before the player has chosen.
  String? get languageCode =>
      _read(() => _prefs?.getString(GameStorageKeys.language));

  Future<void> setLanguageCode(String code) =>
      _write((p) => p.setString(GameStorageKeys.language, code));

  // ---------------------------------------------------------------- helpers

  /// A value stored with the wrong type must not crash the game.
  T? _read<T>(T? Function() read) {
    try {
      return read();
    } catch (e) {
      debugPrint('GameStorage: bad value ($e)');
      return null;
    }
  }

  Future<void> _write(
    Future<bool> Function(SharedPreferences prefs) write,
  ) async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await write(prefs);
    } catch (e) {
      debugPrint('GameStorage: write failed ($e)');
    }
  }
}
