import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_colors.dart';
import 'paint_kit.dart';

const _clear = Color(0x00000000);
const _gilt = [
  Color(0xFF8A7040),
  Color(0xFF3E2E16),
  Color(0xFF9A7E48),
  Color(0xFF2E2210),
];

/// Who is painted in a portrait.
enum Sitter { elias, marta, anna }

/// An oval family portrait in a gilt frame, with a brass name plate.
///
/// The real dead look away. The one that is [watching] looks straight at
/// you — and every few seconds ([blink], a 0..1 loop) it blinks. Once it
/// is [revealed], the face underneath shows.
class PortraitPainter extends CustomPainter {
  const PortraitPainter({
    required this.sitter,
    required this.plate,
    this.watching = false,
    this.blink = .5,
    this.moved = false,
    this.revealed = false,
  });

  final Sitter sitter;
  final String plate;
  final bool watching;
  final double blink;

  /// Someone has looked behind it: it hangs crooked.
  final bool moved;
  final bool revealed;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final frame = Rect.fromLTWH(0, 0, w, h * .84);
    final nail = Offset(w / 2, -h * .06);
    canvas.drawCircle(nail, 2, PaintKit.fill(AppColors.ash));

    if (moved) {
      // A clean patch of wallpaper where it used to hang.
      canvas.drawRect(
        frame,
        PaintKit.fill(AppColors.bone.withValues(alpha: .045)),
      );
      canvas.save();
      canvas
        ..translate(nail.dx, nail.dy)
        ..rotate(.13)
        ..translate(-nail.dx, -nail.dy + h * .03);
    }

    final wire = PaintKit.stroke(AppColors.ash.withValues(alpha: .6), 1);
    canvas.drawLine(nail, Offset(w * .22, h * .05), wire);
    canvas.drawLine(nail, Offset(w * .78, h * .05), wire);

    canvas.drawRect(
      frame.shift(const Offset(3, 5)),
      Paint()
        ..color = AppColors.black.withValues(alpha: .6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gilt,
        ).createShader(frame),
    );
    final mat = frame.deflate(w * .09);
    canvas.drawRect(
      mat,
      PaintKit.stroke(AppColors.black.withValues(alpha: .55), 2),
    );
    canvas.drawRect(mat, PaintKit.fill(const Color(0xFF14100C)));

    final oval = mat.deflate(w * .025);
    canvas.save();
    canvas.clipPath(Path()..addOval(oval));
    _sitter(canvas, oval);
    // Varnish and age.
    canvas.drawRect(
      oval,
      PaintKit.radial(oval.center, oval.height * .62, [
        _clear,
        AppColors.black.withValues(alpha: .55),
      ]),
    );
    final crackle = PaintKit.stroke(AppColors.black.withValues(alpha: .25), .7);
    final rnd = math.Random(sitter.index + 11);
    for (var i = 0; i < 6; i++) {
      final a = Offset(
        oval.left + oval.width * rnd.nextDouble(),
        oval.top + oval.height * rnd.nextDouble(),
      );
      canvas.drawLine(
        a,
        a + Offset((rnd.nextDouble() - .5) * w * .3, rnd.nextDouble() * h * .1),
        crackle,
      );
    }
    canvas.restore();
    canvas.drawOval(
      oval,
      PaintKit.stroke(const Color(0xFF9A7E48).withValues(alpha: .6), 1.2),
    );

    // Name plate.
    final plateRect = Rect.fromCenter(
      center: Offset(w / 2, h * .925),
      width: w * .7,
      height: h * .1,
    );
    canvas.drawRect(
      plateRect,
      PaintKit.vertical(plateRect, const [Color(0xFFA08A5C), AppColors.brass]),
    );
    canvas.drawRect(
      plateRect,
      PaintKit.stroke(AppColors.black.withValues(alpha: .5), 1),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: plate,
        style: AppText.label.copyWith(
          fontSize: plateRect.height * .55,
          letterSpacing: 1,
          color: AppColors.ink,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: plateRect.width);
    tp.paint(
      canvas,
      Offset(
        plateRect.center.dx - tp.width / 2,
        plateRect.center.dy - tp.height / 2,
      ),
    );
    tp.dispose();

    if (moved) canvas.restore();
  }

  void _sitter(Canvas canvas, Rect c) {
    final cw = c.width, ch = c.height;
    final cx = c.center.dx;
    canvas.drawRect(
      c,
      PaintKit.radial(c.center - Offset(0, ch * .1), ch * .7, const [
        Color(0xFF3E3428),
        Color(0xFF15110D),
      ]),
    );

    final clothes = switch (sitter) {
      Sitter.elias => const Color(0xFF16130F),
      Sitter.marta => const Color(0xFF221619),
      Sitter.anna => const Color(0xFF262A32),
    };
    final skin = revealed ? const Color(0xFF8A8A84) : const Color(0xFFAE967E);
    final hair = switch (sitter) {
      Sitter.elias => const Color(0xFF4A4440),
      Sitter.marta => const Color(0xFF6A645C),
      Sitter.anna => const Color(0xFF2A1A12),
    };

    final headH = ch * (revealed ? .5 : .4);
    final head = Rect.fromCenter(
      center: Offset(cx, c.top + ch * .4 + (revealed ? ch * .04 : 0)),
      width: cw * .38,
      height: headH,
    );

    // Long hair falls behind the shoulders.
    if (sitter == Sitter.anna) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            head.left - cw * .05,
            head.top + headH * .1,
            head.right + cw * .05,
            c.top + ch * .82,
          ),
          Radius.circular(cw * .1),
        ),
        PaintKit.fill(hair),
      );
    }

    // Shoulders.
    final shoulders = Path()
      ..moveTo(c.left, c.bottom)
      ..quadraticBezierTo(
        c.left + cw * .08,
        c.top + ch * .72,
        cx - cw * .14,
        c.top + ch * .66,
      )
      ..lineTo(cx + cw * .14, c.top + ch * .66)
      ..quadraticBezierTo(
        c.right - cw * .08,
        c.top + ch * .72,
        c.right,
        c.bottom,
      )
      ..close();
    canvas.drawPath(shoulders, PaintKit.fill(clothes));
    // Collars.
    switch (sitter) {
      case Sitter.elias:
        final v = Path()
          ..moveTo(cx - cw * .1, c.top + ch * .66)
          ..lineTo(cx, c.top + ch * .82)
          ..lineTo(cx + cw * .1, c.top + ch * .66)
          ..close();
        canvas.drawPath(v, PaintKit.fill(const Color(0xFF8E887C)));
      case Sitter.marta:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, c.top + ch * .64),
            width: cw * .2,
            height: ch * .07,
          ),
          PaintKit.fill(const Color(0xFF7A746A)),
        );
      case Sitter.anna:
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx, c.top + ch * .66),
            width: cw * .3,
            height: ch * .1,
          ),
          0,
          math.pi,
          false,
          PaintKit.stroke(const Color(0xFF8E887C), 1.5),
        );
    }
    // Neck.
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, head.bottom),
        width: cw * .13,
        height: ch * .12,
      ),
      PaintKit.fill(Color.lerp(skin, AppColors.black, .25)!),
    );

    // Hair behind the head, then the face.
    if (sitter == Sitter.marta) {
      canvas.drawCircle(
        Offset(cx, head.top - headH * .05),
        cw * .11,
        PaintKit.fill(hair),
      );
    }
    canvas.drawOval(head.inflate(cw * .02), PaintKit.fill(hair));
    canvas.drawOval(
      head,
      PaintKit.radial(head.center - Offset(cw * .06, headH * .12), cw * .3, [
        Color.lerp(skin, AppColors.bone, .15)!,
        Color.lerp(skin, AppColors.black, .35)!,
      ]),
    );
    // Hairline over the forehead.
    canvas.drawArc(
      head.inflate(cw * .01),
      math.pi * 1.08,
      math.pi * .84,
      false,
      PaintKit.stroke(hair, headH * .16),
    );
    if (sitter == Sitter.elias) {
      // A full beard from cheek to cheek; the moustache sits flat on top,
      // so nothing in it reads as a smile.
      final top = head.center.dy + headH * .1;
      final beard = Path()
        ..moveTo(head.left + cw * .015, head.center.dy - headH * .02)
        ..quadraticBezierTo(
          head.left - cw * .01,
          head.bottom + headH * .05,
          head.center.dx,
          head.bottom + headH * .16,
        )
        ..quadraticBezierTo(
          head.right + cw * .01,
          head.bottom + headH * .05,
          head.right - cw * .015,
          head.center.dy - headH * .02,
        )
        ..lineTo(head.right - cw * .06, top)
        ..quadraticBezierTo(
          head.center.dx,
          top - headH * .05,
          head.left + cw * .06,
          top,
        )
        ..close();
      canvas.drawPath(beard, PaintKit.fill(hair));
      canvas.drawLine(
        Offset(cx - cw * .04, top + headH * .12),
        Offset(cx + cw * .04, top + headH * .12),
        PaintKit.stroke(const Color(0xFF241E1A), 1.2),
      );
    }

    _eyes(canvas, head);

    // Mouth.
    final mouthY = head.center.dy + headH * .24;
    if (revealed) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, mouthY + headH * .06),
          width: cw * .1,
          height: headH * .3,
        ),
        PaintKit.fill(const Color(0xFF040202)),
      );
    } else if (sitter != Sitter.elias) {
      canvas.drawLine(
        Offset(cx - cw * .05, mouthY),
        Offset(cx + cw * .05, mouthY),
        PaintKit.stroke(const Color(0xFF4A2A22), 1.2),
      );
    }
  }

  void _eyes(Canvas canvas, Rect head) {
    final eyeY = head.center.dy - head.height * .02;
    final gap = head.width * .22;
    // The dead look away from you; it does not.
    final look = switch (sitter) {
      _ when watching => 0.0,
      Sitter.elias => .45,
      Sitter.anna => -.45,
      Sitter.marta => .3,
    };
    final shut =
        watching && !revealed && (blink < .035 || (blink > .07 && blink < .09));
    for (final side in [-1.0, 1.0]) {
      final e = Offset(head.center.dx + side * gap, eyeY);
      final r = head.width * .09;
      if (revealed) {
        final hole = Path()
          ..addOval(
            Rect.fromCenter(center: e, width: r * 2.2, height: r * 3.4),
          );
        canvas.drawPath(hole, PaintKit.fill(const Color(0xFF020101)));
        canvas.drawLine(
          e + Offset(0, r * 1.5),
          e + Offset(side * r * .3, r * 4.5),
          PaintKit.stroke(const Color(0xFF020101), r * .5),
        );
        continue;
      }
      if (shut) {
        canvas.drawLine(
          e - Offset(r, 0),
          e + Offset(r, 0),
          PaintKit.stroke(const Color(0xFF2A1E18), 1.2),
        );
        continue;
      }
      canvas.drawOval(
        Rect.fromCenter(center: e, width: r * 2, height: r * 1.15),
        PaintKit.fill(const Color(0xFFCFC6B8).withValues(alpha: .8)),
      );
      canvas.drawCircle(
        e + Offset(look * r * .9, 0),
        r * (watching ? .55 : .45),
        PaintKit.fill(const Color(0xFF0E0A08)),
      );
    }
  }

  @override
  bool shouldRepaint(PortraitPainter oldDelegate) =>
      oldDelegate.sitter != sitter ||
      oldDelegate.plate != plate ||
      oldDelegate.watching != watching ||
      oldDelegate.blink != blink ||
      oldDelegate.moved != moved ||
      oldDelegate.revealed != revealed;
}

/// A gilt frame with nothing in it, leaning against the wall.
/// The only thing in the room without dust.
class EmptyFramePainter extends CustomPainter {
  const EmptyFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    PaintKit.floorShadow(canvas, Offset.zero & size, alpha: .7);

    // Leaning back: the top edge is a little narrower.
    final outer = Path()
      ..moveTo(w * .06, 0)
      ..lineTo(w * .94, 0)
      ..lineTo(w, h * .97)
      ..lineTo(0, h * .97)
      ..close();
    final inner = Path()
      ..moveTo(w * .2, h * .13)
      ..lineTo(w * .8, h * .13)
      ..lineTo(w * .84, h * .82)
      ..lineTo(w * .16, h * .82)
      ..close();

    // The wall shows through the empty middle.
    canvas.drawPath(
      inner,
      PaintKit.vertical(Rect.fromLTWH(0, h * .13, w, h * .69), const [
        Color(0xFF0C0A09),
        Color(0xFF1A1513),
      ]),
    );
    final border = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(outer, Offset.zero)
      ..addPath(inner, Offset.zero);
    canvas.drawPath(
      border,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB09058),
            Color(0xFF5A4420),
            Color(0xFFC0A060),
            Color(0xFF3E2E14),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      inner,
      PaintKit.stroke(AppColors.black.withValues(alpha: .6), 1.5),
    );
    // Scratched-out name plate.
    final plate = Rect.fromCenter(
      center: Offset(w / 2, h * .9),
      width: w * .36,
      height: h * .06,
    );
    canvas.drawRect(plate, PaintKit.fill(const Color(0xFF8A7448)));
    final scratch = PaintKit.stroke(AppColors.black.withValues(alpha: .55), .8);
    final rnd = math.Random(17);
    for (var i = 0; i < 7; i++) {
      final y = plate.top + plate.height * rnd.nextDouble();
      canvas.drawLine(
        Offset(plate.left + plate.width * rnd.nextDouble() * .3, y),
        Offset(plate.right - plate.width * rnd.nextDouble() * .3, y + 1),
        scratch,
      );
    }
    // A clean glint along the top.
    canvas.drawLine(
      Offset(w * .1, h * .03),
      Offset(w * .6, h * .03),
      PaintKit.stroke(AppColors.bone.withValues(alpha: .18), 1.2),
    );
  }

  @override
  bool shouldRepaint(EmptyFramePainter oldDelegate) => false;
}

/// One bell of a servants' bell board: a strip of the board with its room
/// label, a coiled spring and a brass bell. [swing] is the bell's angle;
/// [glow] lights it up while it rings.
class ServantBellPainter extends CustomPainter {
  const ServantBellPainter({
    required this.label,
    required this.bellSize,
    this.swing = 0,
    this.glow = 0,
  });

  final String label;

  /// 0 = the smallest, highest bell … 1 = the largest, lowest.
  final double bellSize;
  final double swing;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // The board. Neighbouring bells continue it.
    final board = Rect.fromLTWH(-.5, 0, w + 1, h * .36);
    canvas.drawRect(
      board,
      PaintKit.vertical(board, const [
        AppColors.woodLight,
        AppColors.wood,
        AppColors.woodDark,
      ]),
    );
    canvas.drawLine(
      Offset(0, h * .02),
      Offset(w, h * .02),
      PaintKit.stroke(AppColors.bone.withValues(alpha: .07), 1),
    );
    canvas.drawRect(
      Rect.fromLTWH(-.5, h * .36, w + 1, h * .02),
      PaintKit.fill(AppColors.black.withValues(alpha: .5)),
    );

    // Enamel label.
    final plate = Rect.fromCenter(
      center: Offset(w / 2, h * .19),
      width: w * .8,
      height: h * .14,
    );
    canvas.drawRect(plate, PaintKit.fill(const Color(0xFFA89C84)));
    canvas.drawRect(plate, PaintKit.stroke(AppColors.brass, 1));
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: AppText.label.copyWith(
          fontSize: plate.height * .58,
          letterSpacing: .8,
          color: AppColors.ink,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: plate.width);
    tp.paint(
      canvas,
      Offset(plate.center.dx - tp.width / 2, plate.center.dy - tp.height / 2),
    );
    tp.dispose();

    // Coiled spring.
    final top = Offset(w / 2, h * .38);
    final pivot = Offset(w / 2, h * .54);
    final coil = Path()..moveTo(top.dx, top.dy);
    for (var i = 1; i <= 7; i++) {
      coil.lineTo(
        top.dx + (i.isEven ? -1 : 1) * w * .05,
        top.dy + (pivot.dy - top.dy) * i / 8,
      );
    }
    coil.lineTo(pivot.dx, pivot.dy);
    canvas.drawPath(coil, PaintKit.stroke(const Color(0xFF6A5838), 1.2));

    // The bell.
    canvas.save();
    canvas
      ..translate(pivot.dx, pivot.dy)
      ..rotate(swing);
    final bw = w * (.34 + .22 * bellSize);
    final bh = bw * .82;
    if (glow > 0) {
      canvas.drawCircle(
        Offset(0, bh * .6),
        bw * 1.8,
        PaintKit.radial(Offset(0, bh * .6), bw * 1.8, [
          const Color(0xFFFFD890).withValues(alpha: .55 * glow),
          AppColors.ember.withValues(alpha: .2 * glow),
          _clear,
        ]),
      );
    }
    final bell = Path()
      ..moveTo(-bw * .12, 0)
      ..lineTo(bw * .12, 0)
      ..quadraticBezierTo(bw * .36, bh * .08, bw * .36, bh * .62)
      ..quadraticBezierTo(bw * .38, bh * .86, bw * .5, bh)
      ..lineTo(-bw * .5, bh)
      ..quadraticBezierTo(-bw * .38, bh * .86, -bw * .36, bh * .62)
      ..quadraticBezierTo(-bw * .36, bh * .08, -bw * .12, 0)
      ..close();
    canvas.drawPath(
      bell,
      PaintKit.radial(Offset(-bw * .15, bh * .3), bw * .9, [
        Color.lerp(const Color(0xFFC8A868), const Color(0xFFF0D898), glow)!,
        const Color(0xFF8A6A30),
        const Color(0xFF3A2A10),
      ]),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, bh), width: bw, height: bh * .14),
      PaintKit.fill(const Color(0xFF2A1E0C)),
    );
    // The clapper hangs straight down while the bell swings.
    canvas.drawCircle(
      Offset(-math.sin(swing) * bw * .5, bh * 1.04),
      bw * .08,
      PaintKit.fill(const Color(0xFF4A3A1E)),
    );
    canvas.drawLine(
      Offset(-bw * .2, bh * .2),
      Offset(-bw * .3, bh * .75),
      PaintKit.stroke(AppColors.bone.withValues(alpha: .25), 1.2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ServantBellPainter oldDelegate) =>
      oldDelegate.label != label ||
      oldDelegate.bellSize != bellSize ||
      oldDelegate.swing != swing ||
      oldDelegate.glow != glow;
}

/// A standing coat rack with a man's long coat and a hat.
class CoatPainter extends CustomPainter {
  const CoatPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    PaintKit.floorShadow(
      canvas,
      Rect.fromLTWH(w * .1, 0, w * .8, h),
      alpha: .6,
    );

    // Feet and pole.
    final wood = PaintKit.stroke(AppColors.woodDark, w * .05);
    for (final dx in [-.36, 0.0, .36]) {
      canvas.drawLine(Offset(cx, h * .93), Offset(cx + w * dx, h), wood);
    }
    final pole = Rect.fromLTWH(cx - w * .035, h * .03, w * .07, h * .92);
    canvas.drawRect(pole, PaintKit.wood(pole));
    canvas.drawCircle(
      Offset(cx, h * .03),
      w * .06,
      PaintKit.fill(AppColors.woodLight),
    );
    // Hooks.
    final hook = PaintKit.stroke(AppColors.brass, w * .025);
    for (final side in [-1.0, 1.0]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx + side * w * .12, h * .085),
          width: w * .2,
          height: h * .05,
        ),
        side < 0 ? 0 : math.pi,
        math.pi,
        false,
        hook,
      );
    }

    // Hat on the left hook.
    final hatC = Offset(cx - w * .2, h * .06);
    canvas.drawOval(
      Rect.fromCenter(center: hatC, width: w * .42, height: h * .022),
      PaintKit.fill(const Color(0xFF141210)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: hatC - Offset(0, h * .025),
          width: w * .26,
          height: h * .05,
        ),
        Radius.circular(w * .06),
      ),
      PaintKit.fill(const Color(0xFF1C1916)),
    );

    // The coat.
    final coat = Path()
      ..moveTo(cx - w * .08, h * .1)
      ..quadraticBezierTo(cx - w * .4, h * .12, cx - w * .42, h * .22)
      ..lineTo(cx - w * .46, h * .74)
      ..quadraticBezierTo(cx, h * .78, cx + w * .44, h * .74)
      ..lineTo(cx + w * .4, h * .22)
      ..quadraticBezierTo(cx + w * .38, h * .12, cx + w * .08, h * .1)
      ..close();
    final coatRect = Rect.fromLTWH(cx - w * .46, h * .1, w * .92, h * .68);
    canvas.drawPath(
      coat,
      PaintKit.wood(
        coatRect,
        dark: const Color(0xFF0E0D0C),
        base: const Color(0xFF1E1C1A),
        light: const Color(0xFF2E2B28),
      ),
    );
    final fold = PaintKit.stroke(AppColors.black.withValues(alpha: .5), 1.2);
    for (final x in [-.22, -.05, .16, .3]) {
      canvas.drawLine(
        Offset(cx + w * x, h * .3),
        Offset(cx + w * (x * 1.15), h * .74),
        fold,
      );
    }
    // Lapels and a pocket with a ticket sticking out.
    canvas.drawLine(
      Offset(cx - w * .06, h * .11),
      Offset(cx - w * .02, h * .36),
      PaintKit.stroke(const Color(0xFF34302C), 1.4),
    );
    canvas.drawLine(
      Offset(cx + w * .06, h * .11),
      Offset(cx + w * .02, h * .36),
      PaintKit.stroke(const Color(0xFF34302C), 1.4),
    );
    canvas.drawRect(
      Rect.fromLTWH(cx + w * .1, h * .47, w * .14, h * .025),
      PaintKit.fill(const Color(0xFFB8AC92)),
    );
    canvas.drawRect(
      Rect.fromLTWH(cx + w * .06, h * .49, w * .24, h * .02),
      PaintKit.fill(const Color(0xFF2A2724)),
    );
  }

  @override
  bool shouldRepaint(CoatPainter oldDelegate) => false;
}
