import 'package:flutter/foundation.dart';

import '../data/game_data.dart';
import '../models/clue.dart';
import '../models/game_object.dart';
import '../models/inventory_item.dart';
import '../models/level.dart';
import '../models/puzzle.dart';

enum GameEnding { none, good, bad }

/// Immutable snapshot of one room in progress.
@immutable
class GameState {
  const GameState({
    required this.currentLevel,
    required this.inventory,
    required this.discoveredClues,
    required this.interactionCounts,
    required this.puzzles,
    required this.clockMinutes,
    this.levelStarted = false,
    this.doorUnlocked = false,
    this.hintReady = false,
    this.lampOn = false,
    this.lampEventSeen = false,
    this.drawerOpen = false,
    this.clockRunning = false,
    this.midnightPassed = false,
    this.mirrorTriggered = false,
    this.paintingMoved = false,
    this.litCandles = const [],
    this.lightsFlickering = false,
    this.lightsOut = false,
    this.hidden = false,
    this.keyRevealed = false,
    this.radioStation = 0,
    this.callerHeard = false,
    this.musicWound = false,
    this.musicPlaying = false,
    this.stillness = false,
    this.dollFingers = 0,
    this.dollSpot = 0,
    this.lookedBehind = const {},
    this.bellRound = 0,
    this.bellInput = const [],
    this.bellsListening = false,
    this.setPlaces = const {},
    this.knockingStarted = false,
    this.isKnocking = false,
    this.ending = GameEnding.none,
  });

  /// A fresh, untouched room.
  factory GameState.forLevel(Level level) => GameState(
    currentLevel: level.number,
    inventory: const {},
    discoveredClues: const {},
    interactionCounts: const {},
    puzzles: {
      level.doorPuzzle.id: level.doorPuzzle,
      for (final p in level.sidePuzzles) p.id: p,
    },
    clockMinutes: level.clockMinutes,
  );

  /// Bumped whenever rooms change in a way old saves cannot follow.
  static const saveVersion = 2;

  final int currentLevel;
  final Set<ItemId> inventory;
  final Set<ClueId> discoveredClues;
  final Map<ObjectId, int> interactionCounts;
  final Map<PuzzleId, Puzzle> puzzles;

  /// Timers (clock, knocking, blackouts) run only after the intro card.
  final bool levelStarted;
  final bool doorUnlocked;

  /// The player seems stuck: the hint button starts to glow.
  final bool hintReady;

  // The rule
  final bool lampOn;
  final bool lampEventSeen;
  final bool drawerOpen;

  // The mirror (and the static clocks of the other rooms)
  final int clockMinutes;
  final bool clockRunning;
  final bool midnightPassed;
  final bool mirrorTriggered;
  final bool paintingMoved;

  // The candles
  final List<ObjectId> litCandles;

  // Hide
  final bool lightsFlickering;
  final bool lightsOut;
  final bool hidden;
  final bool keyRevealed;

  // The radio — 0 = off, 1 = static, 2 = numbers, 3 = the caller.
  final int radioStation;
  final bool callerHeard;

  // The lullaby
  /// The music box has been started at least once.
  final bool musicWound;
  final bool musicPlaying;

  /// The music has stopped: touching anything now is "moving".
  final bool stillness;

  /// How many of the doll's fingers have been pried open (0..3).
  final int dollFingers;

  /// Where the doll is (0 = on the dresser … 2 = right in front of you).
  final int dollSpot;

  // The portraits
  final Set<ObjectId> lookedBehind;

  // The bells
  /// Rounds of the bell tune answered correctly.
  final int bellRound;
  final List<ObjectId> bellInput;

  /// The tune has been played; the player may now answer it.
  final bool bellsListening;

  // The dinner
  final Set<ObjectId> setPlaces;

  // The knock
  final bool knockingStarted;
  final bool isKnocking;
  final GameEnding ending;

  Set<ObjectId> get interactedObjects => interactionCounts.keys.toSet();

  int timesTouched(ObjectId id) => interactionCounts[id] ?? 0;

  bool has(ItemId item) => inventory.contains(item);

  bool knows(ClueId clue) => discoveredClues.contains(clue);

  bool get isOver => ending != GameEnding.none;

  /// Clock time as "HH:MM".
  String get clockLabel {
    final h = (clockMinutes ~/ 60) % 24;
    final m = clockMinutes % 60;
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${hour.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  GameState copyWith({
    Set<ItemId>? inventory,
    Set<ClueId>? discoveredClues,
    Map<ObjectId, int>? interactionCounts,
    Map<PuzzleId, Puzzle>? puzzles,
    bool? levelStarted,
    bool? doorUnlocked,
    bool? hintReady,
    bool? lampOn,
    bool? lampEventSeen,
    bool? drawerOpen,
    int? clockMinutes,
    bool? clockRunning,
    bool? midnightPassed,
    bool? mirrorTriggered,
    bool? paintingMoved,
    List<ObjectId>? litCandles,
    bool? lightsFlickering,
    bool? lightsOut,
    bool? hidden,
    bool? keyRevealed,
    int? radioStation,
    bool? callerHeard,
    bool? musicWound,
    bool? musicPlaying,
    bool? stillness,
    int? dollFingers,
    int? dollSpot,
    Set<ObjectId>? lookedBehind,
    int? bellRound,
    List<ObjectId>? bellInput,
    bool? bellsListening,
    Set<ObjectId>? setPlaces,
    bool? knockingStarted,
    bool? isKnocking,
    GameEnding? ending,
  }) {
    return GameState(
      currentLevel: currentLevel,
      inventory: Set.unmodifiable(inventory ?? this.inventory),
      discoveredClues: Set.unmodifiable(
        discoveredClues ?? this.discoveredClues,
      ),
      interactionCounts: Map.unmodifiable(
        interactionCounts ?? this.interactionCounts,
      ),
      puzzles: Map.unmodifiable(puzzles ?? this.puzzles),
      levelStarted: levelStarted ?? this.levelStarted,
      doorUnlocked: doorUnlocked ?? this.doorUnlocked,
      hintReady: hintReady ?? this.hintReady,
      lampOn: lampOn ?? this.lampOn,
      lampEventSeen: lampEventSeen ?? this.lampEventSeen,
      drawerOpen: drawerOpen ?? this.drawerOpen,
      clockMinutes: clockMinutes ?? this.clockMinutes,
      clockRunning: clockRunning ?? this.clockRunning,
      midnightPassed: midnightPassed ?? this.midnightPassed,
      mirrorTriggered: mirrorTriggered ?? this.mirrorTriggered,
      paintingMoved: paintingMoved ?? this.paintingMoved,
      litCandles: List.unmodifiable(litCandles ?? this.litCandles),
      lightsFlickering: lightsFlickering ?? this.lightsFlickering,
      lightsOut: lightsOut ?? this.lightsOut,
      hidden: hidden ?? this.hidden,
      keyRevealed: keyRevealed ?? this.keyRevealed,
      radioStation: radioStation ?? this.radioStation,
      callerHeard: callerHeard ?? this.callerHeard,
      musicWound: musicWound ?? this.musicWound,
      musicPlaying: musicPlaying ?? this.musicPlaying,
      stillness: stillness ?? this.stillness,
      dollFingers: dollFingers ?? this.dollFingers,
      dollSpot: dollSpot ?? this.dollSpot,
      lookedBehind: Set.unmodifiable(lookedBehind ?? this.lookedBehind),
      bellRound: bellRound ?? this.bellRound,
      bellInput: List.unmodifiable(bellInput ?? this.bellInput),
      bellsListening: bellsListening ?? this.bellsListening,
      setPlaces: Set.unmodifiable(setPlaces ?? this.setPlaces),
      knockingStarted: knockingStarted ?? this.knockingStarted,
      isKnocking: isKnocking ?? this.isKnocking,
      ending: ending ?? this.ending,
    );
  }

  // ---------------------------------------------------------------- saving

  /// Everything needed to resume the room later. Moment-to-moment states
  /// (a blackout in progress, knocking right now, hiding, the music playing,
  /// a half-answered bell tune) are left out: the room's timers restart
  /// from a calm moment instead.
  Map<String, Object?> toJson() => {
    'version': saveVersion,
    'level': currentLevel,
    'inventory': [for (final i in inventory) i.name],
    'clues': [for (final c in discoveredClues) c.name],
    'touched': {for (final e in interactionCounts.entries) e.key.name: e.value},
    'solved': [
      for (final p in puzzles.values)
        if (p.solved) p.id.name,
    ],
    'lampOn': lampOn,
    'lampEventSeen': lampEventSeen,
    'drawerOpen': drawerOpen,
    'clockMinutes': clockMinutes,
    'midnightPassed': midnightPassed,
    'mirrorTriggered': mirrorTriggered,
    'paintingMoved': paintingMoved,
    'litCandles': [for (final c in litCandles) c.name],
    'keyRevealed': keyRevealed,
    'radioStation': radioStation,
    'callerHeard': callerHeard,
    'musicWound': musicWound,
    'dollFingers': dollFingers,
    'dollSpot': dollSpot,
    'lookedBehind': [for (final o in lookedBehind) o.name],
    'bellRound': bellRound,
    'setPlaces': [for (final o in setPlaces) o.name],
    'knockingStarted': knockingStarted,
  };

  /// Rebuilds a saved room. Returns null if the data is unusable or was
  /// written for a different set of rooms. Unknown names are skipped.
  static GameState? fromJson(Map<String, Object?> json) {
    try {
      if (json['version'] != saveVersion) return null;
      final number = json['level'];
      if (number is! int || number < 1 || number > GameData.levelCount) {
        return null;
      }
      final level = GameData.level(number);
      final fresh = GameState.forLevel(level);

      Set<T> names<T extends Enum>(List<T> values, Object? raw) => {
        if (raw is List)
          for (final name in raw) ...values.where((v) => v.name == name),
      };
      bool flag(String key) => json[key] == true;
      int count(String key, int max) {
        final value = json[key];
        return value is int ? value.clamp(0, max) : 0;
      }

      final touched = json['touched'];
      final solved = names(PuzzleId.values, json['solved']);
      final minutes = json['clockMinutes'];

      return fresh.copyWith(
        inventory: names(ItemId.values, json['inventory']),
        discoveredClues: names(ClueId.values, json['clues']),
        interactionCounts: {
          if (touched is Map)
            for (final e in touched.entries)
              for (final id in ObjectId.values.where((o) => o.name == e.key))
                if (e.value is int) id: e.value as int,
        },
        puzzles: {
          for (final p in fresh.puzzles.values)
            p.id: solved.contains(p.id) ? p.solve() : p,
        },
        lampOn: flag('lampOn'),
        lampEventSeen: flag('lampEventSeen'),
        drawerOpen: flag('drawerOpen'),
        clockMinutes: minutes is int ? minutes : null,
        midnightPassed: flag('midnightPassed'),
        mirrorTriggered: flag('mirrorTriggered'),
        paintingMoved: flag('paintingMoved'),
        litCandles: names(ObjectId.values, json['litCandles']).toList(),
        keyRevealed: flag('keyRevealed'),
        radioStation: count('radioStation', 3),
        callerHeard: flag('callerHeard'),
        musicWound: flag('musicWound'),
        dollFingers: count('dollFingers', 3),
        dollSpot: count('dollSpot', GameData.dollSpots.length - 1),
        lookedBehind: names(ObjectId.values, json['lookedBehind']),
        bellRound: count('bellRound', 9),
        setPlaces: names(ObjectId.values, json['setPlaces']),
        knockingStarted: flag('knockingStarted'),
      );
    } catch (e) {
      debugPrint('GameState: could not restore room ($e)');
      return null;
    }
  }
}
