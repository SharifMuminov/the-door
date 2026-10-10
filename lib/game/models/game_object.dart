import 'package:flutter/foundation.dart';

import '../../core/l10n/l_text.dart';
import '../../core/utils/audio_manager.dart';

/// Every kind of object that can appear in a room.
enum ObjectId {
  door,
  table,
  drawer,
  clock,
  lamp,
  note,
  mirror,
  chair,
  painting,
  phone,
  window,
  // The candles
  candleA,
  candleB,
  candleC,
  photo,
  // Hide
  wardrobe,
  bulb,
  floorKey,
  // The radio
  radio,
  calendar,
  // The lullaby
  cradle,
  musicBox,
  doll,
  // The portraits
  portraitElias,
  portraitMarta,
  portraitAnna,
  emptyFrame,
  // The bells
  bellA,
  bellB,
  bellC,
  bellD,
  coat,
  // The dinner
  diningTable,
  seatA,
  seatB,
  seatC,
  seatD,
  seatE,
  // The study
  tally,
  desk,
  floorboard,
  diary,
  inkwell;

  bool get isCandle => this == candleA || this == candleB || this == candleC;

  bool get isBell =>
      this == bellA || this == bellB || this == bellC || this == bellD;

  bool get isSeat =>
      this == seatA ||
      this == seatB ||
      this == seatC ||
      this == seatD ||
      this == seatE;

  bool get isPortrait =>
      this == portraitElias || this == portraitMarta || this == portraitAnna;
}

/// Visual variant for objects that look different between rooms.
enum ObjectStyle { standard, tabletop }

/// Where an object sits in the room.
///
/// The room is measured in "stage units": 1 unit = the stage width, which is
/// the screen width on phones. Everything is anchored to the floor line, so
/// the composition keeps its proportions on any aspect ratio.
@immutable
class ObjectPlacement {
  const ObjectPlacement({
    required this.x,
    required this.y,
    required this.width,
    required this.aspectRatio,
  });

  /// Horizontal centre, as a fraction of the stage width (0..1).
  final double x;

  /// Distance of the object's bottom edge above the floor line, in units.
  /// Negative values place the object on the floor, closer to the viewer.
  final double y;

  /// Width in units.
  final double width;

  /// Height divided by width.
  final double aspectRatio;

  double get height => width * aspectRatio;
}

@immutable
class GameObject {
  const GameObject({
    required this.id,
    required this.label,
    required this.placement,
    this.style = ObjectStyle.standard,
    this.tapSound = Sfx.click,
  });

  final ObjectId id;

  /// Used for accessibility.
  final LText label;
  final ObjectPlacement placement;
  final ObjectStyle style;

  /// Played by the widget on every tap. Objects with their own sound
  /// (door, drawer, lamp, note...) leave this null and let the logic decide.
  final Sfx? tapSound;
}
