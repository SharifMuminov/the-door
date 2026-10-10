import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/game_object.dart';

/// Converts [ObjectPlacement]s (stage units, floor-anchored) into pixels.
///
/// The stage is a centred column whose width is the screen width on phones
/// and shrinks on squat screens (tablets), so objects keep their proportions
/// on every aspect ratio.
@immutable
class RoomLayout {
  const RoomLayout._(this.size, this.unit, this.stageLeft, this.floorY);

  factory RoomLayout.of(Size size) {
    final unit = math.min(size.width, size.height * 0.62);
    return RoomLayout._(
      size,
      unit,
      (size.width - unit) / 2,
      size.height * 0.72,
    );
  }

  final Size size;

  /// Pixels per stage unit.
  final double unit;
  final double stageLeft;
  final double floorY;

  Rect rectFor(ObjectPlacement p) {
    final w = p.width * unit;
    final h = p.height * unit;
    final cx = stageLeft + p.x * unit;
    final bottom = floorY - p.y * unit;
    return Rect.fromLTWH(cx - w / 2, bottom - h, w, h);
  }

  Offset point(double x, double y) =>
      Offset(stageLeft + x * unit, floorY - y * unit);
}
