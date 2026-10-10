import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_door/core/constants/game_timings.dart';
import 'package:the_door/core/l10n/l_text.dart';
import 'package:the_door/core/utils/audio_manager.dart';
import 'package:the_door/core/utils/game_storage.dart';
import 'package:the_door/game/data/game_data.dart';
import 'package:the_door/game/logic/game_controller.dart';
import 'package:the_door/game/logic/game_effect.dart';
import 'package:the_door/game/logic/game_state.dart';
import 'package:the_door/game/logic/hints.dart';
import 'package:the_door/game/models/clue.dart';
import 'package:the_door/game/models/game_object.dart';
import 'package:the_door/game/models/inventory_item.dart';
import 'package:the_door/game/models/level.dart';
import 'package:the_door/game/models/puzzle.dart';

/// Room numbers, looked up by kind so reordering rooms never breaks tests.
int _number(RoomKind kind) =>
    GameData.levels.firstWhere((l) => l.kind == kind).number;

/// Starts a controller in [level] with the intro already finished.
Future<(GameController, List<GameEffect>)> _room(
  int level, {
  GameStorage? storage,
}) async {
  final game = GameController(
    storage: storage ?? GameStorage.memory(),
    startLevel: level,
  );
  final effects = <GameEffect>[];
  game.effects.listen(effects.add);
  await game.enterLevel(level);
  game.beginLevel();
  return (game, effects);
}

/// Same as [_room], inside a widget test where timers are fake.
Future<(GameController, List<GameEffect>)> _fakeRoom(
  WidgetTester tester,
  int level,
) async {
  late GameController game;
  await tester.runAsync(() async {
    game = GameController(storage: GameStorage.memory(), startLevel: level);
    await game.enterLevel(level);
  });
  final effects = <GameEffect>[];
  game.effects.listen(effects.add);
  game.beginLevel();
  return (game, effects);
}

Iterable<HorrorKind> _horrors(List<GameEffect> effects) =>
    effects.whereType<HorrorEffect>().map((e) => e.kind);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('eleven rooms, every kind once, the knock is the last one', () {
    expect(GameData.levelCount, 11);
    expect(GameData.levels.last.kind, RoomKind.knock);
    expect(GameData.levels.map((l) => l.number), [
      for (var i = 1; i <= 11; i++) i,
    ]);
    expect(
      GameData.levels.map((l) => l.kind).toList(),
      unorderedEquals(RoomKind.values),
    );
  });

  group('THE RULE', () {
    test('ignores taps before the intro has finished', () async {
      final game = GameController(storage: GameStorage.memory());
      game.interact(ObjectId.note);
      expect(game.state.discoveredClues, isEmpty);
      await game.close();
    });

    test('note reveals the first rule', () async {
      final (game, effects) = await _room(1);
      game.interact(ObjectId.note);
      await _flush();
      expect(game.state.knows(ClueId.firstRule), isTrue);
      expect(effects.whereType<ClueEffect>().single.clue.id, ClueId.firstRule);
      await game.close();
    });

    test('lamp asks first, and turning it on is not fatal', () async {
      final (game, effects) = await _room(1);
      game.interact(ObjectId.lamp);
      await _flush();
      expect(effects.whereType<ChoiceEffect>(), hasLength(1));
      game.choose(ChoiceAction.turnOnLamp);
      await _flush();
      expect(game.state.lampOn, isTrue);
      expect(_horrors(effects), contains(HorrorKind.lampShadow));
      expect(game.state.isOver, isFalse);
      await game.close();
    });

    test('drawer gives the code once; tapping it many times is safe', () async {
      final (game, _) = await _room(1);
      for (var i = 0; i < 7; i++) {
        game.interact(ObjectId.drawer);
      }
      expect(game.state.has(ItemId.drawerCode), isTrue);
      expect(game.state.inventory, hasLength(1));
      await game.close();
    });

    test('wrong code is rejected; 317 opens the door and saves', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await GameStorage.open();
      final (game, effects) = await _room(1, storage: storage);

      expect(game.submitCode('123'), isFalse);
      await _flush();
      expect(_horrors(effects), contains(HorrorKind.wrongCode));
      expect(game.state.doorUnlocked, isFalse);

      expect(game.submitCode('317'), isTrue);
      await _flush();
      expect(game.state.doorUnlocked, isTrue);
      expect(effects.whereType<DoorOpenEffect>(), hasLength(1));
      expect(storage.savedLevel, 2);
      expect(storage.completedLevels, contains(1));

      await game.goToNextLevel();
      expect(game.state.currentLevel, 2);
      expect(game.state.inventory, isEmpty);
      await game.close();
    });
  });

  group("DON'T LOOK", () {
    test(
      'mirror before midnight reveals the painting; key opens the door',
      () async {
        final (game, effects) = await _room(_number(RoomKind.mirror));
        game.interact(ObjectId.painting);
        expect(game.state.has(ItemId.paintingKey), isFalse);

        game.interact(ObjectId.mirror);
        expect(game.state.knows(ClueId.mirrorReflection), isTrue);
        game.interact(ObjectId.painting);
        expect(game.state.has(ItemId.paintingKey), isTrue);

        game.interact(ObjectId.door);
        await _flush();
        expect(effects.whereType<DoorOpenEffect>(), hasLength(1));
        await game.close();
      },
    );

    testWidgets('the clock strikes twelve; the mirror is no longer safe', (
      tester,
    ) async {
      final (game, effects) = await _fakeRoom(tester, _number(RoomKind.mirror));
      await tester.pump(
        const Duration(seconds: 8 * GameTimings.secondsPerClockMinute + 1),
      );
      expect(game.state.midnightPassed, isTrue);

      game.interact(ObjectId.mirror);
      await tester.pump(const Duration(seconds: 3));
      expect(
        _horrors(effects),
        containsAll([HorrorKind.midnight, HorrorKind.mirrorApparition]),
      );
      game.interact(ObjectId.painting);
      expect(game.state.has(ItemId.paintingKey), isTrue);
      await game.close();
    });
  });

  group('THE CANDLES', () {
    testWidgets('wrong order blows them all out; the right order opens', (
      tester,
    ) async {
      final (game, effects) = await _fakeRoom(
        tester,
        _number(RoomKind.candles),
      );

      game.interact(ObjectId.candleA); // MARTA (1961) first is wrong
      expect(game.state.litCandles, [ObjectId.candleA]);
      await tester.pump(const Duration(seconds: 2));
      expect(game.state.litCandles, isEmpty);
      expect(_horrors(effects), contains(HorrorKind.candlesOut));

      game.interact(ObjectId.door);
      await tester.pump();
      expect(effects.whereType<DoorOpenEffect>(), isEmpty);

      // ELIAS 1948 → MARTA 1961 → ANNA 1979
      game.interact(ObjectId.candleB);
      game.interact(ObjectId.candleA);
      game.interact(ObjectId.candleC);
      await tester.pump(const Duration(seconds: 2));
      expect(game.state.litCandles, hasLength(3));

      game.interact(ObjectId.door);
      await tester.pump();
      expect(effects.whereType<DoorOpenEffect>(), hasLength(1));
      await game.close();
    });
  });

  group('HIDE', () {
    testWidgets('caught in the open, safe in the wardrobe, then the key', (
      tester,
    ) async {
      final (game, effects) = await _fakeRoom(tester, _number(RoomKind.hide));

      // First blackout: standing in the room.
      await tester.pump(
        GameTimings.blackoutFirst + GameTimings.blackoutWarning,
      );
      expect(game.state.lightsOut, isTrue);
      await tester.pump(GameTimings.blackoutGrace + GameTimings.caught);
      expect(_horrors(effects), contains(HorrorKind.caught));
      expect(game.state.lightsOut, isFalse);
      expect(game.state.keyRevealed, isFalse);

      // Second blackout: hidden.
      game.interact(ObjectId.wardrobe);
      expect(game.state.hidden, isTrue);
      game.interact(ObjectId.door);
      expect(
        game.state.timesTouched(ObjectId.door),
        0,
        reason: 'no taps while hidden',
      );

      await tester.pump(
        GameTimings.blackoutRepeat + GameTimings.blackoutWarning,
      );
      await tester.pump(GameTimings.blackoutGrace + GameTimings.passBy);
      expect(_horrors(effects), contains(HorrorKind.passBy));
      expect(game.state.keyRevealed, isTrue);
      expect(game.state.hidden, isFalse, reason: 'steps out once it is gone');

      game.interact(ObjectId.floorKey);
      expect(game.state.has(ItemId.ironKey), isTrue);
      game.interact(ObjectId.door);
      await tester.pump();
      expect(effects.whereType<DoorOpenEffect>(), hasLength(1));
      await game.close();
    });
  });

  group("DON'T ANSWER", () {
    test(
      'the dial cycles stations; answering is punished; 409 opens',
      () async {
        final (game, effects) = await _room(_number(RoomKind.radio));
        game.interact(ObjectId.radio);
        expect(game.state.radioStation, 1);
        game.interact(ObjectId.radio);
        expect(game.state.knows(ClueId.radioNumbers), isTrue);
        game.interact(ObjectId.radio);
        await _flush();
        expect(effects.whereType<ChoiceEffect>(), hasLength(1));

        game.choose(ChoiceAction.answerCaller);
        await _flush();
        expect(_horrors(effects), contains(HorrorKind.radioScream));
        expect(game.state.isOver, isFalse);

        expect(game.submitCode('317'), isFalse);
        expect(game.submitCode('409'), isTrue);
        await game.close();
      },
    );
  });

  group('THE LULLABY', () {
    testWidgets('the doll lets go only while the music plays', (tester) async {
      final (game, effects) = await _fakeRoom(
        tester,
        _number(RoomKind.lullaby),
      );
      game.interact(ObjectId.doll);
      expect(game.state.dollFingers, 0, reason: 'nothing gives in the quiet');

      game.interact(ObjectId.note);
      await tester.pump(
        GameTimings.musicAfterNote + const Duration(milliseconds: 100),
      );
      expect(game.state.musicPlaying, isTrue, reason: 'it starts by itself');
      expect(effects.whereType<LoopEffect>().last.sfx, Sfx.musicBox);

      game.interact(ObjectId.doll);
      game.interact(ObjectId.doll);
      expect(game.state.dollFingers, 2);

      // The music stops. Moving now undoes the work.
      await tester.pump(
        GameTimings.musicLengths.first +
            GameTimings.stillnessGrace +
            const Duration(milliseconds: 50),
      );
      expect(game.state.stillness, isTrue);
      expect(game.state.dollSpot, 1, reason: 'it came closer');
      game.interact(ObjectId.doll);
      await tester.pump();
      expect(_horrors(effects), contains(HorrorKind.dollCaught));
      expect(game.state.dollFingers, 0);

      // The music comes back on its own.
      await tester.pump(GameTimings.stillness);
      expect(game.state.musicPlaying, isTrue);
      for (var i = 0; i < 3; i++) {
        game.interact(ObjectId.doll);
      }
      expect(game.state.has(ItemId.dollKey), isTrue);

      game.interact(ObjectId.door);
      await tester.pump();
      expect(effects.whereType<DoorOpenEffect>(), hasLength(1));
      expect(
        effects.whereType<LoopEffect>().last.sfx,
        isNull,
        reason: 'the music stops when the door opens',
      );
      await game.close();
    });
  });

  group('THE PORTRAITS', () {
    test('only one story fits: Marta lies, the key is behind Elias', () async {
      final (game, effects) = await _room(_number(RoomKind.portraits));

      game.interact(ObjectId.portraitMarta);
      await _flush();
      expect(
        effects.whereType<ChoiceEffect>().last.choice.body.en,
        contains('Anna'),
      );
      game.choose(ChoiceAction.lookBehind);
      await _flush();
      expect(_horrors(effects), contains(HorrorKind.impostor));
      expect(game.state.has(ItemId.portraitKey), isFalse);

      game.interact(ObjectId.portraitAnna);
      game.choose(ChoiceAction.lookBehind);
      expect(game.state.has(ItemId.portraitKey), isFalse);

      game.interact(ObjectId.portraitElias);
      game.choose(ChoiceAction.lookBehind);
      expect(game.state.has(ItemId.portraitKey), isTrue);

      game.interact(ObjectId.door);
      await _flush();
      expect(effects.whereType<DoorOpenEffect>(), hasLength(1));
      await game.close();
    });

    test('stepping back touches nothing', () async {
      final (game, _) = await _room(_number(RoomKind.portraits));
      game.interact(ObjectId.portraitElias);
      game.choose(ChoiceAction.leavePortrait);
      game.choose(ChoiceAction.lookBehind);
      expect(game.state.lookedBehind, isEmpty);
      expect(game.state.has(ItemId.portraitKey), isFalse);
      await game.close();
    });

    test('exactly one of them can be the liar', () {
      // Elias: "Marta is not Marta." Marta: "Behind Anna." Anna: "Behind
      // Elias." Try every liar and every hiding place.
      final fits = <(String, String)>[];
      for (final liar in ['elias', 'marta', 'anna']) {
        for (final key in ['elias', 'marta', 'anna']) {
          final says = {
            'elias': liar == 'marta',
            'marta': key == 'anna',
            'anna': key == 'elias',
          };
          final consistent = says.entries.every(
            (e) => e.value == (e.key != liar),
          );
          if (consistent) fits.add((liar, key));
        }
      }
      expect(fits, [('marta', 'elias')]);
    });
  });

  group('THE BELLS', () {
    testWidgets('three rounds, one bell longer each time', (tester) async {
      final (game, effects) = await _fakeRoom(tester, _number(RoomKind.bells));
      await tester.pump(
        GameTimings.bellsFirst + const Duration(milliseconds: 50),
      );
      var tune = effects.whereType<PatternEffect>().last.bells;
      expect(tune, hasLength(3));

      game.interact(tune.first);
      expect(game.state.bellInput, isEmpty, reason: 'not listening yet');

      // A wrong bell: something comes down the stairs, then the same tune.
      game.patternShown();
      game.interact(ObjectId.bellB);
      await tester.pump();
      expect(_horrors(effects), contains(HorrorKind.wrongBell));
      await tester.pump(GameTimings.bellsRetry);
      expect(effects.whereType<PatternEffect>(), hasLength(2));

      for (final length in [3, 4, 5]) {
        tune = effects.whereType<PatternEffect>().last.bells;
        expect(tune, hasLength(length));
        expect(tune.take(3), [ObjectId.bellC, ObjectId.bellA, ObjectId.bellD]);
        game.patternShown();
        for (final bell in tune) {
          game.interact(bell);
        }
        await tester.pump(
          GameTimings.bellsNextRound + const Duration(milliseconds: 50),
        );
      }
      expect(game.state.puzzles[PuzzleId.bellPattern]!.solved, isTrue);

      game.interact(ObjectId.door);
      await tester.pump();
      expect(effects.whereType<DoorOpenEffect>(), hasLength(1));
      await game.close();
    });

    testWidgets('nobody answering brings footsteps, then the tune again', (
      tester,
    ) async {
      final (game, effects) = await _fakeRoom(tester, _number(RoomKind.bells));
      await tester.pump(
        GameTimings.bellsFirst + const Duration(milliseconds: 50),
      );
      game.patternShown();
      await tester.pump(
        GameTimings.bellAnswer + const Duration(milliseconds: 50),
      );
      expect(_horrors(effects), contains(HorrorKind.footsteps));
      expect(game.state.bellsListening, isFalse);
      await tester.pump(GameTimings.bellsRetry);
      expect(effects.whereType<PatternEffect>(), hasLength(2));
      await game.close();
    });
  });

  group('THE DINNER', () {
    testWidgets('a place for the guest clears the table', (tester) async {
      final (game, effects) = await _fakeRoom(tester, _number(RoomKind.dinner));
      game.interact(ObjectId.seatA);
      game.interact(GameData.guestSeat);
      await tester.pump();
      expect(_horrors(effects), contains(HorrorKind.guestSits));
      game.interact(ObjectId.seatB);
      expect(
        game.state.setPlaces,
        isNot(contains(ObjectId.seatB)),
        reason: 'the table cannot be touched while it sits down',
      );
      await tester.pump(GameTimings.guestSits);
      expect(game.state.setPlaces, isEmpty);
      await game.close();
    });

    testWidgets('the family and the card with no name open the door', (
      tester,
    ) async {
      final (game, effects) = await _fakeRoom(tester, _number(RoomKind.dinner));
      bool solved() => game.state.puzzles[PuzzleId.dinnerTable]!.solved;

      for (final seat in [ObjectId.seatA, ObjectId.seatB, ObjectId.seatD]) {
        game.interact(seat);
      }
      expect(solved(), isFalse, reason: 'someone is still standing');
      game.interact(ObjectId.door);
      await tester.pump();
      expect(effects.whereType<DoorOpenEffect>(), isEmpty);

      game.interact(ObjectId.seatB);
      expect(game.state.setPlaces, isNot(contains(ObjectId.seatB)));
      game.interact(ObjectId.seatB);
      game.interact(GameData.blankSeat);
      expect(solved(), isTrue);
      await tester.pump(const Duration(seconds: 2));

      game.interact(ObjectId.door);
      await tester.pump();
      expect(effects.whereType<DoorOpenEffect>(), hasLength(1));
      await game.close();
    });
  });

  group('THE HANDWRITING', () {
    testWidgets('41 opens the diary; the key inside opens the door', (
      tester,
    ) async {
      final (game, effects) = await _fakeRoom(tester, _number(RoomKind.study));
      for (final id in [ObjectId.tally, ObjectId.desk, ObjectId.floorboard]) {
        game.interact(id);
      }
      expect(game.state.knows(ClueId.marksFloor), isTrue);

      game.interact(ObjectId.diary);
      await tester.pump();
      final lock = effects.whereType<KeypadEffect>().last.puzzle;
      expect(lock.id, PuzzleId.diaryLock);
      expect(game.submitCode('40', id: lock.id), isFalse);
      expect(game.submitCode('41', id: lock.id), isTrue);
      expect(game.state.has(ItemId.diary), isTrue);
      expect(game.state.has(ItemId.studyKey), isTrue);
      expect(
        game.state.doorUnlocked,
        isFalse,
        reason: 'the diary is not the door',
      );

      await tester.pump(GameTimings.afterKeypad);
      expect(effects.whereType<ClueEffect>().last.clue.id, ClueId.diaryPages);

      game.interact(ObjectId.door);
      await tester.pump();
      expect(effects.whereType<DoorOpenEffect>(), hasLength(1));
      await game.close();
    });

    test('the pen tells you whose handwriting it is', () async {
      final (game, effects) = await _room(_number(RoomKind.study));
      game.interact(ObjectId.inkwell);
      game.interact(ObjectId.inkwell);
      await _flush();
      expect(_horrors(effects), contains(HorrorKind.handwriting));
      await game.close();
    });
  });

  group('THE KNOCK', () {
    testWidgets('knock → phone → key under the clock → bad ending', (
      tester,
    ) async {
      final (game, effects) = await _fakeRoom(tester, _number(RoomKind.knock));

      game.interact(ObjectId.phone);
      expect(game.state.knows(ClueId.phoneMessages), isFalse);

      await tester.pump(
        GameTimings.firstKnockDelay + const Duration(milliseconds: 100),
      );
      expect(game.state.knockingStarted, isTrue);

      game.interact(ObjectId.phone);
      game.interact(ObjectId.clock);
      expect(game.state.has(ItemId.key), isTrue);
      await tester.pump(
        GameTimings.knockAfterKey + const Duration(milliseconds: 100),
      );
      expect(_horrors(effects), contains(HorrorKind.heavyKnock));

      game.interact(ObjectId.door);
      await tester.pump();
      final choice = effects.whereType<ChoiceEffect>().last.choice;
      expect(
        choice.options.map((o) => o.action),
        isNot(contains(ChoiceAction.lockDoor)),
      );

      game.choose(ChoiceAction.openDoor);
      await tester.pump();
      expect(game.state.ending, GameEnding.bad);
      await game.close();
    });

    testWidgets('the window stops the knocking and allows the good ending', (
      tester,
    ) async {
      final (game, effects) = await _fakeRoom(tester, _number(RoomKind.knock));
      await tester.pump(
        GameTimings.firstKnockDelay + const Duration(milliseconds: 100),
      );
      game.interact(ObjectId.phone);
      game.interact(ObjectId.clock);
      await tester.pump(
        GameTimings.knockAfterKey + const Duration(milliseconds: 100),
      );

      game.interact(ObjectId.window);
      final knocks = _horrors(
        effects,
      ).where((k) => k == HorrorKind.heavyKnock).length;
      await tester.pump(GameTimings.knockRepeat * 2);
      expect(
        _horrors(effects).where((k) => k == HorrorKind.heavyKnock).length,
        knocks,
      );

      game.interact(ObjectId.door);
      await tester.pump();
      expect(
        effects.whereType<ChoiceEffect>().last.choice.options.map(
          (o) => o.action,
        ),
        contains(ChoiceAction.lockDoor),
      );
      game.choose(ChoiceAction.lockDoor);
      await tester.pump();
      expect(game.state.ending, GameEnding.good);
      await game.close();
    });
  });

  group('Saving inside a room', () {
    test('leaving and continuing restores the room as it was', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await GameStorage.open();

      final (first, _) = await _room(1, storage: storage);
      first.interact(ObjectId.note);
      first.interact(ObjectId.drawer);
      first.choose(ChoiceAction.turnOnLamp);
      await first.close(); // flushes the pending save

      final second = GameController(storage: storage, startLevel: 1);
      await second.start(level: 1);
      expect(second.state.has(ItemId.drawerCode), isTrue);
      expect(second.state.knows(ClueId.firstRule), isTrue);
      expect(second.state.drawerOpen, isTrue);
      expect(second.state.lampOn, isTrue);
      expect(second.state.levelStarted, isFalse, reason: 'intro plays again');
      await second.close();
    });

    test('PLAY starts clean even with a saved room', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await GameStorage.open();
      final (first, _) = await _room(1, storage: storage);
      first.interact(ObjectId.drawer);
      await first.close();

      final second = GameController(storage: storage);
      await second.start(level: 1, fresh: true);
      expect(second.state.inventory, isEmpty);
      await second.close();
    });

    test('candle order survives a restart', () async {
      final room = _number(RoomKind.candles);
      final saved = GameState.forLevel(
        GameData.level(room),
      ).copyWith(litCandles: [ObjectId.candleB, ObjectId.candleA]);
      final restored = GameState.fromJson(saved.toJson())!;
      expect(restored.litCandles, [ObjectId.candleB, ObjectId.candleA]);
    });

    test('the new rooms survive a restart, calmly', () {
      GameState fresh(RoomKind kind) =>
          GameState.forLevel(GameData.level(_number(kind)));
      GameState again(GameState s) => GameState.fromJson(s.toJson())!;

      final lullaby = again(
        fresh(RoomKind.lullaby).copyWith(
          musicWound: true,
          musicPlaying: true,
          stillness: true,
          dollFingers: 2,
          dollSpot: 1,
        ),
      );
      expect(lullaby.musicWound, isTrue);
      expect(lullaby.musicPlaying, isFalse);
      expect(lullaby.stillness, isFalse);
      expect(lullaby.dollFingers, 2);
      expect(lullaby.dollSpot, 1);

      final bells = again(
        fresh(RoomKind.bells).copyWith(
          bellRound: 2,
          bellInput: [ObjectId.bellC],
          bellsListening: true,
        ),
      );
      expect(bells.bellRound, 2);
      expect(bells.bellInput, isEmpty);
      expect(bells.bellsListening, isFalse);

      final portraits = again(
        fresh(
          RoomKind.portraits,
        ).copyWith(lookedBehind: {ObjectId.portraitAnna}),
      );
      expect(portraits.lookedBehind, {ObjectId.portraitAnna});

      final dinner = again(
        fresh(
          RoomKind.dinner,
        ).copyWith(setPlaces: {ObjectId.seatA, ObjectId.seatE}),
      );
      expect(dinner.setPlaces, {ObjectId.seatA, ObjectId.seatE});

      final study = fresh(RoomKind.study);
      final diary = study.puzzles[PuzzleId.diaryLock]!;
      final opened = again(
        study.copyWith(puzzles: {...study.puzzles, diary.id: diary.solve()}),
      );
      expect(opened.puzzles[PuzzleId.diaryLock]!.solved, isTrue);
      expect(opened.puzzles[PuzzleId.studyLock]!.solved, isFalse);
    });

    test('saves from before the new rooms are not restored', () {
      expect(GameState.fromJson({'level': 1, 'inventory': <String>[]}), isNull);
    });

    test('broken or foreign data is ignored safely', () {
      expect(GameState.fromJson({'level': 'x'}), isNull);
      expect(GameState.fromJson({'level': 99}), isNull);
      final s = GameState.fromJson({
        'version': GameState.saveVersion,
        'level': 1,
        'inventory': ['drawerCode', 'somethingFromTheFuture'],
        'touched': {'drawer': 2, 'ghost': 1, 'lamp': 'x'},
      })!;
      expect(s.inventory, {ItemId.drawerCode});
      expect(s.interactionCounts, {ObjectId.drawer: 2});
    });
  });

  group('Hints', () {
    test('follow the player through a room', () async {
      final level = GameData.level(1);
      var s = GameState.forLevel(level);
      expect(hintFor(level, s).en, contains('note'));
      s = s.copyWith(discoveredClues: {ClueId.firstRule});
      expect(hintFor(level, s).en, contains('drawers'));
      s = s.copyWith(inventory: {ItemId.drawerCode});
      expect(hintFor(level, s).en, contains('three numbers'));
    });

    test('the new rooms nudge the player step by step', () {
      final dinner = GameData.level(_number(RoomKind.dinner));
      var s = GameState.forLevel(
        dinner,
      ).copyWith(discoveredClues: {dinner.note});
      expect(hintFor(dinner, s).en, contains('dead'));
      s = s.copyWith(
        setPlaces: {ObjectId.seatA, ObjectId.seatB, ObjectId.seatD},
      );
      expect(hintFor(dinner, s).en, contains('no name'));

      final study = GameData.level(_number(RoomKind.study));
      s = GameState.forLevel(study).copyWith(discoveredClues: {study.note});
      expect(hintFor(study, s).en, contains('wall'));
      s = s.copyWith(
        discoveredClues: {
          study.note,
          ClueId.marksWall,
          ClueId.marksDesk,
          ClueId.marksFloor,
        },
      );
      expect(hintFor(study, s).en, contains('Add'));

      final lullaby = GameData.level(_number(RoomKind.lullaby));
      s = GameState.forLevel(lullaby).copyWith(discoveredClues: {lullaby.note});
      expect(hintFor(lullaby, s).en, contains('music box'));
      s = s.copyWith(musicWound: true, dollFingers: 1);
      expect(hintFor(lullaby, s).en, contains('stops'));
    });

    testWidgets('the hint starts to glow when the player is stuck', (
      tester,
    ) async {
      final (game, effects) = await _fakeRoom(tester, 1);
      await tester.pump(GameTimings.stuckAfter + const Duration(seconds: 1));
      expect(game.state.hintReady, isTrue);

      game.requestHint();
      await tester.pump();
      expect(game.state.hintReady, isFalse);
      expect(effects.whereType<MessageEffect>(), isNotEmpty);
      await game.close();
    });
  });

  test('every text has both languages', () {
    final texts = <LText>[
      for (final c in GameData.clues.values) ...[c.title, ...c.lines],
      for (final l in GameData.levels) ...[
        l.title,
        l.epigraph,
        l.lockedMessage,
        l.code,
        for (final o in l.objects) o.label,
      ],
      for (final i in GameData.items.values) ...[i.name, i.description],
      ...GameData.portraitWords.values,
      ...GameData.bellRooms.values,
      for (final e in GameData.seatCards.entries)
        if (e.key != GameData.blankSeat) e.value,
    ];
    for (final t in texts) {
      expect(t.en.trim(), isNotEmpty);
      expect(t.uz.trim(), isNotEmpty);
    }
    expect(GameData.level(1).code.of(AppLanguage.uz), 'XONA 01');
  });

  test('a corrupted or missing save falls back to a real room', () {
    expect(GameController.resolveLevel(null), 1);
    expect(GameController.resolveLevel(-4), 1);
    expect(GameController.resolveLevel(99), GameData.levelCount);
  });

  test('wrong-typed preference values do not crash', () async {
    SharedPreferences.setMockInitialValues({
      'the_door.current_level': 'oops',
      'the_door.room_progress': '{not json',
    });
    final storage = await GameStorage.open();
    expect(storage.savedLevel, isNull);
    expect(storage.soundEnabled, isTrue);

    final game = GameController(storage: storage);
    await game.start(level: 1);
    expect(game.state.currentLevel, 1);
    await game.close();
    unawaited(storage.resetProgress());
  });
}
