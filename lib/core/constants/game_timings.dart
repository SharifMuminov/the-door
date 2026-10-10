/// Tuning values for pacing. Keep horror beats short, UI motion calm.
abstract final class GameTimings {
  // UI
  static const tap = Duration(milliseconds: 180);
  static const fade = Duration(milliseconds: 450);
  static const dialog = Duration(milliseconds: 380);
  static const darkness = Duration(milliseconds: 600);
  static const breathing = Duration(seconds: 7);

  // Level flow
  static const intro = Duration(milliseconds: 5600);
  static const doorSwing = Duration(milliseconds: 1400);
  static const afterDoorOpens = Duration(milliseconds: 1500);
  static const blackout = Duration(milliseconds: 700);

  /// No new clue, item or solved puzzle for this long → the hint glows.
  static const stuckAfter = Duration(seconds: 45);

  /// How long room progress waits before being written to disk.
  static const saveDebounce = Duration(milliseconds: 300);

  /// A keypad closes itself this long after the right code; anything that
  /// opens a new dialog afterwards waits at least this long.
  static const afterKeypad = Duration(milliseconds: 1600);

  // The mirror — the clock
  static const secondsPerClockMinute = 5;

  // Hide — the blackouts
  static const blackoutFirst = Duration(seconds: 9);
  static const blackoutWarning = Duration(milliseconds: 2600);
  static const blackoutGrace = Duration(milliseconds: 2200);
  static const passBy = Duration(milliseconds: 3200);
  static const caught = Duration(milliseconds: 1500);
  static const blackoutRepeat = Duration(seconds: 18);

  // The lullaby — the music box
  static const musicAfterNote = Duration(seconds: 4);
  static const musicResume = Duration(seconds: 2);

  /// How long the music plays each time, in turn. Never the same twice.
  static const musicLengths = [
    Duration(seconds: 9),
    Duration(seconds: 7),
    Duration(seconds: 10),
    Duration(seconds: 6),
    Duration(seconds: 8),
  ];

  /// Reaction time after the music stops before a touch counts as moving.
  static const stillnessGrace = Duration(milliseconds: 600);
  static const stillness = Duration(milliseconds: 4200);

  // The bells
  static const bellsFirst = Duration(seconds: 4);
  static const bellInterval = Duration(milliseconds: 760);
  static const bellAnswer = Duration(seconds: 16);
  static const bellsNextRound = Duration(milliseconds: 2800);
  static const bellsRetry = Duration(milliseconds: 4200);

  // The dinner
  static const guestSits = Duration(milliseconds: 2200);

  // The knock
  static const firstKnockDelay = Duration(seconds: 9);
  static const knockAfterKey = Duration(milliseconds: 2200);
  static const knockRepeat = Duration(seconds: 12);
  static const knockInterval = Duration(milliseconds: 540);
  static const knockingLasts = Duration(milliseconds: 2400);
}
