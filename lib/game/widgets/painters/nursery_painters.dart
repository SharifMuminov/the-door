import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'paint_kit.dart';

const _clear = Color(0x00000000);
const _porcelain = Color(0xFFE0D6C8);
const _porcelainShade = Color(0xFFA89C8C);

/// An old wooden cradle on rockers, with a hood and a brass name plate.
/// [rock] (-1..1) tilts it on its rockers.
class CradlePainter extends CustomPainter {
  const CradlePainter({this.rock = 0});

  final double rock;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    PaintKit.floorShadow(
      canvas,
      Rect.fromLTWH(w * .06, 0, w * .88, h),
      alpha: .65,
    );

    canvas.save();
    final pivot = Offset(w / 2, h * .96);
    canvas
      ..translate(pivot.dx, pivot.dy)
      ..rotate(rock * .07)
      ..translate(-pivot.dx, -pivot.dy);

    // Rockers.
    final rocker = Path()
      ..moveTo(w * .02, h * .84)
      ..quadraticBezierTo(w * .5, h * 1.03, w * .98, h * .84);
    canvas.drawPath(rocker, PaintKit.stroke(AppColors.woodDark, h * .06));
    canvas.drawPath(
      rocker.shift(Offset(0, -h * .015)),
      PaintKit.stroke(AppColors.woodLight.withValues(alpha: .45), h * .012),
    );

    // Legs from the rockers up to the basket.
    for (final x in [.17, .83]) {
      final leg = Rect.fromLTWH(w * x - w * .025, h * .6, w * .05, h * .3);
      canvas.drawRect(leg, PaintKit.wood(leg));
    }

    // Basket, a little wider at the top. Dark gaps between the spindles.
    final basket = Path()
      ..moveTo(w * .08, h * .3)
      ..lineTo(w * .92, h * .3)
      ..lineTo(w * .86, h * .66)
      ..lineTo(w * .14, h * .66)
      ..close();
    final basketRect = Rect.fromLTWH(w * .08, h * .3, w * .84, h * .36);
    canvas.drawPath(basket, PaintKit.wood(basketRect));
    canvas.save();
    canvas.clipPath(basket);
    final gap = PaintKit.fill(AppColors.black.withValues(alpha: .78));
    for (var i = 0; i < 9; i++) {
      final x = w * (.16 + i * .085);
      canvas.drawRect(Rect.fromLTWH(x, h * .36, w * .034, h * .23), gap);
    }
    PaintKit.grain(canvas, basketRect, lines: 5, seed: 41);
    canvas.restore();

    final rail = Rect.fromLTWH(w * .05, h * .27, w * .9, h * .06);
    canvas.drawRect(rail, PaintKit.wood(rail));
    canvas.drawLine(
      rail.topLeft,
      rail.topRight,
      PaintKit.stroke(AppColors.bone.withValues(alpha: .08), 1),
    );
    final bottomRail = Rect.fromLTWH(w * .12, h * .61, w * .76, h * .05);
    canvas.drawRect(bottomRail, PaintKit.wood(bottomRail));

    // Hood over the head end.
    final hood = Path()
      ..moveTo(w * .05, h * .3)
      ..quadraticBezierTo(w * .03, h * .02, w * .3, h * .03)
      ..quadraticBezierTo(w * .36, h * .16, w * .35, h * .3)
      ..close();
    canvas.drawPath(
      hood,
      PaintKit.vertical(Rect.fromLTWH(0, 0, w * .36, h * .3), const [
        Color(0xFF3E2C2A),
        Color(0xFF1E1513),
      ]),
    );
    final rib = PaintKit.stroke(AppColors.black.withValues(alpha: .4), 1);
    for (final t in [.35, .6, .82]) {
      canvas.drawLine(
        Offset(w * (.05 + .25 * t), h * (.3 - .27 * t)),
        Offset(w * (.35 - .02 * t), h * .3),
        rib,
      );
    }

    // A blanket spilling over the rail.
    final blanket = Path()
      ..moveTo(w * .42, h * .28)
      ..quadraticBezierTo(w * .56, h * .2, w * .72, h * .28)
      ..lineTo(w * .75, h * .47)
      ..quadraticBezierTo(w * .67, h * .52, w * .61, h * .45)
      ..quadraticBezierTo(w * .53, h * .41, w * .45, h * .47)
      ..close();
    canvas.drawPath(
      blanket,
      PaintKit.vertical(Rect.fromLTWH(w * .4, h * .2, w * .36, h * .3), const [
        Color(0xFF9A8E80),
        Color(0xFF5A5148),
      ]),
    );

    // Brass name plate.
    final plate = Rect.fromCenter(
      center: Offset(w * .5, h * .56),
      width: w * .15,
      height: h * .07,
    );
    canvas.drawRect(
      plate,
      PaintKit.vertical(plate, const [Color(0xFFA08A5C), AppColors.brass]),
    );
    canvas.drawRect(
      plate,
      PaintKit.stroke(AppColors.black.withValues(alpha: .5), 1),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CradlePainter oldDelegate) => oldDelegate.rock != rock;
}

/// A lacquered music box with its lid open. While [playing], the tiny
/// dancer turns, the key unwinds and notes drift up.
class MusicBoxPainter extends CustomPainter {
  const MusicBoxPainter({required this.playing, this.phase = 0});

  final bool playing;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final f = phase * math.pi * 2;

    if (playing) {
      final c = Offset(w / 2, h * .5);
      canvas.drawCircle(
        c,
        w * 1.3,
        PaintKit.radial(c, w * 1.3, [
          AppColors.ember.withValues(alpha: .1),
          _clear,
        ]),
      );
    }

    // Lid, open and tilted back: dark velvet and a small round mirror.
    final lid = Path()
      ..moveTo(w * .08, h * .56)
      ..lineTo(w * .92, h * .56)
      ..lineTo(w * .84, h * .1)
      ..lineTo(w * .16, h * .1)
      ..close();
    canvas.drawPath(
      lid,
      PaintKit.vertical(Rect.fromLTWH(0, h * .1, w, h * .46), const [
        Color(0xFF3E161A),
        Color(0xFF1E090B),
      ]),
    );
    canvas.drawPath(lid, PaintKit.stroke(AppColors.brass, w * .025));
    final mirror = Rect.fromCenter(
      center: Offset(w * .5, h * .3),
      width: w * .34,
      height: h * .22,
    );
    canvas.drawOval(
      mirror,
      PaintKit.vertical(mirror, const [AppColors.glass, AppColors.glassDark]),
    );
    canvas.drawOval(mirror, PaintKit.stroke(AppColors.brass, 1));

    // Box.
    final body = Rect.fromLTWH(w * .04, h * .56, w * .92, h * .42);
    canvas.drawRect(
      body.shift(const Offset(1.5, 2.5)),
      Paint()
        ..color = AppColors.black.withValues(alpha: .6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRect(
      body,
      PaintKit.wood(
        body,
        dark: const Color(0xFF2A1210),
        base: const Color(0xFF4E2219),
        light: const Color(0xFF6E3626),
      ),
    );
    final trim = PaintKit.fill(AppColors.brass);
    canvas.drawRect(
      Rect.fromLTWH(body.left, body.top, body.width, h * .035),
      trim,
    );
    canvas.drawRect(
      Rect.fromLTWH(body.left, body.bottom - h * .03, body.width, h * .03),
      trim,
    );
    // Inlaid flower on the front.
    final centre = Offset(w * .5, h * .78);
    final petal = PaintKit.fill(const Color(0xFFB09868).withValues(alpha: .7));
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      canvas.drawCircle(
        centre + Offset(math.cos(a), math.sin(a)) * w * .05,
        w * .035,
        petal,
      );
    }
    canvas.drawCircle(centre, w * .028, PaintKit.fill(AppColors.ember));

    // The dancer, turning on her spindle.
    final turn = playing ? math.cos(f * 2) : 1.0;
    final base = Offset(w * .5, h * .56);
    canvas.drawLine(
      base,
      base - Offset(0, h * .05),
      PaintKit.stroke(AppColors.brass, 1.2),
    );
    canvas.save();
    canvas.translate(base.dx, base.dy - h * .05);
    canvas.scale(math.max(.22, turn.abs()), 1);
    final porcelain = PaintKit.fill(_porcelain.withValues(alpha: .92));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -h * .05),
        width: w * .24,
        height: h * .06,
      ),
      porcelain,
    );
    canvas.drawLine(
      Offset(0, -h * .05),
      Offset(0, -h * .2),
      PaintKit.stroke(_porcelain, w * .035),
    );
    canvas.drawCircle(Offset(0, -h * .23), w * .04, porcelain);
    final arms = Path()
      ..moveTo(-w * .07, -h * .14)
      ..quadraticBezierTo(-w * .02, -h * .32, w * .07, -h * .14);
    canvas.drawPath(arms, PaintKit.stroke(_porcelain, w * .018));
    canvas.restore();

    // Winding key on the side.
    final keyPivot = Offset(w * .98, h * .76);
    canvas.save();
    canvas.translate(keyPivot.dx, keyPivot.dy);
    canvas.rotate(playing ? -f : 0);
    final keyPaint = PaintKit.fill(const Color(0xFF9A8458));
    canvas.drawCircle(Offset(0, -w * .05), w * .035, keyPaint);
    canvas.drawCircle(Offset(0, w * .05), w * .035, keyPaint);
    canvas.drawCircle(Offset.zero, w * .02, keyPaint);
    canvas.restore();

    // Notes drifting up.
    if (!playing) return;
    for (var i = 0; i < 3; i++) {
      final t = (phase * 1.5 + i / 3) % 1;
      final p = Offset(
        w * (.28 + .22 * i) + math.sin(t * 6 + i) * w * .06,
        h * .45 - t * h * .7,
      );
      final a = math.sin(t * math.pi) * .55;
      final ink = AppColors.bone.withValues(alpha: a);
      canvas.drawOval(
        Rect.fromCenter(center: p, width: w * .07, height: w * .05),
        PaintKit.fill(ink),
      );
      canvas.drawLine(
        p + Offset(w * .03, 0),
        p + Offset(w * .03, -h * .1),
        PaintKit.stroke(ink, 1),
      );
    }
  }

  @override
  bool shouldRepaint(MusicBoxPainter oldDelegate) =>
      oldDelegate.playing != playing || oldDelegate.phase != phase;
}

/// A porcelain doll in a faded red dress, hands clasped in her lap.
///
/// [fingers] (0..3) opens the hands a little at a time; while
/// [holdingKey], something brass glints between them. When [staring],
/// the head turns towards the viewer and the eyes go black.
class DollPainter extends CustomPainter {
  const DollPainter({
    required this.fingers,
    required this.holdingKey,
    this.staring = false,
    this.smiling = false,
  });

  final int fingers;
  final bool holdingKey;
  final bool staring;
  final bool smiling;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .5, h * .97),
        width: w * 1.05,
        height: h * .07,
      ),
      Paint()
        ..color = AppColors.black.withValues(alpha: .6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Legs stretched out towards us: socks and little black shoes.
    for (final x in [.34, .66]) {
      canvas.drawRect(
        Rect.fromLTWH(w * x - w * .07, h * .82, w * .14, h * .08),
        PaintKit.fill(const Color(0xFFCFC6B8)),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * x, h * .93),
          width: w * .2,
          height: h * .07,
        ),
        PaintKit.fill(const Color(0xFF0E0C0C)),
      );
    }

    // Dress.
    final dress = Path()
      ..moveTo(w * .36, h * .43)
      ..lineTo(w * .64, h * .43)
      ..quadraticBezierTo(w * .96, h * .72, w * .94, h * .88)
      ..lineTo(w * .06, h * .88)
      ..quadraticBezierTo(w * .04, h * .72, w * .36, h * .43)
      ..close();
    final dressRect = Rect.fromLTWH(0, h * .43, w, h * .45);
    canvas.drawPath(
      dress,
      PaintKit.vertical(dressRect, const [
        Color(0xFF6E2C30),
        Color(0xFF3A1416),
      ]),
    );
    // Lace hem and collar.
    final lace = PaintKit.stroke(
      const Color(0xFFCFC6B8).withValues(alpha: .55),
      h * .012,
    );
    final hem = Path()..moveTo(w * .07, h * .875);
    for (var x = .07; x < .93; x += .07) {
      hem.quadraticBezierTo(w * (x + .035), h * .905, w * (x + .07), h * .875);
    }
    canvas.drawPath(hem, lace);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * .5, h * .43),
        width: w * .34,
        height: h * .07,
      ),
      0,
      math.pi,
      false,
      lace,
    );

    // Arms down to the lap; the hands part as the fingers are opened.
    final spread = holdingKey ? fingers / 3 * w * .07 : w * .13;
    final skin = PaintKit.stroke(_porcelain, w * .09);
    for (final side in [-1.0, 1.0]) {
      final arm = Path()
        ..moveTo(w * (.5 + side * .16), h * .46)
        ..quadraticBezierTo(
          w * (.5 + side * .26),
          h * .58,
          w * .5 + side * (w * .05 + spread),
          h * .64,
        );
      canvas.drawPath(arm, skin);
    }
    if (holdingKey) {
      // The key, peeking out more with every finger.
      final peek = .4 + .2 * fingers;
      final key = PaintKit.fill(
        const Color(0xFFC8A868).withValues(alpha: peek.clamp(0, 1)),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(w * .5, h * .67),
          width: w * .035,
          height: h * .07,
        ),
        key,
      );
      canvas.drawCircle(Offset(w * .5, h * .625), w * .035, key);
    }
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(w * .5 + side * (w * .04 + spread), h * .645),
        w * .055,
        PaintKit.radial(
          Offset(w * .5 + side * (w * .04 + spread), h * .63),
          w * .07,
          const [_porcelain, _porcelainShade],
        ),
      );
    }

    // Head, tilted towards you when it stares.
    final neck = Offset(w * .5, h * .42);
    canvas.save();
    canvas.translate(neck.dx, neck.dy);
    canvas.rotate(staring ? -.22 : .06);
    canvas.translate(-neck.dx, -neck.dy);

    final head = Rect.fromCenter(
      center: Offset(w * .5, h * .27),
      width: w * .42,
      height: h * .27,
    );
    // Hair behind the head.
    canvas.drawOval(
      head.inflate(w * .04).translate(0, h * .01),
      PaintKit.fill(const Color(0xFF241812)),
    );
    canvas.drawOval(
      head,
      PaintKit.radial(head.center - Offset(w * .06, h * .04), w * .3, const [
        _porcelain,
        _porcelainShade,
      ]),
    );
    // Fringe.
    final fringe = Path()
      ..moveTo(head.left - w * .01, head.top + head.height * .45)
      ..quadraticBezierTo(
        head.left,
        head.top - head.height * .08,
        head.center.dx,
        head.top - head.height * .04,
      )
      ..quadraticBezierTo(
        head.right,
        head.top - head.height * .08,
        head.right + w * .01,
        head.top + head.height * .45,
      )
      ..lineTo(head.right - w * .04, head.top + head.height * .3)
      ..lineTo(head.left + w * .04, head.top + head.height * .3)
      ..close();
    canvas.drawPath(fringe, PaintKit.fill(const Color(0xFF2A1C14)));

    // Cheeks.
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(head.center.dx + side * w * .12, head.center.dy + h * .04),
        w * .045,
        PaintKit.fill(const Color(0xFFB0605A).withValues(alpha: .28)),
      );
    }

    // Eyes.
    final eyeY = head.center.dy + h * .005;
    for (final side in [-1.0, 1.0]) {
      final e = Offset(head.center.dx + side * w * .085, eyeY);
      if (staring) {
        canvas.drawOval(
          Rect.fromCenter(center: e, width: w * .1, height: h * .05),
          PaintKit.fill(const Color(0xFF050303)),
        );
        canvas.drawCircle(
          e + Offset(-w * .015, -h * .008),
          w * .012,
          PaintKit.fill(AppColors.bone.withValues(alpha: .8)),
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: e, width: w * .07, height: h * .028),
          PaintKit.fill(const Color(0xFF1A1210)),
        );
      }
    }

    // Mouth: a small painted bow — or a smile that wasn't there before.
    final mouthY = head.center.dy + h * .075;
    if (smiling) {
      final smile = Path()
        ..moveTo(head.center.dx - w * .09, mouthY - h * .008)
        ..quadraticBezierTo(
          head.center.dx,
          mouthY + h * .035,
          head.center.dx + w * .09,
          mouthY - h * .008,
        );
      canvas.drawPath(smile, PaintKit.stroke(const Color(0xFF5A1414), 1.6));
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(head.center.dx, mouthY),
          width: w * .06,
          height: h * .014,
        ),
        PaintKit.fill(const Color(0xFF8A2A2A)),
      );
    }

    // A hairline crack across the forehead.
    final crack = Path()
      ..moveTo(head.center.dx + w * .02, head.top + head.height * .32)
      ..lineTo(head.center.dx + w * .07, head.top + head.height * .42)
      ..lineTo(head.center.dx + w * .05, head.top + head.height * .5)
      ..lineTo(head.center.dx + w * .11, head.top + head.height * .58);
    canvas.drawPath(
      crack,
      PaintKit.stroke(AppColors.ink.withValues(alpha: .55), .8),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(DollPainter oldDelegate) =>
      oldDelegate.fingers != fingers ||
      oldDelegate.holdingKey != holdingKey ||
      oldDelegate.staring != staring ||
      oldDelegate.smiling != smiling;
}
