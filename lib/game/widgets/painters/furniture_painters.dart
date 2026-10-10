import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../../core/constants/app_colors.dart';
import 'paint_kit.dart';

/// Old wooden table, seen slightly from above.
class TablePainter extends CustomPainter {
  const TablePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    PaintKit.floorShadow(canvas, Offset.zero & size);

    // Back legs (further away, darker).
    for (final x in [w * .14, w * .81]) {
      canvas.drawRect(
        Rect.fromLTWH(x, h * .2, w * .05, h * .72),
        PaintKit.fill(AppColors.woodDark.withValues(alpha: .9)),
      );
    }
    // Apron under the top.
    final apron = Rect.fromLTWH(w * .05, h * .18, w * .9, h * .11);
    canvas.drawRect(apron, PaintKit.wood(apron, light: AppColors.wood));
    // Front legs.
    for (final x in [w * .05, w * .88]) {
      final leg = Rect.fromLTWH(x, h * .18, w * .07, h * .82);
      canvas.drawRect(leg, PaintKit.wood(leg));
    }
    // Top surface (visible from above).
    final top = Path()
      ..moveTo(w * .04, 0)
      ..lineTo(w * .96, 0)
      ..lineTo(w, h * .1)
      ..lineTo(0, h * .1)
      ..close();
    final topRect = Rect.fromLTWH(0, 0, w, h * .1);
    canvas.drawPath(
      top,
      PaintKit.vertical(topRect, [AppColors.woodDark, AppColors.woodLight]),
    );
    PaintKit.grain(canvas, topRect, lines: 4, vertical: false, alpha: .12);
    // Front edge.
    final edge = Rect.fromLTWH(0, h * .1, w, h * .08);
    canvas.drawRect(edge, PaintKit.wood(edge));
    canvas.drawLine(
      Offset(0, h * .1),
      Offset(w, h * .1),
      PaintKit.stroke(AppColors.bone.withValues(alpha: .08), 1),
    );
  }

  @override
  bool shouldRepaint(TablePainter oldDelegate) => false;
}

/// Bedside cabinet with one drawer that slides towards the viewer.
class DrawerPainter extends CustomPainter {
  const DrawerPainter({required this.open});

  final bool open;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    PaintKit.floorShadow(canvas, Offset.zero & size);

    // Short legs.
    for (final x in [w * .04, w * .88]) {
      canvas.drawRect(
        Rect.fromLTWH(x, h * .9, w * .08, h * .1),
        PaintKit.fill(AppColors.woodDark),
      );
    }
    // Body.
    final body = Rect.fromLTWH(0, h * .07, w, h * .85);
    canvas.drawRect(body, PaintKit.wood(body));
    PaintKit.grain(canvas, body, lines: 6, seed: 11);
    // Top.
    final top = Path()
      ..moveTo(w * .03, 0)
      ..lineTo(w * .97, 0)
      ..lineTo(w, h * .07)
      ..lineTo(0, h * .07)
      ..close();
    canvas.drawPath(
      top,
      PaintKit.vertical(Rect.fromLTWH(0, 0, w, h * .07), [
        AppColors.woodDark,
        AppColors.woodLight,
      ]),
    );

    // Lower cabinet door.
    PaintKit.recessedPanel(
      canvas,
      Rect.fromLTWH(w * .1, h * .5, w * .8, h * .35),
    );
    canvas.drawCircle(
      Offset(w * .8, h * .62),
      w * .025,
      PaintKit.fill(AppColors.brass.withValues(alpha: .7)),
    );

    final slot = Rect.fromLTWH(w * .07, h * .13, w * .86, h * .3);
    if (!open) {
      _drawerFront(canvas, slot, w);
      return;
    }

    // Open: a dark slot, the drawer's insides and its front pulled forward.
    canvas.drawRect(slot, PaintKit.fill(AppColors.black));
    final front = Rect.fromLTWH(w * .02, h * .25, w * .96, h * .3);
    final inside = Path()
      ..moveTo(slot.left, slot.top + slot.height * .2)
      ..lineTo(slot.right, slot.top + slot.height * .2)
      ..lineTo(front.right, front.top)
      ..lineTo(front.left, front.top)
      ..close();
    canvas.drawPath(inside, PaintKit.fill(const Color(0xFF0E0907)));
    canvas.drawPath(
      inside,
      PaintKit.stroke(AppColors.woodLight.withValues(alpha: .5), 1.2),
    );
    _drawerFront(canvas, front, w);
  }

  void _drawerFront(Canvas canvas, Rect r, double w) {
    canvas.drawRect(
      r,
      PaintKit.wood(
        r,
        base: AppColors.woodLight,
        light: const Color(0xFF55402C),
      ),
    );
    canvas.drawRect(
      r,
      PaintKit.stroke(AppColors.black.withValues(alpha: .6), 1.5),
    );
    canvas.drawCircle(
      r.center,
      w * .035,
      PaintKit.radial(r.center - Offset(w * .01, w * .01), w * .04, [
        const Color(0xFFA08A64),
        AppColors.brass,
        AppColors.woodDark,
      ]),
    );
  }

  @override
  bool shouldRepaint(DrawerPainter oldDelegate) => oldDelegate.open != open;
}

/// A wooden chair seen from behind — it faces the mirror.
class ChairPainter extends CustomPainter {
  const ChairPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    PaintKit.floorShadow(canvas, Rect.fromLTWH(0, 0, w, h), alpha: .6);

    // Front legs (further from us, visible under the seat).
    for (final x in [w * .24, w * .7]) {
      canvas.drawRect(
        Rect.fromLTWH(x, h * .58, w * .06, h * .36),
        PaintKit.fill(AppColors.woodDark),
      );
    }
    // Seat.
    final seat = Path()
      ..moveTo(w * .2, h * .52)
      ..lineTo(w * .8, h * .52)
      ..lineTo(w * .9, h * .6)
      ..lineTo(w * .1, h * .6)
      ..close();
    canvas.drawPath(
      seat,
      PaintKit.vertical(Rect.fromLTWH(0, h * .52, w, h * .08), [
        AppColors.woodLight,
        AppColors.wood,
      ]),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * .1, h * .6, w * .8, h * .04),
      PaintKit.fill(AppColors.woodDark),
    );
    // Back posts, running down into the back legs.
    for (final x in [w * .1, w * .82]) {
      final post = Rect.fromLTWH(x, 0, w * .08, h);
      canvas.drawRect(post, PaintKit.wood(post));
    }
    // Top rail and slats.
    final rail = Rect.fromLTWH(w * .1, h * .02, w * .8, h * .09);
    canvas.drawRect(rail, PaintKit.wood(rail));
    for (final x in [.32, .47, .62]) {
      final slat = Rect.fromLTWH(w * x, h * .11, w * .06, h * .41);
      canvas.drawRect(slat, PaintKit.wood(slat, light: AppColors.wood));
    }
    canvas.drawRect(
      Rect.fromLTWH(w * .1, h * .44, w * .8, h * .05),
      PaintKit.fill(AppColors.wood),
    );
  }

  @override
  bool shouldRepaint(ChairPainter oldDelegate) => false;
}

/// Table lamp. When on, it gives a wrong, reddish light.
class LampPainter extends CustomPainter {
  const LampPainter({required this.on, this.flicker = 0});

  final bool on;

  /// 0..1 animation phase used to make the light unsteady.
  final double flicker;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final shade = Path()
      ..moveTo(w * .28, h * .04)
      ..lineTo(w * .72, h * .04)
      ..lineTo(w * .98, h * .44)
      ..lineTo(w * .02, h * .44)
      ..close();
    final shadeRect = Rect.fromLTWH(0, h * .04, w, h * .4);
    final glow = on
        ? .75 +
              .25 * math.sin(flicker * math.pi * 2 * 3) * math.sin(flicker * 17)
        : 0.0;

    if (on) {
      // Halo and the light pool on the table.
      canvas.drawCircle(
        shadeRect.center,
        w * 2.2,
        PaintKit.radial(shadeRect.center, w * 2.2, [
          AppColors.ember.withValues(alpha: .2 * glow),
          AppColors.blood.withValues(alpha: .06 * glow),
          const Color(0x00000000),
        ]),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * .5, h),
          width: w * 3,
          height: h * .18,
        ),
        PaintKit.radial(Offset(w * .5, h), w * 1.5, [
          AppColors.ember.withValues(alpha: .25 * glow),
          const Color(0x00000000),
        ]),
      );
    }

    // Base and stem.
    final base = Rect.fromLTWH(w * .22, h * .9, w * .56, h * .1);
    canvas.drawOval(
      base,
      PaintKit.wood(
        base,
        base: AppColors.brass,
        light: const Color(0xFF8D7755),
      ),
    );
    final stem = Rect.fromLTWH(w * .46, h * .43, w * .08, h * .5);
    canvas.drawRect(
      stem,
      PaintKit.wood(
        stem,
        base: AppColors.brass,
        light: const Color(0xFF8D7755),
      ),
    );

    if (on) {
      canvas.drawCircle(
        Offset(w * .5, h * .42),
        w * .12,
        PaintKit.fill(const Color(0xFFE8C9A0).withValues(alpha: glow)),
      );
    }

    // Shade.
    canvas.drawPath(
      shade,
      PaintKit.vertical(
        shadeRect,
        on
            ? [
                Color.lerp(
                  const Color(0xFF5A2A16),
                  const Color(0xFFA8643A),
                  glow,
                )!,
                Color.lerp(
                  const Color(0xFF3A160C),
                  const Color(0xFF7A3018),
                  glow,
                )!,
              ]
            : const [Color(0xFF3E342B), Color(0xFF1F1915)],
      ),
    );
    final seams = PaintKit.stroke(AppColors.black.withValues(alpha: .18), 1);
    for (final t in [.3, .5, .7]) {
      canvas.drawLine(
        Offset(w * (.28 + .44 * t), h * .04),
        Offset(w * (.02 + .96 * t), h * .44),
        seams,
      );
    }
    canvas.drawLine(
      Offset(w * .02, h * .44),
      Offset(w * .98, h * .44),
      PaintKit.stroke(AppColors.black.withValues(alpha: .5), 1.5),
    );
  }

  @override
  bool shouldRepaint(LampPainter oldDelegate) =>
      oldDelegate.on != on || oldDelegate.flicker != flicker;
}

/// A phone propped up on the table.
class PhonePainter extends CustomPainter {
  const PhonePainter({required this.screen, required this.unread});

  /// 0 = dark, 1 = fully lit.
  final double screen;
  final bool unread;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .08, 0, w * .84, h * .96),
      Radius.circular(w * .14),
    );

    if (screen > 0) {
      canvas.drawCircle(
        body.center,
        w * 1.8,
        PaintKit.radial(body.center, w * 1.8, [
          AppColors.coldLight.withValues(alpha: .16 * screen),
          const Color(0x00000000),
        ]),
      );
    }

    canvas.drawRRect(body, PaintKit.fill(const Color(0xFF121212)));
    canvas.drawRRect(body, PaintKit.stroke(AppColors.smoke, 1.2));

    final glass = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .16, h * .06, w * .68, h * .84),
      Radius.circular(w * .08),
    );
    canvas.drawRRect(
      glass,
      PaintKit.vertical(glass.outerRect, [
        Color.lerp(const Color(0xFF0A0C0D), const Color(0xFF55636A), screen)!,
        Color.lerp(const Color(0xFF050606), const Color(0xFF242C30), screen)!,
      ]),
    );
    if (screen > 0) {
      final line = PaintKit.stroke(
        AppColors.bone.withValues(alpha: .6 * screen),
        1.4,
      );
      for (var i = 0; i < 3; i++) {
        final y = glass.top + glass.height * (.3 + i * .14);
        canvas.drawLine(
          Offset(glass.left + glass.width * .15, y),
          Offset(glass.left + glass.width * (i == 2 ? .55 : .85), y),
          line,
        );
      }
      if (unread) {
        canvas.drawCircle(
          Offset(
            glass.right - glass.width * .18,
            glass.top + glass.height * .1,
          ),
          w * .06,
          PaintKit.fill(const Color(0xFFB01818)),
        );
      }
    }
    // Reflection streak.
    canvas.save();
    canvas.clipRRect(glass);
    canvas.drawLine(
      Offset(glass.left, glass.top + glass.height * .55),
      Offset(glass.right, glass.top + glass.height * .2),
      PaintKit.stroke(AppColors.bone.withValues(alpha: .05), w * .2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PhonePainter oldDelegate) =>
      oldDelegate.screen != screen || oldDelegate.unread != unread;
}
