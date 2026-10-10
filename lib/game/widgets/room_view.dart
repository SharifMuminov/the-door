import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/settings_cubit.dart';
import '../../core/constants/game_timings.dart';
import '../../core/l10n/l_text.dart';
import '../data/game_data.dart';
import '../logic/game_state.dart';
import '../models/clue.dart';
import '../models/game_object.dart';
import '../models/inventory_item.dart';
import '../models/level.dart';
import '../models/puzzle.dart';
import 'door_widget.dart';
import 'interactive_object.dart';
import 'painters/furniture_painters.dart';
import 'painters/gallery_painters.dart';
import 'painters/nursery_painters.dart';
import 'painters/prop_painters.dart';
import 'painters/study_painters.dart';
import 'painters/wall_painters.dart';
import 'room_background.dart';
import 'room_layout.dart';
import 'servant_bell.dart';

/// The room: background, every object of the level, and a slow
/// "breathing" (scale + vignette) that makes the walls feel alive.
class RoomView extends StatefulWidget {
  const RoomView({
    super.key,
    required this.level,
    required this.state,
    required this.onObjectTap,
    required this.interactive,
    required this.doorOpen,
    required this.knockSeq,
    required this.mirrorApparition,
    this.ringing,
    this.ringSeq = 0,
  });

  final Level level;
  final GameState state;
  final ValueChanged<ObjectId> onObjectTap;
  final bool interactive;
  final bool doorOpen;
  final int knockSeq;
  final bool mirrorApparition;

  /// The bell that is ringing right now, and a counter that changes with
  /// every ring.
  final ObjectId? ringing;
  final int ringSeq;

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: GameTimings.breathing,
  )..repeat(reverse: true);

  /// Resolved once per build: LayoutBuilder callbacks run during layout,
  /// where looking up the language through the context is not allowed.
  AppLanguage _language = AppLanguage.en;

  String _tr(LText text) => text.of(_language);

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _language = context.language;
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = RoomLayout.of(constraints.biggest);
        return AnimatedBuilder(
          animation: _breath,
          builder: (context, room) {
            final b = Curves.easeInOut.transform(_breath.value);
            return Stack(
              fit: StackFit.expand,
              children: [
                Transform.scale(scale: 1 + .012 * b, child: room),
                RoomVignette(intensity: .85 + .15 * b),
              ],
            );
          },
          // Keyed by level so every object starts fresh in a new room.
          child: KeyedSubtree(
            key: ValueKey(widget.level.number),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RoomBackground(
                    layout: layout,
                    wallTint: widget.level.wallTint,
                    doorLight: widget.level.doorLight,
                    seed: widget.level.number,
                  ),
                ),
                for (final object in widget.level.objects)
                  _placed(object, layout.rectFor(_placementOf(object))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placed(GameObject object, Rect rect) {
    return Positioned.fromRect(
      rect: rect,
      child: InteractiveObject(
        id: object.id,
        semanticLabel: _tr(object.label),
        sound: object.tapSound,
        enabled: widget.interactive,
        visible: _isVisible(object.id),
        onTap: () => widget.onObjectTap(object.id),
        child: _visual(object, rect),
      ),
    );
  }

  /// Objects that move about the room (the doll) are placed by state.
  ObjectPlacement _placementOf(GameObject object) {
    if (object.id != ObjectId.doll) return object.placement;
    final spots = GameData.dollSpots;
    return spots[widget.state.dollSpot.clamp(0, spots.length - 1)];
  }

  bool _isVisible(ObjectId id) {
    final s = widget.state;
    return switch (id) {
      ObjectId.floorKey => s.keyRevealed && !s.has(ItemId.ironKey),
      _ => true,
    };
  }

  /// Maps an object + the current state to its drawing.
  Widget _visual(GameObject object, Rect rect) {
    final s = widget.state;
    final level = widget.level;
    final knockRoom = level.kind == RoomKind.knock;

    return switch (object.id) {
      ObjectId.door => DoorWidget(
        lightColor: level.doorLight,
        hasKeypad: level.doorPuzzle.type == PuzzleType.keypad,
        isOpen: widget.doorOpen,
        knockSeq: widget.knockSeq,
        presence:
            knockRoom && s.knockingStarted && !s.knows(ClueId.windowTruth),
        beyond: knockRoom ? DoorBeyond.dark : DoorBeyond.light,
      ),
      ObjectId.table => const CustomPaint(painter: TablePainter()),
      ObjectId.drawer => CustomPaint(
        painter: DrawerPainter(open: s.drawerOpen),
      ),
      ObjectId.chair => const CustomPaint(painter: ChairPainter()),
      ObjectId.note => CustomPaint(
        painter: NotePainter(seed: level.number * 7),
      ),
      ObjectId.painting => CustomPaint(
        painter: PaintingPainter(moved: s.paintingMoved),
      ),
      ObjectId.photo => const CustomPaint(painter: PhotoPainter()),
      ObjectId.wardrobe => CustomPaint(
        painter: WardrobePainter(occupied: s.hidden),
      ),
      ObjectId.calendar => CustomPaint(
        painter: CalendarPainter(
          month: _tr(GameData.calendarMonth),
          year: GameData.calendarYear,
        ),
      ),
      ObjectId.clock => LoopingPaint(
        animate: s.clockRunning,
        period: const Duration(seconds: GameTimings.secondsPerClockMinute),
        painter: (phase) => ClockPainter(
          minutes: s.clockMinutes,
          tabletop: object.style == ObjectStyle.tabletop,
          cracked: s.midnightPassed,
          sweep: s.clockRunning ? phase : null,
        ),
      ),
      ObjectId.lamp => LoopingPaint(
        animate: s.lampOn,
        period: const Duration(seconds: 3),
        painter: (phase) => LampPainter(on: s.lampOn, flicker: phase),
      ),
      ObjectId.mirror => LoopingPaint(
        animate: s.midnightPassed,
        period: const Duration(seconds: 5),
        painter: (phase) => MirrorPainter(
          distorted: s.midnightPassed,
          apparition: widget.mirrorApparition,
          phase: phase,
        ),
      ),
      ObjectId.candleA || ObjectId.candleB || ObjectId.candleC => LoopingPaint(
        animate: s.litCandles.contains(object.id),
        period: Duration(milliseconds: 2600 + object.id.index * 170),
        painter: (phase) => CandlePainter(
          lit:
              s.litCandles.contains(object.id) ||
              (s.puzzles[level.doorPuzzle.id]?.solved ?? false),
          phase: phase,
        ),
      ),
      ObjectId.bulb => LoopingPaint(
        animate: s.lightsFlickering,
        period: const Duration(seconds: 2),
        painter: (phase) => BulbPainter(
          cordLength: rect.top,
          on: !s.lightsOut,
          flickering: s.lightsFlickering,
          phase: phase,
        ),
      ),
      ObjectId.floorKey => LoopingPaint(
        period: const Duration(milliseconds: 1800),
        painter: (phase) => FloorKeyPainter(phase: phase),
      ),
      ObjectId.radio => LoopingPaint(
        animate: s.radioStation > 0,
        period: const Duration(seconds: 2),
        painter: (phase) => RadioPainter(station: s.radioStation, phase: phase),
      ),
      ObjectId.phone => _phone(s),
      ObjectId.window => LoopingPaint(
        animate: s.has(ItemId.key),
        period: const Duration(seconds: 4),
        painter: (phase) => WindowPainter(
          fogged: s.has(ItemId.key),
          writing: s.knows(ClueId.windowTruth)
              ? _tr(GameData.windowWriting)
              : null,
          phase: phase,
        ),
      ),
      // The lullaby
      ObjectId.cradle => LoopingPaint(
        animate: s.musicPlaying,
        period: const Duration(milliseconds: 3200),
        painter: (phase) => CradlePainter(
          rock: s.musicPlaying ? math.sin(phase * math.pi * 2) : 0,
        ),
      ),
      ObjectId.musicBox => LoopingPaint(
        animate: s.musicPlaying,
        period: const Duration(milliseconds: 2400),
        painter: (phase) =>
            MusicBoxPainter(playing: s.musicPlaying, phase: phase),
      ),
      ObjectId.doll => CustomPaint(
        painter: DollPainter(
          fingers: s.dollFingers,
          holdingKey: !s.has(ItemId.dollKey),
          staring: s.stillness,
          smiling: s.has(ItemId.dollKey),
        ),
      ),
      // The portraits
      ObjectId.portraitElias ||
      ObjectId.portraitMarta ||
      ObjectId.portraitAnna => _portrait(object.id, s),
      ObjectId.emptyFrame => const CustomPaint(painter: EmptyFramePainter()),
      // The bells
      ObjectId.bellA ||
      ObjectId.bellB ||
      ObjectId.bellC ||
      ObjectId.bellD => ServantBell(
        label: _tr(GameData.bellRooms[object.id]!),
        bellSize: (object.id.index - ObjectId.bellA.index) / 3,
        ringing: widget.ringing == object.id,
        ringSeq: widget.ringSeq,
      ),
      ObjectId.coat => const CustomPaint(painter: CoatPainter()),
      // The dinner
      ObjectId.diningTable => LoopingPaint(
        period: const Duration(seconds: 3),
        painter: (phase) =>
            DiningTablePainter(chairs: _chairsAt(object), phase: phase),
      ),
      ObjectId.seatA ||
      ObjectId.seatB ||
      ObjectId.seatC ||
      ObjectId.seatD ||
      ObjectId.seatE => CustomPaint(
        painter: PlaceSettingPainter(
          card: _tr(GameData.seatCards[object.id]!),
          set: s.setPlaces.contains(object.id),
          guest: object.id == GameData.guestSeat,
        ),
      ),
      // The study
      ObjectId.tally => const CustomPaint(painter: TallyPainter()),
      ObjectId.desk => const CustomPaint(painter: DeskPainter()),
      ObjectId.diary => CustomPaint(
        painter: DiaryPainter(
          open: s.puzzles[PuzzleId.diaryLock]?.solved ?? false,
        ),
      ),
      ObjectId.inkwell => const CustomPaint(painter: InkwellPainter()),
      ObjectId.floorboard => CustomPaint(
        painter: FloorboardPainter(lifted: s.knows(ClueId.marksFloor)),
      ),
    };
  }

  Widget _portrait(ObjectId id, GameState s) {
    // Marta is not Marta: she watches you, and now and then she blinks.
    final impostor = id == ObjectId.portraitMarta;
    final looked = s.lookedBehind.contains(id);
    return LoopingPaint(
      animate: impostor && !looked,
      period: const Duration(seconds: 6),
      painter: (phase) => PortraitPainter(
        sitter: switch (id) {
          ObjectId.portraitElias => Sitter.elias,
          ObjectId.portraitMarta => Sitter.marta,
          _ => Sitter.anna,
        },
        plate: GameData.portraitPlates[id]!,
        watching: impostor,
        blink: impostor && !looked ? phase : .5,
        moved: looked,
        revealed: impostor && looked,
      ),
    );
  }

  /// Where the chairs stand, as fractions of the table's width.
  List<double> _chairsAt(GameObject table) {
    final p = table.placement;
    final left = p.x - p.width / 2;
    return [
      for (final o in widget.level.objects)
        if (o.id.isSeat) (o.placement.x - left) / p.width,
    ];
  }

  Widget _phone(GameState s) {
    final unread = s.knockingStarted && !s.knows(ClueId.phoneMessages);
    return LoopingPaint(
      animate: unread,
      period: const Duration(milliseconds: 1600),
      painter: (phase) => PhonePainter(
        screen: !s.knockingStarted
            ? 0
            : (unread ? .55 + .45 * math.sin(phase * math.pi).abs() : .5),
        unread: unread,
      ),
    );
  }
}
