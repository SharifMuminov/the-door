import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../core/l10n/l_text.dart';
import 'clue.dart';
import 'game_object.dart';
import 'puzzle.dart';

/// Which set of rules a room runs. Decouples behaviour from room numbers,
/// so rooms can be reordered or inserted freely.
enum RoomKind {
  rule,
  mirror,
  candles,
  hide,
  radio,
  lullaby,
  portraits,
  bells,
  dinner,
  study,
  knock,
}

@immutable
class Level {
  const Level({
    required this.number,
    required this.kind,
    required this.title,
    required this.epigraph,
    required this.objects,
    required this.doorPuzzle,
    required this.note,
    required this.lockedMessage,
    required this.wallTint,
    required this.doorLight,
    this.sidePuzzles = const [],
    this.clockMinutes = 0,
  });

  final int number;
  final RoomKind kind;

  /// Subtitle shown on the intro card, e.g. "THE RULE".
  final LText title;

  /// One line of the story, shown under the title on the intro card.
  final LText epigraph;

  /// Drawn in list order: later objects sit on top and win taps.
  final List<GameObject> objects;
  final Puzzle doorPuzzle;

  /// Puzzles inside the room that are not the door (a locked diary...).
  final List<Puzzle> sidePuzzles;

  /// The rule written on this room's note.
  final ClueId note;

  /// Whispered when the player tries the door without the solution.
  final LText lockedMessage;

  /// Minutes since midnight shown by the clock when the room starts.
  final int clockMinutes;

  /// A faint colour cast on the wall.
  final Color wallTint;

  /// Light leaking under the door.
  final Color doorLight;

  LText get code {
    final n = number.toString().padLeft(2, '0');
    return LText('ROOM $n', 'XONA $n');
  }

  bool has(ObjectId id) => objects.any((o) => o.id == id);
}
