import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_colors.dart';
import 'paint_kit.dart';

const _clear = Color(0x00000000);

// ------------------------------------------------------------ the dinner

/// A long dining table under an old cloth, two candlesticks, and the
/// backs of the chairs behind it. [chairs] are the chair positions as
/// fractions of the table's width.
class DiningTablePainter extends CustomPainter {
  const DiningTablePainter({required this.chairs, this.phase = 0});

  final List<double> chairs;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    PaintKit.floorShadow(canvas, Offset.zero & size, alpha: .7);

    // Chair backs, standing behind the table.
    for (final x in chairs) {
      _chairBack(canvas, w * x, w, h);
    }

    // Top, seen slightly from above.
    final top = Path()
      ..moveTo(w * .03, 0)
      ..lineTo(w * .97, 0)
      ..lineTo(w, h * .42)
      ..lineTo(0, h * .42)
      ..close();
    final topRect = Rect.fromLTWH(0, 0, w, h * .42);
    canvas.drawPath(
      top,
      PaintKit.vertical(topRect, const [Color(0xFF6E675C), Color(0xFF9C9382)]),
    );
    final rnd = math.Random(23);
    for (var i = 0; i < 5; i++) {
      final c = Offset(w * rnd.nextDouble(), h * (.08 + rnd.nextDouble() * .3));
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w * .06, height: h * .06),
        PaintKit.fill(const Color(0xFF4A3A28).withValues(alpha: .14)),
      );
    }

    // Two candlesticks between the places.
    for (final x in [.21, .79]) {
      _candlestick(canvas, Offset(w * x, h * .26), w, h);
    }

    // The cloth hanging down the front, with folds and a lace hem.
    final drop = Rect.fromLTWH(0, h * .42, w, h * .46);
    canvas.drawRect(
      drop,
      PaintKit.vertical(drop, const [Color(0xFF8E8676), Color(0xFF4E483E)]),
    );
    final fold = PaintKit.stroke(AppColors.black.withValues(alpha: .16), 2);
    for (var x = .04; x < 1; x += .075) {
      canvas.drawLine(
        Offset(w * x, h * .44),
        Offset(w * (x + .01), h * .88),
        fold,
      );
    }
    canvas.drawLine(
      Offset(0, h * .42),
      Offset(w, h * .42),
      PaintKit.stroke(AppColors.bone.withValues(alpha: .12), 1),
    );
    final hem = Path()..moveTo(0, h * .88);
    for (var x = 0.0; x < 1; x += .025) {
      hem.quadraticBezierTo(w * (x + .0125), h * .93, w * (x + .025), h * .88);
    }
    canvas.drawPath(
      hem,
      PaintKit.stroke(const Color(0xFFB8AE9A).withValues(alpha: .5), 1.2),
    );

    // Legs under the cloth.
    for (final x in [.04, .92]) {
      canvas.drawRect(
        Rect.fromLTWH(w * x, h * .9, w * .04, h * .1),
        PaintKit.fill(AppColors.woodDark),
      );
    }
  }

  void _chairBack(Canvas canvas, double cx, double w, double h) {
    final cw = w * .1;
    final top = -h * .62;
    final back = Rect.fromLTRB(cx - cw / 2, top, cx + cw / 2, h * .05);
    for (final x in [back.left, back.right - cw * .16]) {
      final post = Rect.fromLTWH(x, top, cw * .16, back.height);
      canvas.drawRect(post, PaintKit.wood(post));
      canvas.drawCircle(
        Offset(x + cw * .08, top),
        cw * .12,
        PaintKit.fill(AppColors.woodLight),
      );
    }
    final rail = Rect.fromLTWH(back.left, top + h * .05, cw, h * .1);
    canvas.drawRect(rail, PaintKit.wood(rail));
    final splat = Rect.fromLTWH(cx - cw * .14, top + h * .15, cw * .28, h * .4);
    canvas.drawRect(splat, PaintKit.wood(splat, light: AppColors.wood));
  }

  void _candlestick(Canvas canvas, Offset base, double w, double h) {
    final f = phase * math.pi * 2;
    final brass = PaintKit.fill(AppColors.brass);
    canvas.drawOval(
      Rect.fromCenter(center: base, width: w * .05, height: h * .05),
      brass,
    );
    canvas.drawRect(
      Rect.fromLTRB(base.dx - w * .006, -h * .2, base.dx + w * .006, base.dy),
      brass,
    );
    canvas.drawRect(
      Rect.fromLTRB(base.dx - w * .009, -h * .4, base.dx + w * .009, -h * .2),
      PaintKit.fill(const Color(0xFFCEC2A6)),
    );
    final flame = Offset(base.dx, -h * .44);
    final flicker = .85 + .15 * math.sin(f * 7) * math.sin(f * 3 + 1);
    canvas.drawCircle(
      flame,
      w * .09,
      PaintKit.radial(flame, w * .09, [
        AppColors.ember.withValues(alpha: .3 * flicker),
        _clear,
      ]),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: flame,
        width: w * .012,
        height: h * .09 * flicker,
      ),
      PaintKit.fill(const Color(0xFFFFD890)),
    );
  }

  @override
  bool shouldRepaint(DiningTablePainter oldDelegate) =>
      oldDelegate.phase != phase || !listEquals(oldDelegate.chairs, chairs);
}

/// One place at the table: a folded name card and, once set, a plate
/// with knife and fork. Unset, only a ring in the dust remains.
class PlaceSettingPainter extends CustomPainter {
  const PlaceSettingPainter({
    required this.card,
    required this.set,
    this.guest = false,
  });

  /// The name on the card; empty for the card with no name.
  final String card;
  final bool set;
  final bool guest;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // The plate, or the ring where one used to be.
    final plate = Rect.fromCenter(
      center: Offset(w / 2, h * .7),
      width: w * .66,
      height: h * .34,
    );
    if (set) {
      canvas.drawOval(
        plate.shift(const Offset(1, 2)),
        Paint()
          ..color = AppColors.black.withValues(alpha: .4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawOval(
        plate,
        PaintKit.radial(plate.center - Offset(0, plate.height * .2), w * .4, [
          const Color(0xFFDCD4C6),
          const Color(0xFF9A9284),
        ]),
      );
      canvas.drawOval(
        plate.deflate(w * .07),
        PaintKit.stroke(const Color(0xFFA08A5C).withValues(alpha: .7), 1),
      );
      final cutlery = PaintKit.stroke(const Color(0xFFB8B0A2), w * .025);
      canvas.drawLine(
        Offset(w * .07, h * .55),
        Offset(w * .07, h * .9),
        cutlery,
      );
      canvas.drawLine(
        Offset(w * .93, h * .55),
        Offset(w * .93, h * .9),
        cutlery,
      );
      for (final dx in [-.02, .0, .02]) {
        canvas.drawLine(
          Offset(w * (.07 + dx), h * .5),
          Offset(w * (.07 + dx), h * .58),
          PaintKit.stroke(const Color(0xFFB8B0A2), 1),
        );
      }
    } else {
      canvas.drawOval(
        plate,
        PaintKit.stroke(const Color(0xFF3A3024).withValues(alpha: .35), 1.5),
      );
    }

    // The name card, folded like a little tent.
    final cardRect = Rect.fromCenter(
      center: Offset(w / 2, h * .24),
      width: w * .84,
      height: h * .34,
    );
    canvas.drawRect(
      cardRect.shift(const Offset(1.5, 2)),
      Paint()
        ..color = AppColors.black.withValues(alpha: .45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawRect(
      cardRect,
      PaintKit.vertical(cardRect, [
        guest ? const Color(0xFFE0D4BC) : const Color(0xFFCFC3A8),
        const Color(0xFF9E937C),
      ]),
    );
    if (guest) {
      canvas.drawRect(
        cardRect.deflate(w * .03),
        PaintKit.stroke(AppColors.blood.withValues(alpha: .8), 1),
      );
    }
    if (card.isEmpty) {
      // Wiped clean, recently.
      canvas.drawLine(
        Offset(cardRect.left + w * .12, cardRect.center.dy),
        Offset(cardRect.right - w * .12, cardRect.center.dy + h * .02),
        PaintKit.stroke(AppColors.ink.withValues(alpha: .18), h * .06),
      );
      return;
    }
    final tp = TextPainter(
      text: TextSpan(
        text: card,
        style: AppText.label.copyWith(
          fontSize: cardRect.height * .5,
          letterSpacing: 1,
          color: guest ? AppColors.blood : AppColors.ink,
          fontStyle: guest ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: cardRect.width);
    tp.paint(
      canvas,
      Offset(
        cardRect.center.dx - tp.width / 2,
        cardRect.center.dy - tp.height / 2,
      ),
    );
    tp.dispose();
  }

  @override
  bool shouldRepaint(PlaceSettingPainter oldDelegate) =>
      oldDelegate.card != card ||
      oldDelegate.set != set ||
      oldDelegate.guest != guest;
}

// ------------------------------------------------------------ the study

/// Tally marks scratched into the wallpaper, in groups of five.
class TallyPainter extends CustomPainter {
  const TallyPainter({this.count = 20});

  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rnd = math.Random(count);

    // Scraped wallpaper around the marks.
    canvas.drawRect(
      Offset.zero & size,
      PaintKit.radial(size.center(Offset.zero), w * .6, [
        AppColors.bone.withValues(alpha: .04),
        _clear,
      ]),
    );

    final groups = (count / 5).ceil();
    const perRow = 2;
    final rows = (groups / perRow).ceil();
    final cellW = w / perRow, cellH = h / rows;
    final light = PaintKit.stroke(AppColors.bone.withValues(alpha: .42), 1.6);
    final dark = PaintKit.stroke(AppColors.black.withValues(alpha: .6), 1.6);

    var left = count;
    for (var g = 0; g < groups; g++) {
      final cell = Rect.fromLTWH(
        (g % perRow) * cellW,
        (g ~/ perRow) * cellH,
        cellW,
        cellH,
      ).deflate(w * .05);
      final marks = math.min(5, left);
      left -= marks;
      for (var i = 0; i < marks; i++) {
        late Offset a, b;
        if (i < 4) {
          final x = cell.left + cell.width * (.12 + i * .25);
          a = Offset(x + (rnd.nextDouble() - .5) * 3, cell.top);
          b = Offset(x + (rnd.nextDouble() - .5) * 4, cell.bottom);
        } else {
          a = Offset(cell.left, cell.top + cell.height * .7);
          b = Offset(cell.right, cell.top + cell.height * .25);
        }
        canvas.drawLine(a + const Offset(1, 1), b + const Offset(1, 1), dark);
        canvas.drawLine(a, b, light);
      }
    }
  }

  @override
  bool shouldRepaint(TallyPainter oldDelegate) => oldDelegate.count != count;
}

/// A writing desk with a pedestal of drawers. Fifteen marks are cut into
/// the front.
class DeskPainter extends CustomPainter {
  const DeskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    PaintKit.floorShadow(canvas, Offset.zero & size);

    // Back legs.
    canvas.drawRect(
      Rect.fromLTWH(w * .1, h * .2, w * .04, h * .75),
      PaintKit.fill(AppColors.woodDark.withValues(alpha: .9)),
    );

    // Pedestal of drawers on the right.
    final pedestal = Rect.fromLTWH(w * .58, h * .12, w * .38, h * .88);
    canvas.drawRect(pedestal, PaintKit.wood(pedestal));
    PaintKit.grain(canvas, pedestal, lines: 4, seed: 51);
    for (var i = 0; i < 3; i++) {
      final d = Rect.fromLTWH(
        pedestal.left + w * .03,
        pedestal.top + h * (.1 + i * .26),
        pedestal.width - w * .06,
        h * .22,
      );
      PaintKit.recessedPanel(canvas, d, inset: 1.5);
      canvas.drawCircle(
        d.center,
        w * .015,
        PaintKit.fill(AppColors.brass.withValues(alpha: .8)),
      );
    }
    // Front leg on the left.
    final leg = Rect.fromLTWH(w * .04, h * .12, w * .06, h * .88);
    canvas.drawRect(leg, PaintKit.wood(leg));

    // Apron under the top, with the marks cut into it.
    final apron = Rect.fromLTWH(w * .04, h * .1, w * .54, h * .16);
    canvas.drawRect(apron, PaintKit.wood(apron, light: AppColors.wood));
    final cut = PaintKit.stroke(AppColors.bone.withValues(alpha: .3), 1.2);
    final shadow = PaintKit.stroke(AppColors.black.withValues(alpha: .6), 1.2);
    for (var g = 0; g < 3; g++) {
      final x0 = apron.left + apron.width * (.12 + g * .29);
      final y0 = apron.top + apron.height * .2;
      final y1 = apron.bottom - apron.height * .2;
      for (var i = 0; i < 4; i++) {
        final x = x0 + apron.width * .045 * i;
        canvas.drawLine(Offset(x + 1, y0 + 1), Offset(x + 1, y1 + 1), shadow);
        canvas.drawLine(Offset(x, y0), Offset(x, y1), cut);
      }
      canvas.drawLine(
        Offset(x0 - apron.width * .02, y1),
        Offset(x0 + apron.width * .16, y0),
        cut,
      );
    }

    // Top surface.
    final top = Path()
      ..moveTo(w * .02, 0)
      ..lineTo(w * .98, 0)
      ..lineTo(w, h * .1)
      ..lineTo(0, h * .1)
      ..close();
    canvas.drawPath(
      top,
      PaintKit.vertical(Rect.fromLTWH(0, 0, w, h * .1), const [
        AppColors.woodDark,
        AppColors.woodLight,
      ]),
    );
    // Green leather inlay.
    canvas.drawRect(
      Rect.fromLTWH(w * .14, h * .02, w * .72, h * .06),
      PaintKit.fill(const Color(0xFF1E2A1E).withValues(alpha: .8)),
    );
  }

  @override
  bool shouldRepaint(DeskPainter oldDelegate) => false;
}

/// A leather diary with a little two-dial lock. When [open], its pages
/// show — written to the edges.
class DiaryPainter extends CustomPainter {
  const DiaryPainter({required this.open});

  final bool open;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * .92),
        width: w * 1.05,
        height: h * .18,
      ),
      Paint()
        ..color = AppColors.black.withValues(alpha: .55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    if (open) {
      for (final side in [-1.0, 1.0]) {
        final page = Path()
          ..moveTo(w / 2, h * .2)
          ..lineTo(w / 2 + side * w * .46, h * .12)
          ..lineTo(w / 2 + side * w * .5, h * .86)
          ..lineTo(w / 2, h * .9)
          ..close();
        canvas.drawPath(
          page,
          PaintKit.vertical(Rect.fromLTWH(0, h * .1, w, h * .8), const [
            Color(0xFFC8BCA2),
            Color(0xFF9A8E76),
          ]),
        );
        final ink = PaintKit.stroke(AppColors.ink.withValues(alpha: .55), .8);
        for (var i = 0; i < 6; i++) {
          final y = h * (.26 + i * .1);
          canvas.drawLine(
            Offset(w / 2 + side * w * .06, y),
            Offset(w / 2 + side * w * .4, y - h * .01 * side),
            ink,
          );
        }
      }
      canvas.drawLine(
        Offset(w / 2, h * .2),
        Offset(w / 2, h * .9),
        PaintKit.stroke(AppColors.black.withValues(alpha: .5), 1.5),
      );
      return;
    }

    // Closed: pages (thickness) under the cover.
    final pages = Rect.fromLTWH(w * .06, h * .58, w * .88, h * .28);
    canvas.drawRect(pages, PaintKit.fill(const Color(0xFFB8AC92)));
    final lines = PaintKit.stroke(AppColors.black.withValues(alpha: .2), .6);
    for (var i = 1; i < 4; i++) {
      final y = pages.top + pages.height * i / 4;
      canvas.drawLine(Offset(pages.left, y), Offset(pages.right, y), lines);
    }
    final cover = Path()
      ..moveTo(w * .1, h * .1)
      ..lineTo(w * .9, h * .1)
      ..lineTo(w * .98, h * .6)
      ..lineTo(w * .02, h * .6)
      ..close();
    canvas.drawPath(
      cover,
      PaintKit.wood(
        Rect.fromLTWH(0, h * .1, w, h * .5),
        dark: const Color(0xFF2A100C),
        base: const Color(0xFF4A1E16),
        light: const Color(0xFF5E2A1E),
      ),
    );
    // Strap and lock.
    canvas.drawRect(
      Rect.fromLTWH(w * .62, h * .1, w * .12, h * .8),
      PaintKit.fill(const Color(0xFF1E0C08)),
    );
    final lock = Rect.fromLTWH(w * .58, h * .4, w * .2, h * .26);
    canvas.drawRect(
      lock,
      PaintKit.vertical(lock, const [Color(0xFFB09868), AppColors.brass]),
    );
    for (final dx in [.33, .67]) {
      canvas.drawCircle(
        Offset(lock.left + lock.width * dx, lock.center.dy),
        lock.width * .14,
        PaintKit.fill(const Color(0xFF3A2A14)),
      );
    }
  }

  @override
  bool shouldRepaint(DiaryPainter oldDelegate) => oldDelegate.open != open;
}

/// A squat glass inkwell with a quill standing in it.
class InkwellPainter extends CustomPainter {
  const InkwellPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * .97),
        width: w * 1.1,
        height: h * .06,
      ),
      Paint()
        ..color = AppColors.black.withValues(alpha: .55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Quill.
    final shaft = Path()
      ..moveTo(w * .5, h * .66)
      ..quadraticBezierTo(w * .62, h * .3, w * .95, 0);
    canvas.drawPath(shaft, PaintKit.stroke(const Color(0xFFCFC6B8), 1.2));
    final vane = Path()
      ..moveTo(w * .58, h * .42)
      ..quadraticBezierTo(w * .45, h * .15, w * .95, 0)
      ..quadraticBezierTo(w * 1.05, h * .2, w * .62, h * .44)
      ..close();
    canvas.drawPath(
      vane,
      PaintKit.fill(const Color(0xFF9A9286).withValues(alpha: .85)),
    );

    // Bottle.
    final bottle = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .06, h * .66, w * .88, h * .32),
      Radius.circular(w * .2),
    );
    canvas.drawRRect(
      bottle,
      PaintKit.vertical(bottle.outerRect, const [
        Color(0xFF2A3036),
        Color(0xFF0A0C0E),
      ]),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * .32, h * .6, w * .36, h * .08),
      PaintKit.fill(const Color(0xFF1A1E22)),
    );
    canvas.drawLine(
      Offset(w * .22, h * .72),
      Offset(w * .2, h * .9),
      PaintKit.stroke(AppColors.bone.withValues(alpha: .25), 1.4),
    );
  }

  @override
  bool shouldRepaint(InkwellPainter oldDelegate) => false;
}

/// A floorboard, seen in perspective. One end sits a little proud — it is
/// loose. Once [lifted], the dark gap beneath shows six marks and a knife.
class FloorboardPainter extends CustomPainter {
  const FloorboardPainter({required this.lifted});

  final bool lifted;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final board = Path()
      ..moveTo(w * .1, h * .1)
      ..lineTo(w * .9, h * .1)
      ..lineTo(w, h * .9)
      ..lineTo(0, h * .9)
      ..close();

    if (!lifted) {
      canvas.drawPath(
        board,
        PaintKit.vertical(Rect.fromLTWH(0, h * .1, w, h * .8), const [
          Color(0xFF1A130E),
          Color(0xFF241A12),
        ]),
      );
      // Grain running along the board, towards the back of the room.
      final grain = PaintKit.stroke(AppColors.black.withValues(alpha: .35), 1);
      for (final t in [.3, .55, .78]) {
        canvas.drawLine(
          Offset(w * (.1 + .8 * t), h * .1),
          Offset(w * t, h * .9),
          grain,
        );
      }
      canvas.drawPath(
        board,
        PaintKit.stroke(AppColors.black.withValues(alpha: .7), 1.5),
      );
      // The raised end catches a sliver of light.
      canvas.drawLine(
        Offset(w * .1, h * .1),
        Offset(w * .9, h * .1),
        PaintKit.stroke(AppColors.bone.withValues(alpha: .14), 1.2),
      );
      for (final x in [.2, .8]) {
        canvas.drawCircle(
          Offset(w * x, h * .5),
          w * .012,
          PaintKit.fill(AppColors.ash.withValues(alpha: .4)),
        );
      }
      return;
    }

    // The gap beneath.
    canvas.drawPath(board, PaintKit.fill(const Color(0xFF030202)));
    final cut = PaintKit.stroke(AppColors.bone.withValues(alpha: .3), 1);
    for (var i = 0; i < 6; i++) {
      final x = w * (.2 + i * .07);
      canvas.drawLine(Offset(x, h * .35), Offset(x - w * .01, h * .7), cut);
    }
    // The knife.
    canvas.drawLine(
      Offset(w * .66, h * .62),
      Offset(w * .86, h * .5),
      PaintKit.stroke(const Color(0xFF8A8A88), h * .08),
    );
    canvas.drawLine(
      Offset(w * .56, h * .68),
      Offset(w * .66, h * .62),
      PaintKit.stroke(const Color(0xFF2A1A10), h * .12),
    );
    // The board itself, propped up on its far edge.
    final raised = Path()
      ..moveTo(w * .1, h * .1)
      ..lineTo(w * .9, h * .1)
      ..lineTo(w * .86, -h * .9)
      ..lineTo(w * .14, -h * .9)
      ..close();
    canvas.drawPath(
      raised,
      PaintKit.vertical(Rect.fromLTWH(0, -h * .9, w, h), const [
        Color(0xFF120D09),
        Color(0xFF2A1E14),
      ]),
    );
    canvas.drawPath(
      raised,
      PaintKit.stroke(AppColors.black.withValues(alpha: .7), 1.2),
    );
  }

  @override
  bool shouldRepaint(FloorboardPainter oldDelegate) =>
      oldDelegate.lifted != lifted;
}
