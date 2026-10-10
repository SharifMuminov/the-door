import 'package:flutter/foundation.dart';

import '../../core/l10n/l_text.dart';

enum ClueId {
  firstRule,
  doorRemembers,
  ruleTwo,
  mirrorReflection,
  ruleThree,
  photoBack,
  ruleFour,
  ruleFive,
  radioNumbers,
  calendar,
  ruleSix,
  ruleSeven,
  ruleEight,
  ruleNine,
  ruleTen,
  marksWall,
  marksDesk,
  marksFloor,
  diaryPages,
  finalRule,
  phoneMessages,
  windowTruth,
}

/// How a clue is presented.
enum ClueStyle {
  /// An old, damaged sheet of paper.
  paper,

  /// Messages appearing one by one on a phone screen.
  phone,

  /// Bare text in the dark, line by line.
  plain,
}

@immutable
class Clue {
  const Clue({
    required this.id,
    required this.title,
    required this.lines,
    this.style = ClueStyle.paper,
  });

  final ClueId id;
  final LText title;

  /// Paragraphs for paper/plain, separate messages for phone.
  final List<LText> lines;
  final ClueStyle style;
}
