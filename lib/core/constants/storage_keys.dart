/// Every SharedPreferences key used by the game, in one place.
abstract final class GameStorageKeys {
  static const currentLevel = 'the_door.current_level';
  static const completedLevels = 'the_door.completed_levels';
  static const endingsSeen = 'the_door.endings_seen';

  /// JSON snapshot of the room in progress (see GameState.toJson).
  static const roomProgress = 'the_door.room_progress';
  static const soundEnabled = 'the_door.sound_enabled';
  static const vibrationEnabled = 'the_door.vibration_enabled';
  static const language = 'the_door.language';
}
