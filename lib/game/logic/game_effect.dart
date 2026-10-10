import 'package:flutter/foundation.dart';

import '../../core/l10n/l_text.dart';
import '../../core/utils/audio_manager.dart';
import '../models/clue.dart';
import '../models/game_object.dart';
import '../models/puzzle.dart';
import 'game_state.dart';

/// One-shot things the UI must do: show a note, play a sound, scare the
/// player. They are not part of [GameState] because they must happen once,
/// not on every rebuild.
@immutable
sealed class GameEffect {
  const GameEffect();
}

final class MessageEffect extends GameEffect {
  const MessageEffect(this.text);
  final LText text;
}

final class SoundEffect extends GameEffect {
  const SoundEffect(this.sfx, {this.volume = 1});
  final Sfx sfx;
  final double volume;
}

/// Starts a looping sound (the music box), or stops it when [sfx] is null.
final class LoopEffect extends GameEffect {
  const LoopEffect(this.sfx, {this.volume = 1});
  final Sfx? sfx;
  final double volume;
}

final class ClueEffect extends GameEffect {
  const ClueEffect(this.clue);
  final Clue clue;
}

final class KeypadEffect extends GameEffect {
  const KeypadEffect(this.puzzle);
  final Puzzle puzzle;
}

final class ChoiceEffect extends GameEffect {
  const ChoiceEffect(this.choice);
  final Choice choice;
}

final class HorrorEffect extends GameEffect {
  const HorrorEffect(this.kind);
  final HorrorKind kind;
}

/// The bells ring [bells] one after another. The UI plays them, then calls
/// `GameController.patternShown` so the player may answer.
final class PatternEffect extends GameEffect {
  const PatternEffect(this.bells);
  final List<ObjectId> bells;
}

/// The player pulled one bell.
final class BellEffect extends GameEffect {
  const BellEffect(this.bell);
  final ObjectId bell;
}

/// The door of the current room has been unlocked and swings open.
final class DoorOpenEffect extends GameEffect {
  const DoorOpenEffect();
}

final class EndingEffect extends GameEffect {
  const EndingEffect(this.ending);
  final GameEnding ending;
}

enum HorrorKind {
  lampShadow,
  lampFlicker,
  wrongCode,
  knock,
  heavyKnock,
  midnight,
  mirrorApparition,
  glitch,
  silence,
  candlesOut,
  bulbFlicker,
  lightsOut,
  passBy,
  caught,
  radioScream,
  musicStops,
  dollCaught,
  impostor,
  wrongBell,
  footsteps,
  guestSits,
  handwriting,
}

enum ChoiceAction {
  turnOnLamp,
  leaveLamp,
  answerCaller,
  staySilent,
  lookBehind,
  leavePortrait,
  openDoor,
  stepBack,
  lockDoor,
}

@immutable
class ChoiceOption {
  const ChoiceOption(this.label, this.action, {this.danger = false});
  final LText label;
  final ChoiceAction action;
  final bool danger;
}

@immutable
class Choice {
  const Choice({
    required this.title,
    required this.body,
    required this.options,
    this.dismissAction,
  });

  final LText title;
  final LText body;
  final List<ChoiceOption> options;

  /// What happens if the player closes the dialog without choosing.
  /// Null means nothing happens.
  final ChoiceAction? dismissAction;
}
