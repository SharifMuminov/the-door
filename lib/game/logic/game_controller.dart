import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/game_timings.dart';
import '../../core/l10n/l_text.dart';
import '../../core/utils/audio_manager.dart';
import '../../core/utils/game_storage.dart';
import '../data/game_data.dart';
import '../models/clue.dart';
import '../models/game_object.dart';
import '../models/inventory_item.dart';
import '../models/level.dart';
import '../models/puzzle.dart';
import 'game_effect.dart';
import 'game_state.dart';
import 'hints.dart';

/// All rules of the game live here. The UI only reports taps and plays
/// whatever [effects] it is told to play.
///
/// Room progress is saved automatically on every change, so CONTINUE
/// resumes inside the room, not only at its start.
class GameController extends Cubit<GameState> {
  GameController({required GameStorage storage, int startLevel = 1})
    : _storage = storage,
      super(GameState.forLevel(GameData.level(startLevel)));

  final GameStorage _storage;
  final _effects = StreamController<GameEffect>.broadcast();
  final _timers = <Timer>[];
  Timer? _clock;
  Timer? _knockLoop;
  Timer? _stuck;
  Timer? _saveTimer;
  Timer? _answer;
  int _clockSeconds = 0;

  /// The lullaby: how many times the music has played / stopped, and
  /// whether the doll already saw the player move in this silence.
  int _musicCycle = 0;
  int _musicStops = 0;
  bool _caughtThisSilence = false;

  /// The portrait the player is being asked about.
  ObjectId? _choiceTarget;

  /// The dinner: something is sitting down; the table cannot be touched.
  bool _guestSitting = false;

  Stream<GameEffect> get effects => _effects.stream;

  Level get level => GameData.level(state.currentLevel);

  /// A safe level number from whatever was saved (or nothing).
  static int resolveLevel(int? saved) =>
      (saved ?? 1).clamp(1, GameData.levelCount);

  // ================================================================ flow

  /// Starts a session. [fresh] wipes saved progress first (PLAY);
  /// otherwise the room is restored exactly where it was left.
  Future<void> start({required int level, bool fresh = false}) async {
    if (fresh) await _storage.resetProgress();
    final restored = fresh ? null : _restore(level);
    if (restored == null) {
      await enterLevel(level);
    } else {
      _cancelTimers();
      _emit(restored);
    }
  }

  /// Resets the room to its initial state and saves it as a checkpoint.
  Future<void> enterLevel(int number) async {
    _cancelTimers();
    final next = GameData.level(number);
    _emit(GameState.forLevel(next));
    await _storage.saveCurrentLevel(next.number);
    await _saveNow();
  }

  /// Called once the intro card has faded. Starts the room's timers.
  void beginLevel() {
    if (isClosed || state.levelStarted) return;
    _emit(state.copyWith(levelStarted: true));
    _restartStuckTimer();
    switch (level.kind) {
      case RoomKind.mirror:
        if (!state.midnightPassed) _startClock();
      case RoomKind.hide:
        _after(GameTimings.blackoutFirst, _warnBlackout);
      case RoomKind.lullaby:
        if (state.musicWound) _after(GameTimings.musicResume, _playMusic);
      case RoomKind.bells:
        if (!_doorPuzzle.solved) _after(GameTimings.bellsFirst, _ringBells);
      case RoomKind.knock:
        if (!state.knockingStarted) {
          _after(GameTimings.firstKnockDelay, _knock);
        } else if (state.has(ItemId.key) && !state.knows(ClueId.windowTruth)) {
          _startKnockLoop();
        }
      default:
        break;
    }
  }

  /// Called after the door animation.
  Future<void> goToNextLevel() async {
    if (isClosed || state.currentLevel >= GameData.levelCount) return;
    await enterLevel(state.currentLevel + 1);
  }

  // ================================================================ input

  void interact(ObjectId id) {
    if (isClosed ||
        !state.levelStarted ||
        state.doorUnlocked ||
        state.isOver ||
        state.hidden) {
      return;
    }
    final count = state.timesTouched(id) + 1;
    _emit(
      state.copyWith(
        interactionCounts: {...state.interactionCounts, id: count},
      ),
    );

    // The lullaby: once the music has stopped, any touch is moving.
    if (level.kind == RoomKind.lullaby && state.stillness) {
      _movedInSilence();
      return;
    }
    if (id == ObjectId.door) {
      _touchDoor();
      return;
    }
    if (id == ObjectId.note) {
      _readNote();
      return;
    }
    switch (level.kind) {
      case RoomKind.rule:
        _ruleRoom(id, count);
      case RoomKind.mirror:
        _mirrorRoom(id, count);
      case RoomKind.candles:
        _candleRoom(id);
      case RoomKind.hide:
        _hideRoom(id);
      case RoomKind.radio:
        _radioRoom(id);
      case RoomKind.lullaby:
        _lullabyRoom(id, count);
      case RoomKind.portraits:
        _portraitRoom(id, count);
      case RoomKind.bells:
        _bellRoom(id, count);
      case RoomKind.dinner:
        _dinnerRoom(id);
      case RoomKind.study:
        _studyRoom(id, count);
      case RoomKind.knock:
        _knockRoom(id);
    }
  }

  /// Returns true when the code is right. Without [id] the code is for the
  /// door; otherwise for that puzzle inside the room (the diary).
  bool submitCode(String code, {PuzzleId? id}) {
    if (isClosed || state.isOver) return false;
    final puzzle = id == null ? _doorPuzzle : state.puzzles[id];
    if (puzzle == null || puzzle.type != PuzzleType.keypad) return false;
    if (puzzle.solved) return true;
    if (!puzzle.check(code)) {
      _effect(const HorrorEffect(HorrorKind.wrongCode));
      return false;
    }
    if (puzzle.id == level.doorPuzzle.id) {
      _unlockDoor();
    } else {
      _solveSidePuzzle(puzzle);
    }
    return true;
  }

  void choose(ChoiceAction action) {
    if (isClosed || state.isOver) return;
    switch (action) {
      case ChoiceAction.turnOnLamp:
        _turnOnLamp();
      case ChoiceAction.leaveLamp:
        _say(Lines.lampLeft);
      case ChoiceAction.answerCaller:
        _emit(state.copyWith(radioStation: 1));
        _effect(const HorrorEffect(HorrorKind.radioScream));
        _after(const Duration(milliseconds: 1600), () => _say(Lines.answered));
      case ChoiceAction.staySilent:
        _emit(state.copyWith(radioStation: 2));
        _learn(ClueId.radioNumbers);
        _say(Lines.stayedSilent);
      case ChoiceAction.lookBehind:
        final target = _choiceTarget;
        _choiceTarget = null;
        if (target != null && level.kind == RoomKind.portraits) {
          _lookBehind(target);
        }
      case ChoiceAction.leavePortrait:
        _choiceTarget = null;
      case ChoiceAction.openDoor:
        _finish(GameEnding.bad);
      case ChoiceAction.lockDoor:
        _finish(GameEnding.good);
      case ChoiceAction.stepBack:
        _say(Lines.stepBack);
        _knock(heavy: true);
    }
  }

  void inspectItem(ItemId id) {
    if (isClosed || !state.has(id)) return;
    final item = GameData.item(id);
    final clue = item.clue;
    if (clue != null) {
      _effect(ClueEffect(GameData.clue(clue)));
    } else {
      _say(item.description);
    }
  }

  /// Whispers a nudge for the current situation.
  void requestHint() {
    if (isClosed || !state.levelStarted || state.isOver || state.doorUnlocked) {
      return;
    }
    _sound(Sfx.breath, .3);
    _say(hintFor(level, state));
    _emit(state.copyWith(hintReady: false));
    _restartStuckTimer();
  }

  /// Leaves the wardrobe in the hiding room.
  void stepOut() {
    if (isClosed || !state.hidden) return;
    _emit(state.copyWith(hidden: false));
    _sound(Sfx.creak, .4);
  }

  /// The UI has finished ringing the bell tune: the player may answer.
  void patternShown() {
    if (isClosed || level.kind != RoomKind.bells || _doorPuzzle.solved) {
      return;
    }
    _emit(state.copyWith(bellsListening: true, bellInput: const []));
    _waitForAnswer();
  }

  // ================================================================ doors

  Puzzle get _doorPuzzle =>
      state.puzzles[level.doorPuzzle.id] ?? level.doorPuzzle;

  bool get _roomDone => state.doorUnlocked || state.isOver;

  void _touchDoor() {
    final puzzle = _doorPuzzle;
    switch (puzzle.type) {
      case PuzzleType.keypad:
        if (puzzle.solved) return;
        _sound(Sfx.click, .5);
        _effect(KeypadEffect(puzzle));
      case PuzzleType.sequence || PuzzleType.arrangement:
        if (puzzle.solved) {
          _unlockDoor();
        } else {
          _sound(Sfx.lock, .3);
          _say(level.lockedMessage);
        }
      case PuzzleType.keyItem:
        _tryKey(puzzle);
    }
  }

  void _tryKey(Puzzle puzzle) {
    final key = ItemId.values
        .where((i) => i.name == puzzle.solution)
        .firstOrNull;
    if (key == null || !state.has(key)) {
      _sound(Sfx.lock, .3);
      final breathing = level.kind == RoomKind.knock && state.knockingStarted;
      _say(breathing ? Lines.doorBreathing : level.lockedMessage);
      return;
    }
    if (level.kind == RoomKind.knock) {
      _offerFinalChoice();
    } else {
      _say(Lines.doorOpens);
      _unlockDoor();
    }
  }

  void _unlockDoor() {
    final puzzle = _doorPuzzle;
    _cancelTimers();
    _emit(
      state.copyWith(
        doorUnlocked: true,
        isKnocking: false,
        lightsOut: false,
        lightsFlickering: false,
        hidden: false,
        musicPlaying: false,
        stillness: false,
        bellsListening: false,
        hintReady: false,
        puzzles: {...state.puzzles, puzzle.id: puzzle.solve()},
      ),
    );
    _effect(const LoopEffect(null));
    final number = state.currentLevel;
    unawaited(_storage.clearRoomProgress());
    unawaited(_storage.markLevelCompleted(number));
    if (number < GameData.levelCount) {
      unawaited(_storage.saveCurrentLevel(number + 1));
    }
    _effect(const DoorOpenEffect());
  }

  void _solveSidePuzzle(Puzzle puzzle) {
    _emit(
      state.copyWith(puzzles: {...state.puzzles, puzzle.id: puzzle.solve()}),
    );
    if (puzzle.id == PuzzleId.diaryLock) _diaryOpened();
  }

  void _readNote() {
    _read(level.note);
    // The lullaby: once the rule is known, the music box starts by itself.
    if (level.kind == RoomKind.lullaby && !state.musicWound) {
      _after(GameTimings.musicAfterNote, () {
        if (state.musicWound || _roomDone) return;
        _emit(state.copyWith(musicWound: true));
        _say(Lines.musicByItself);
        _playMusic();
      });
    }
  }

  // ================================================================ THE RULE

  void _ruleRoom(ObjectId id, int count) {
    switch (id) {
      case ObjectId.lamp:
        _touchLamp();
      case ObjectId.drawer:
        _touchDrawer(count);
      case ObjectId.clock:
        _say(count == 1 ? Lines.clock1 : Lines.clock1Again);
      case ObjectId.table:
        _say(count == 1 ? Lines.table1 : Lines.table1Again);
      default:
        break;
    }
  }

  void _touchLamp() {
    if (state.lampOn) {
      _emit(state.copyWith(lampOn: false));
      _sound(Sfx.lampSwitch, .6);
      _say(Lines.lampOff);
      return;
    }
    _effect(
      const ChoiceEffect(
        Choice(
          title: Lines.lampPromptTitle,
          body: Lines.lampPrompt,
          options: [
            ChoiceOption(
              Lines.lampTurnOn,
              ChoiceAction.turnOnLamp,
              danger: true,
            ),
            ChoiceOption(Lines.lampLeave, ChoiceAction.leaveLamp),
          ],
          dismissAction: ChoiceAction.leaveLamp,
        ),
      ),
    );
  }

  void _turnOnLamp() {
    if (state.lampOn || level.kind != RoomKind.rule) return;
    final first = !state.lampEventSeen;
    _emit(state.copyWith(lampOn: true, lampEventSeen: true));
    _effect(
      HorrorEffect(first ? HorrorKind.lampShadow : HorrorKind.lampFlicker),
    );
    _after(
      const Duration(milliseconds: 1800),
      () => _say(first ? Lines.lampOn : Lines.lampAgain),
    );
  }

  void _touchDrawer(int count) {
    final opening = !state.drawerOpen;
    _emit(state.copyWith(drawerOpen: opening));
    _sound(Sfx.drawer, .8);

    if (!opening) {
      if (count == 2) _say(Lines.drawerClosed);
      return;
    }
    if (!state.has(ItemId.drawerCode)) {
      _gain(ItemId.drawerCode);
      _after(
        const Duration(milliseconds: 450),
        () => _read(ClueId.doorRemembers),
      );
    } else if (count == 3) {
      _say(Lines.drawerAgain);
      _effect(const HorrorEffect(HorrorKind.glitch));
    } else {
      _say(Lines.drawerEmpty);
    }
  }

  // ================================================================ DON'T LOOK

  void _mirrorRoom(ObjectId id, int count) {
    switch (id) {
      case ObjectId.mirror:
        _touchMirror();
      case ObjectId.painting:
        _touchPainting(count);
      case ObjectId.chair:
        _say(count == 1 ? Lines.chair : Lines.chairAgain);
      case ObjectId.clock:
        _say(
          state.midnightPassed
              ? Lines.clockMidnight
              : Lines.clockRunning.prefixed('${state.clockLabel}. '),
        );
      default:
        break;
    }
  }

  void _startClock() {
    _emit(state.copyWith(clockRunning: true));
    _clockSeconds = 0;
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tickClock());
  }

  void _tickClock() {
    if (isClosed || state.midnightPassed) {
      _clock?.cancel();
      return;
    }
    _clockSeconds++;
    _sound(Sfx.tick, .35);
    if (_clockSeconds % GameTimings.secondsPerClockMinute != 0) return;

    final next = state.clockMinutes + 1;
    if (next >= 24 * 60) {
      _strikeMidnight();
    } else {
      _emit(state.copyWith(clockMinutes: next));
    }
  }

  void _strikeMidnight() {
    _clock?.cancel();
    _emit(
      state.copyWith(
        clockMinutes: 0,
        clockRunning: false,
        midnightPassed: true,
      ),
    );
    _effect(const HorrorEffect(HorrorKind.midnight));
    _after(const Duration(milliseconds: 1400), () => _say(Lines.midnight));
  }

  void _touchMirror() {
    if (!state.midnightPassed) {
      _read(ClueId.mirrorReflection);
      return;
    }
    if (!state.mirrorTriggered) {
      _emit(state.copyWith(mirrorTriggered: true));
      _effect(const HorrorEffect(HorrorKind.mirrorApparition));
      _after(const Duration(milliseconds: 2000), () => _say(Lines.mirrorAfter));
      return;
    }
    _effect(const HorrorEffect(HorrorKind.glitch));
    _say(Lines.mirrorAgain);
  }

  void _touchPainting(int count) {
    if (state.has(ItemId.paintingKey)) {
      _say(Lines.paintingEmpty);
      return;
    }
    // The mirror shows where the key is; after midnight (or with enough
    // stubbornness) the painting gives it up anyway, so nobody gets stuck.
    final found =
        state.knows(ClueId.mirrorReflection) ||
        state.midnightPassed ||
        count >= 3;
    if (found) {
      _emit(state.copyWith(paintingMoved: true));
      _gain(ItemId.paintingKey);
      _sound(Sfx.key);
      _say(Lines.paintingKey);
    } else {
      _say(count == 1 ? Lines.paintingPlain : Lines.paintingPlainAgain);
    }
  }

  // ================================================================ THE CANDLES

  void _candleRoom(ObjectId id) {
    if (id.isCandle) {
      _touchCandle(id);
    } else if (id == ObjectId.photo) {
      if (state.knows(ClueId.photoBack) && state.timesTouched(id) % 2 == 0) {
        _say(Lines.photoAgain);
      } else {
        _read(ClueId.photoBack);
      }
    }
  }

  void _touchCandle(ObjectId id) {
    final puzzle = _doorPuzzle;
    if (puzzle.solved || state.litCandles.contains(id)) {
      _say(Lines.candleBurning);
      return;
    }
    final lit = [...state.litCandles, id];
    _emit(state.copyWith(litCandles: lit));
    _sound(Sfx.ignite, .8);
    _say(Lines.candleCarved.suffixed('${GameData.candleNames[id]}.'));

    final steps = puzzle.steps;
    final inOrder = [
      for (var i = 0; i < lit.length && i < steps.length; i++)
        lit[i].name == steps[i],
    ].every((ok) => ok);

    if (!inOrder) {
      _after(const Duration(milliseconds: 1300), () {
        if (state.litCandles.isEmpty) return;
        _emit(state.copyWith(litCandles: const []));
        _effect(const HorrorEffect(HorrorKind.candlesOut));
        _say(Lines.candlesOut);
      });
    } else if (lit.length == steps.length) {
      _emit(
        state.copyWith(puzzles: {...state.puzzles, puzzle.id: puzzle.solve()}),
      );
      _after(const Duration(milliseconds: 1200), () {
        _sound(Sfx.lock);
        _say(Lines.candlesSolved);
      });
    }
  }

  // ================================================================ HIDE

  void _hideRoom(ObjectId id) {
    switch (id) {
      case ObjectId.wardrobe:
        _emit(state.copyWith(hidden: true));
        _sound(Sfx.creak, .5);
        _sound(Sfx.breath, .5);
        _say(Lines.wardrobeHide);
      case ObjectId.bulb:
        _say(Lines.bulb);
      case ObjectId.chair:
        _say(Lines.chair4);
      case ObjectId.floorKey:
        if (state.keyRevealed && !state.has(ItemId.ironKey)) {
          _gain(ItemId.ironKey);
          _sound(Sfx.key);
          _say(Lines.ironKey);
        }
      default:
        break;
    }
  }

  void _warnBlackout() {
    if (_roomDone) return;
    _emit(state.copyWith(lightsFlickering: true));
    _effect(const HorrorEffect(HorrorKind.bulbFlicker));
    _after(GameTimings.blackoutWarning, _blackout);
  }

  void _blackout() {
    _emit(state.copyWith(lightsFlickering: false, lightsOut: true));
    _effect(const HorrorEffect(HorrorKind.lightsOut));
    _after(GameTimings.blackoutGrace, () {
      if (state.hidden) {
        _effect(const HorrorEffect(HorrorKind.passBy));
        _after(GameTimings.passBy, () => _lightsBack(survived: true));
      } else {
        _effect(const HorrorEffect(HorrorKind.caught));
        _after(GameTimings.caught, () => _lightsBack(survived: false));
      }
    });
  }

  void _lightsBack({required bool survived}) {
    _emit(state.copyWith(lightsOut: false));
    if (survived) {
      // It is gone. Step out and see what it left.
      _emit(state.copyWith(hidden: false));
      _sound(Sfx.creak, .4);
      if (!state.keyRevealed) {
        _emit(state.copyWith(keyRevealed: true));
        _after(const Duration(milliseconds: 900), () => _say(Lines.itLeft));
      }
    } else {
      _say(Lines.itSawYou);
    }
    _after(GameTimings.blackoutRepeat, _warnBlackout);
  }

  // ================================================================ DON'T ANSWER

  void _radioRoom(ObjectId id) {
    switch (id) {
      case ObjectId.radio:
        _tuneRadio();
      case ObjectId.calendar:
        _learn(ClueId.calendar);
        _say(Lines.calendar);
      case ObjectId.table:
        _say(Lines.table5);
      default:
        break;
    }
  }

  void _tuneRadio() {
    final next = state.radioStation % 3 + 1;
    _emit(state.copyWith(radioStation: next));
    _sound(Sfx.radioStatic, .55);
    switch (next) {
      case 1:
        _say(Lines.radioStatic);
      case 2:
        _learn(ClueId.radioNumbers);
        _say(Lines.radioNumbers);
      default:
        if (state.callerHeard) {
          _say(Lines.radioBreathing);
          return;
        }
        _emit(state.copyWith(callerHeard: true));
        _effect(
          const ChoiceEffect(
            Choice(
              title: Lines.callerTitle,
              body: Lines.callerBody,
              options: [
                ChoiceOption(
                  Lines.answer,
                  ChoiceAction.answerCaller,
                  danger: true,
                ),
                ChoiceOption(Lines.staySilent, ChoiceAction.staySilent),
              ],
              dismissAction: ChoiceAction.staySilent,
            ),
          ),
        );
    }
  }

  // ================================================================ THE LULLABY

  void _lullabyRoom(ObjectId id, int count) {
    switch (id) {
      case ObjectId.musicBox:
        _touchMusicBox();
      case ObjectId.doll:
        _touchDoll();
      case ObjectId.cradle:
        _say(count == 1 ? Lines.cradle : Lines.cradleAgain);
      case ObjectId.drawer:
        _say(count == 1 ? Lines.dresser : Lines.dresserAgain);
      default:
        break;
    }
  }

  void _touchMusicBox() {
    if (!state.musicWound) {
      _emit(state.copyWith(musicWound: true));
      _sound(Sfx.click, .6);
      _say(Lines.musicWind);
      _playMusic();
      return;
    }
    _say(state.musicPlaying ? Lines.musicPlaying : Lines.musicWoundDown);
  }

  void _playMusic() {
    if (_roomDone || state.musicPlaying) return;
    _emit(state.copyWith(musicPlaying: true, stillness: false));
    _effect(const LoopEffect(Sfx.musicBox, volume: .75));
    final lengths = GameTimings.musicLengths;
    _after(lengths[_musicCycle++ % lengths.length], _stopMusic);
  }

  /// The music stops. The doll comes a little closer, then watches.
  void _stopMusic() {
    if (_roomDone || !state.musicPlaying) return;
    _caughtThisSilence = false;
    _emit(
      state.copyWith(
        musicPlaying: false,
        dollSpot: math.min(state.dollSpot + 1, GameData.dollSpots.length - 1),
      ),
    );
    _effect(const LoopEffect(null));
    _effect(const HorrorEffect(HorrorKind.musicStops));
    if (_musicStops++ < 2) _say(Lines.musicStops);
    _after(GameTimings.stillnessGrace, () {
      if (!_roomDone) _emit(state.copyWith(stillness: true));
    });
    _after(GameTimings.stillnessGrace + GameTimings.stillness, _playMusic);
  }

  void _touchDoll() {
    if (state.has(ItemId.dollKey)) {
      _say(Lines.dollSmiling);
      return;
    }
    if (!state.musicPlaying) {
      _say(Lines.dollWaiting);
      return;
    }
    final fingers = state.dollFingers + 1;
    _emit(state.copyWith(dollFingers: math.min(fingers, 3)));
    if (fingers >= 3) {
      _gain(ItemId.dollKey);
      _sound(Sfx.key);
      _say(Lines.dollKey);
    } else {
      _sound(Sfx.click, .5);
      _say(fingers == 1 ? Lines.dollFinger : Lines.dollFingerAgain);
    }
  }

  void _movedInSilence() {
    // One scare per silence is enough.
    if (_caughtThisSilence) return;
    _caughtThisSilence = true;
    final lost = state.dollFingers > 0 && !state.has(ItemId.dollKey);
    if (lost) _emit(state.copyWith(dollFingers: 0));
    _effect(const HorrorEffect(HorrorKind.dollCaught));
    _after(
      const Duration(milliseconds: 1200),
      () => _say(lost ? Lines.handsClosed : Lines.sawYouMove),
    );
  }

  // ================================================================ THE PORTRAITS

  void _portraitRoom(ObjectId id, int count) {
    if (id.isPortrait) {
      _askPortrait(id);
    } else if (id == ObjectId.emptyFrame) {
      _say(count == 1 ? Lines.emptyFrame : Lines.emptyFrameAgain);
    }
  }

  void _askPortrait(ObjectId id) {
    final words = GameData.portraitWords[id]!;
    if (state.lookedBehind.contains(id)) {
      _say(id == ObjectId.portraitMarta ? Lines.stillWatching : words);
      return;
    }
    _choiceTarget = id;
    final plate = GameData.portraitPlates[id]!;
    _effect(
      ChoiceEffect(
        Choice(
          title: LText(plate, plate),
          body: words,
          options: const [
            ChoiceOption(Lines.lookBehind, ChoiceAction.lookBehind),
            ChoiceOption(Lines.leavePortrait, ChoiceAction.leavePortrait),
          ],
          dismissAction: ChoiceAction.leavePortrait,
        ),
      ),
    );
  }

  void _lookBehind(ObjectId id) {
    if (state.lookedBehind.contains(id)) return;
    _emit(state.copyWith(lookedBehind: {...state.lookedBehind, id}));
    switch (id) {
      case ObjectId.portraitMarta:
        // It was never her.
        _effect(const HorrorEffect(HorrorKind.impostor));
        _after(const Duration(milliseconds: 1700), () => _say(Lines.notMarta));
      case ObjectId.portraitElias:
        _gain(ItemId.portraitKey);
        _sound(Sfx.key);
        _say(Lines.eliasKey);
      default:
        _sound(Sfx.paper, .5);
        _say(Lines.annaSorry);
    }
  }

  // ================================================================ THE BELLS

  /// How many bells the tune has in the current round.
  int get _tuneLength =>
      math.min(3 + state.bellRound, _doorPuzzle.steps.length);

  void _bellRoom(ObjectId id, int count) {
    if (id.isBell) {
      _pullBell(id);
    } else if (id == ObjectId.coat) {
      _say(count == 1 ? Lines.coat : Lines.coatAgain);
    }
  }

  void _ringBells() {
    if (_roomDone || _doorPuzzle.solved) return;
    _answer?.cancel();
    final tune = [
      for (final name in _doorPuzzle.steps.take(_tuneLength))
        ObjectId.values.byName(name),
    ];
    _emit(state.copyWith(bellsListening: false, bellInput: const []));
    _effect(PatternEffect(tune));
  }

  void _pullBell(ObjectId bell) {
    _effect(BellEffect(bell));
    if (_doorPuzzle.solved) {
      _say(Lines.bellsQuiet);
      return;
    }
    if (!state.bellsListening) {
      _say(Lines.bellsWait);
      return;
    }
    final input = [...state.bellInput, bell];
    final steps = _doorPuzzle.steps;
    if (input.last.name != steps[input.length - 1]) {
      _bellsWrong();
      return;
    }
    if (input.length < _tuneLength) {
      _emit(state.copyWith(bellInput: input));
      _waitForAnswer();
      return;
    }

    // The whole tune, answered.
    _answer?.cancel();
    final complete = input.length >= steps.length;
    _emit(
      state.copyWith(
        bellRound: state.bellRound + 1,
        bellInput: const [],
        bellsListening: false,
        puzzles: complete
            ? {...state.puzzles, _doorPuzzle.id: _doorPuzzle.solve()}
            : null,
      ),
    );
    if (complete) {
      _after(const Duration(milliseconds: 900), () {
        _sound(Sfx.lock);
        _say(Lines.bellsSolved);
      });
    } else {
      _after(const Duration(milliseconds: 900), () => _say(Lines.bellsAgain));
      _after(GameTimings.bellsNextRound, _ringBells);
    }
  }

  void _bellsWrong() {
    _answer?.cancel();
    _emit(state.copyWith(bellsListening: false, bellInput: const []));
    _effect(const HorrorEffect(HorrorKind.wrongBell));
    _after(const Duration(milliseconds: 1100), () => _say(Lines.bellsWrong));
    _after(GameTimings.bellsRetry, _ringBells);
  }

  void _waitForAnswer() {
    _answer?.cancel();
    _answer = Timer(GameTimings.bellAnswer, () {
      if (isClosed || !state.bellsListening || _roomDone) return;
      _emit(state.copyWith(bellsListening: false, bellInput: const []));
      _effect(const HorrorEffect(HorrorKind.footsteps));
      _say(Lines.bellsUnanswered);
      _after(GameTimings.bellsRetry, _ringBells);
    });
  }

  // ================================================================ THE DINNER

  void _dinnerRoom(ObjectId id) {
    if (id.isSeat) {
      _touchSeat(id);
    } else if (id == ObjectId.clock) {
      _say(Lines.dinnerClock);
    } else if (id == ObjectId.diningTable) {
      _say(Lines.dinnerTable);
    }
  }

  void _touchSeat(ObjectId seat) {
    final puzzle = _doorPuzzle;
    if (puzzle.solved) {
      _say(Lines.dinnerServed);
      return;
    }
    if (_guestSitting) return;

    if (state.setPlaces.contains(seat)) {
      _emit(state.copyWith(setPlaces: {...state.setPlaces}..remove(seat)));
      _sound(Sfx.plate, .5);
      _say(Lines.plateTaken);
      return;
    }
    final places = {...state.setPlaces, seat};
    _emit(state.copyWith(setPlaces: places));
    _sound(Sfx.plate);

    if (seat == GameData.guestSeat) {
      _guestSits();
      return;
    }
    final wanted = puzzle.steps.toSet();
    if (places.length == wanted.length &&
        places.every((p) => wanted.contains(p.name))) {
      _emit(
        state.copyWith(puzzles: {...state.puzzles, puzzle.id: puzzle.solve()}),
      );
      _after(const Duration(milliseconds: 700), () {
        _sound(Sfx.scrape);
        _say(Lines.dinnerSolved);
      });
      _after(const Duration(milliseconds: 1700), () => _sound(Sfx.lock));
      return;
    }
    _say(
      seat == GameData.blankSeat
          ? Lines.blankCard
          : Lines.placeSet(GameData.seatCards[seat]!),
    );
  }

  void _guestSits() {
    _guestSitting = true;
    _effect(const HorrorEffect(HorrorKind.guestSits));
    _say(Lines.guestSits);
    _after(GameTimings.guestSits, () {
      _guestSitting = false;
      _emit(state.copyWith(setPlaces: const {}));
      _say(Lines.platesBroken);
    });
  }

  // ================================================================ THE STUDY

  void _studyRoom(ObjectId id, int count) {
    switch (id) {
      case ObjectId.tally:
        _learn(ClueId.marksWall);
        _say(Lines.marksWall);
      case ObjectId.desk:
        _learn(ClueId.marksDesk);
        _say(Lines.marksDesk);
      case ObjectId.floorboard:
        if (!state.knows(ClueId.marksFloor)) _sound(Sfx.creak, .5);
        _learn(ClueId.marksFloor);
        _say(Lines.marksFloor);
      case ObjectId.diary:
        _touchDiary();
      case ObjectId.inkwell:
        _touchInkwell(count);
      default:
        break;
    }
  }

  void _touchDiary() {
    final lock = state.puzzles[PuzzleId.diaryLock];
    if (lock == null) return;
    if (lock.solved) {
      _read(ClueId.diaryPages);
      return;
    }
    _sound(Sfx.click, .5);
    _effect(KeypadEffect(lock));
  }

  void _diaryOpened() {
    _gain(ItemId.diary);
    _gain(ItemId.studyKey);
    _sound(Sfx.lock, .6);
    _after(const Duration(milliseconds: 400), () => _say(Lines.diaryOpens));
    _after(GameTimings.afterKeypad, () => _read(ClueId.diaryPages));
  }

  void _touchInkwell(int count) {
    if (count == 1) {
      _say(Lines.inkwell);
      return;
    }
    if (count == 2) _effect(const HorrorEffect(HorrorKind.handwriting));
    _say(count == 2 ? Lines.handwriting : Lines.handwritingAgain);
  }

  // ================================================================ THE KNOCK

  void _knockRoom(ObjectId id) {
    switch (id) {
      case ObjectId.phone:
        if (state.knockingStarted) {
          _read(ClueId.phoneMessages);
        } else {
          _say(Lines.phoneDead);
        }
      case ObjectId.clock:
        _touchSmallClock();
      case ObjectId.window:
        _touchWindow();
      case ObjectId.table:
        _say(Lines.table6);
      default:
        break;
    }
  }

  void _knock({bool heavy = false}) {
    if (isClosed || _roomDone || state.knows(ClueId.windowTruth)) return;
    _emit(state.copyWith(knockingStarted: true, isKnocking: true));
    _effect(HorrorEffect(heavy ? HorrorKind.heavyKnock : HorrorKind.knock));
    _after(GameTimings.knockingLasts, () {
      _emit(state.copyWith(isKnocking: false));
    });
  }

  /// Heavy knocking that keeps coming back until the window is read.
  void _startKnockLoop() {
    _after(GameTimings.knockAfterKey, () {
      if (state.knows(ClueId.windowTruth)) return;
      _knock(heavy: true);
      _knockLoop?.cancel();
      _knockLoop = Timer.periodic(
        GameTimings.knockRepeat,
        (_) => _knock(heavy: true),
      );
    });
  }

  void _touchSmallClock() {
    if (state.has(ItemId.key)) {
      _say(Lines.clockAfter);
      return;
    }
    if (!state.knows(ClueId.phoneMessages)) {
      _say(Lines.clockStopped);
      return;
    }
    _gain(ItemId.key);
    _sound(Sfx.key);
    _say(Lines.clockKey);
    // The moment the key is in hand, it comes back.
    _startKnockLoop();
  }

  void _touchWindow() {
    if (state.knows(ClueId.windowTruth)) {
      _say(Lines.windowAfter);
      return;
    }
    if (!state.has(ItemId.key)) {
      _say(Lines.window);
      return;
    }
    _knockLoop?.cancel();
    _emit(state.copyWith(isKnocking: false));
    _read(ClueId.windowTruth);
    _effect(const HorrorEffect(HorrorKind.silence));
  }

  void _offerFinalChoice() {
    final understood = state.knows(ClueId.windowTruth);
    _effect(
      ChoiceEffect(
        Choice(
          title: Lines.doorChoiceTitle,
          body: understood ? Lines.doorChoiceKnown : Lines.doorChoiceKnocking,
          options: [
            const ChoiceOption(
              Lines.openIt,
              ChoiceAction.openDoor,
              danger: true,
            ),
            if (understood)
              const ChoiceOption(Lines.lockIt, ChoiceAction.lockDoor)
            else
              const ChoiceOption(Lines.stepBackOption, ChoiceAction.stepBack),
          ],
        ),
      ),
    );
  }

  void _finish(GameEnding ending) {
    if (state.isOver ||
        ending == GameEnding.none ||
        level.kind != RoomKind.knock ||
        !state.has(ItemId.key)) {
      return;
    }
    if (ending == GameEnding.good && !state.knows(ClueId.windowTruth)) return;

    _cancelTimers();
    _emit(
      state.copyWith(
        ending: ending,
        isKnocking: false,
        hintReady: false,
        doorUnlocked: ending == GameEnding.bad,
      ),
    );
    unawaited(_storage.clearRoomProgress());
    unawaited(_storage.markLevelCompleted(state.currentLevel));
    unawaited(_storage.markEndingSeen(ending.name));
    _effect(EndingEffect(ending));
  }

  // ================================================================ helpers

  void _read(ClueId id) {
    _learn(id);
    final clue = GameData.clue(id);
    switch (clue.style) {
      case ClueStyle.paper:
        _sound(Sfx.paper, .8);
      case ClueStyle.phone:
        _sound(Sfx.buzz, .7);
      case ClueStyle.plain:
        break;
    }
    _effect(ClueEffect(clue));
  }

  void _learn(ClueId id) {
    if (state.knows(id)) return;
    _emit(state.copyWith(discoveredClues: {...state.discoveredClues, id}));
  }

  void _gain(ItemId id) {
    _emit(state.copyWith(inventory: {...state.inventory, id}));
  }

  void _say(LText text) => _effect(MessageEffect(text));

  void _sound(Sfx sfx, [double volume = 1]) =>
      _effect(SoundEffect(sfx, volume: volume));

  void _effect(GameEffect effect) {
    if (!_effects.isClosed) _effects.add(effect);
  }

  void _emit(GameState next) {
    if (!isClosed) emit(next);
  }

  void _after(Duration delay, void Function() action) {
    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      if (!isClosed) action();
    });
    _timers.add(timer);
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _clock?.cancel();
    _clock = null;
    _knockLoop?.cancel();
    _knockLoop = null;
    _stuck?.cancel();
    _stuck = null;
    _answer?.cancel();
    _answer = null;
    _choiceTarget = null;
    _guestSitting = false;
  }

  // ================================================================ hints

  void _restartStuckTimer() {
    _stuck?.cancel();
    _stuck = Timer(GameTimings.stuckAfter, () {
      if (!isClosed && !_roomDone) {
        _emit(state.copyWith(hintReady: true));
      }
    });
  }

  static int _solved(GameState s) =>
      s.puzzles.values.where((p) => p.solved).length;

  static bool _progressed(GameState before, GameState after) =>
      after.inventory.length > before.inventory.length ||
      after.discoveredClues.length > before.discoveredClues.length ||
      _solved(after) > _solved(before) ||
      after.dollFingers > before.dollFingers ||
      after.lookedBehind.length > before.lookedBehind.length ||
      after.bellRound > before.bellRound;

  // ================================================================ saving

  @override
  void onChange(Change<GameState> change) {
    super.onChange(change);
    final next = change.nextState;
    if (next.levelStarted && _progressed(change.currentState, next)) {
      _restartStuckTimer();
      // Never emit from inside onChange: the state is not committed yet.
      if (next.hintReady) {
        scheduleMicrotask(() => _emit(state.copyWith(hintReady: false)));
      }
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(GameTimings.saveDebounce, () => unawaited(_saveNow()));
  }

  GameState? _restore(int level) {
    final raw = _storage.roomProgress;
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final restored = GameState.fromJson(json);
      return restored?.currentLevel == level ? restored : null;
    } catch (e) {
      debugPrint('GameController: ignoring broken save ($e)');
      return null;
    }
  }

  Future<void> _saveNow() async {
    _saveTimer?.cancel();
    if (_roomDone) return;
    await _storage.saveRoomProgress(jsonEncode(state.toJson()));
  }

  @override
  Future<void> close() async {
    _cancelTimers();
    // Leaving mid-room: make sure the last moves are on disk.
    if (_saveTimer?.isActive ?? false) await _saveNow();
    _saveTimer?.cancel();
    await _effects.close();
    return super.close();
  }
}
