import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'painters/paint_kit.dart';
import 'room_layout.dart';

/// Walls, floor, stains and grain of a room. Static: painted once per size.
class RoomBackground extends StatelessWidget {
  const RoomBackground({
    super.key,
    required this.layout,
    required this.wallTint,
    required this.doorLight,
    this.seed = 1,
  });

  final RoomLayout layout;
  final Color wallTint;
  final Color doorLight;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: layout.size,
        painter: _RoomPainter(layout, wallTint, doorLight, seed),
      ),
    );
  }
}

/// Darkens the edges of the room. [intensity] is animated by the breathing.
class RoomVignette extends StatelessWidget {
  const RoomVignette({super.key, this.intensity = 1});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -.1),
            radius: 1.05,
            colors: [
              Colors.transparent,
              AppColors.black.withValues(alpha: .55 * intensity),
              AppColors.black.withValues(alpha: .95 * intensity),
            ],
            stops: const [.42, .78, 1],
          ),
        ),
      ),
    );
  }
}

class _RoomPainter extends CustomPainter {
  const _RoomPainter(this.layout, this.wallTint, this.doorLight, this.seed);

  final RoomLayout layout;
  final Color wallTint;
  final Color doorLight;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final u = layout.unit;
    final floorY = layout.floorY;
    final rnd = math.Random(seed);

    // Wall.
    final wall = Rect.fromLTWH(0, 0, w, floorY);
    canvas.drawRect(
      wall,
      PaintKit.vertical(
        wall,
        [
          AppColors.wallDark,
          Color.lerp(AppColors.wall, wallTint, .45)!,
          AppColors.wall,
        ],
        const [0, .55, 1],
      ),
    );

    // Old striped wallpaper.
    final step = u * .075;
    final stripe = PaintKit.fill(AppColors.bone.withValues(alpha: .018));
    for (var x = layout.stageLeft % step - step; x < w; x += step) {
      canvas.drawRect(Rect.fromLTWH(x, 0, step * .42, floorY), stripe);
    }
    final hairline = PaintKit.fill(AppColors.black.withValues(alpha: .12));
    for (var x = layout.stageLeft % step - step; x < w; x += step) {
      canvas.drawRect(Rect.fromLTWH(x + step * .42, 0, 1, floorY), hairline);
    }

    // Damp stains.
    for (var i = 0; i < 6; i++) {
      final c = Offset(rnd.nextDouble() * w, rnd.nextDouble() * floorY);
      final r = u * (.12 + rnd.nextDouble() * .25);
      canvas.drawCircle(
        c,
        r,
        PaintKit.radial(c, r, [
          AppColors.black.withValues(alpha: .22),
          AppColors.black.withValues(alpha: 0),
        ]),
      );
    }
    // A long water streak.
    final streakX = layout.stageLeft + u * (.25 + rnd.nextDouble() * .5);
    canvas.drawRect(
      Rect.fromLTWH(streakX, 0, u * .02, floorY * .6),
      PaintKit.vertical(Rect.fromLTWH(streakX, 0, 1, floorY * .6), [
        AppColors.black.withValues(alpha: .25),
        AppColors.black.withValues(alpha: 0),
      ]),
    );

    // Faint light around the door.
    final doorCenter = layout.point(.5, .35);
    canvas.drawCircle(
      doorCenter,
      u * .8,
      PaintKit.radial(doorCenter, u * .8, [
        doorLight.withValues(alpha: .06),
        doorLight.withValues(alpha: 0),
      ]),
    );

    // Contact shadow where the wall meets the floor.
    final ao = Rect.fromLTWH(0, floorY - u * .1, w, u * .1);
    canvas.drawRect(
      ao,
      PaintKit.vertical(ao, [
        AppColors.black.withValues(alpha: 0),
        AppColors.black.withValues(alpha: .45),
      ]),
    );

    // Floor.
    final floor = Rect.fromLTWH(0, floorY, w, h - floorY);
    canvas.drawRect(
      floor,
      PaintKit.vertical(floor, [AppColors.floor, AppColors.floorDark]),
    );

    // Perspective floorboards.
    final vanish = Offset(w / 2, floorY - h * .55);
    final seam = PaintKit.stroke(AppColors.black.withValues(alpha: .45), 1);
    final glint = PaintKit.stroke(AppColors.bone.withValues(alpha: .025), 1);
    for (var i = -12; i <= 12; i++) {
      final bottom = Offset(w / 2 + i * u * .16, h);
      final t = (floorY - vanish.dy) / (bottom.dy - vanish.dy);
      final top = Offset.lerp(vanish, bottom, t)!;
      canvas.drawLine(top, bottom, seam);
      canvas.drawLine(top.translate(1.5, 0), bottom.translate(2.5, 0), glint);
    }
    for (var i = 1; i <= 4; i++) {
      final y = floorY + (h - floorY) * math.pow(i / 5, 1.6);
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y),
        PaintKit.stroke(AppColors.black.withValues(alpha: .25), 1),
      );
    }

    // Baseboard.
    final board = Rect.fromLTWH(0, floorY - u * .03, w, u * .03);
    canvas.drawRect(board, PaintKit.fill(AppColors.woodDark));
    canvas.drawLine(
      board.topLeft,
      board.topRight,
      PaintKit.stroke(AppColors.bone.withValues(alpha: .05), 1),
    );

    // Light pooling on the floor in front of the door.
    final pool = layout.point(.5, -.06);
    canvas.drawOval(
      Rect.fromCenter(center: pool, width: u * .7, height: u * .16),
      PaintKit.radial(pool, u * .35, [
        doorLight.withValues(alpha: .09),
        doorLight.withValues(alpha: 0),
      ]),
    );

    // Film grain / dust.
    final dust = Paint();
    for (var i = 0; i < 900; i++) {
      dust.color = (rnd.nextBool() ? AppColors.bone : AppColors.black)
          .withValues(alpha: .02 + rnd.nextDouble() * .05);
      canvas.drawRect(
        Rect.fromLTWH(rnd.nextDouble() * w, rnd.nextDouble() * h, 1.2, 1.2),
        dust,
      );
    }
  }

  @override
  bool shouldRepaint(_RoomPainter oldDelegate) =>
      oldDelegate.layout.size != layout.size ||
      oldDelegate.wallTint != wallTint ||
      oldDelegate.doorLight != doorLight ||
      oldDelegate.seed != seed;
}
