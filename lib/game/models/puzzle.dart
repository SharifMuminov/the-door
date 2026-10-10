import 'package:flutter/foundation.dart';

import '../../core/l10n/l_text.dart';

enum PuzzleId {
  doorCode,
  mirrorLock,
  candleOrder,
  ironLock,
  radioCode,
  dollLock,
  portraitLock,
  bellPattern,
  dinnerTable,
  diaryLock,
  studyLock,
  finalLock,
}

enum PuzzleType {
  /// Solved by typing [Puzzle.solution] on a keypad.
  keypad,

  /// Solved by holding the item whose name is [Puzzle.solution].
  keyItem,

  /// Solved by touching objects in the order given by [Puzzle.solution]
  /// (comma-separated object names).
  sequence,

  /// Solved by setting exactly the objects listed in [Puzzle.solution],
  /// in any order.
  arrangement,
}

@immutable
class Puzzle {
  const Puzzle({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.solution,
    this.solved = false,
  });

  final PuzzleId id;
  final LText title;
  final LText description;
  final PuzzleType type;
  final String solution;
  final bool solved;

  bool check(String attempt) => attempt.trim() == solution;

  int get length => solution.length;

  /// For [PuzzleType.sequence] and [PuzzleType.arrangement]: the object names.
  List<String> get steps => solution.split(',');

  Puzzle solve() => copyWith(solved: true);

  Puzzle copyWith({bool? solved}) => Puzzle(
    id: id,
    title: title,
    description: description,
    type: type,
    solution: solution,
    solved: solved ?? this.solved,
  );
}
