import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_colors.dart';
import 'paint_kit.dart';

const _clear = Color(0x00000000);

/// Wall clock, or a small mantel clock when [tabletop] is true.
class ClockPainter extends CustomPainter {
  const ClockPainter({
    required this.minutes,
    this.tabletop = false,
    this.cracked = false,
    this.sweep,
  });

  /// Minutes since midnight.
  final int minutes;
  final bool tabletop;
  final bool cracked;

  /// 0..1 position of a running second hand, or null when stopped.
  final double? sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    late final Offset c;
    late final double r;

    if (tabletop) {
      PaintKit.floorShadow(canvas, Offset.zero & size, alpha: .6);
      final body = RRect.fromRectAndCorners(
        Rect.fromLTWH(w * .04, h * .06, w * .92, h * .88),
        topLeft: Radius.circular(w * .46),
        topRight: Radius.circular(w * .46),
        bottomLeft: Radius.circular(w * .04),
        bottomRight: Radius.circular(w * .04),
      );
      canvas.drawRRect(body, PaintKit.wood(body.outerRect));
      canvas.drawRect(
        Rect.fromLTWH(0, h * .9, w, h * .1),
        PaintKit.fill(AppColors.woodDark),
      );
      c = Offset(w / 2, h * .46);
      r = w * .34;
    } else {
      c = Offset(w / 2, h / 2);
      r = math.min(w, h) / 2 * .96;
      canvas.drawCircle(
        c + Offset(r * .06, r * .1),
        r,
        Paint()
          ..color = AppColors.black.withValues(alpha: .6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        c,
        r,
        PaintKit.radial(c - Offset(r * .3, r * .3), r * 1.4, [
          AppColors.woodLight,
          AppColors.woodDark,
        ]),
      );
    }

    final face = r * (tabletop ? 1 : .8);
    canvas.drawCircle(
      c,
      face,
      PaintKit.radial(c - Offset(face * .2, face * .25), face * 1.2, [
        const Color(0xFF7A7264),
        const Color(0xFF4A443A),
        const Color(0xFF2A2621),
      ]),
    );
    canvas.drawCircle(
      c,
      face,
      PaintKit.stroke(AppColors.brass.withValues(alpha: .7), face * .06),
    );

    // Hour ticks.
    final tick = PaintKit.stroke(
      AppColors.ink.withValues(alpha: .85),
      face * .045,
    );
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      final dir = Offset(math.sin(a), -math.cos(a));
      final inner = i % 3 == 0 ? .7 : .8;
      canvas.drawLine(c + dir * face * inner, c + dir * face * .9, tick);
    }

    // Hands.
    final m = minutes % 60;
    final hr = (minutes / 60) % 12;
    _hand(canvas, c, hr / 12, face * .48, face * .08, AppColors.ink);
    _hand(canvas, c, m / 60, face * .72, face * .05, AppColors.ink);
    final s = sweep;
    if (s != null) {
      _hand(canvas, c, s, face * .8, face * .02, const Color(0xFF8E1A1A));
    }
    canvas.drawCircle(c, face * .07, PaintKit.fill(AppColors.brass));

    if (cracked) {
      final crack = PaintKit.stroke(AppColors.bone.withValues(alpha: .35), 1);
      final path = Path()
        ..moveTo(c.dx - face * .7, c.dy - face * .5)
        ..lineTo(c.dx - face * .2, c.dy - face * .15)
        ..lineTo(c.dx - face * .3, c.dy + face * .1)
        ..lineTo(c.dx + face * .15, c.dy + face * .35)
        ..lineTo(c.dx + face * .55, c.dy + face * .6)
        ..moveTo(c.dx - face * .2, c.dy - face * .15)
        ..lineTo(c.dx + face * .25, c.dy - face * .55);
      canvas.drawPath(path, crack);
    }

    // Glass glint.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: face * .82),
      math.pi * 1.1,
      math.pi * .35,
      false,
      PaintKit.stroke(AppColors.bone.withValues(alpha: .08), face * .06),
    );
  }

  void _hand(
    Canvas canvas,
    Offset c,
    double turn,
    double length,
    double width,
    Color color,
  ) {
    final a = turn * math.pi * 2;
    canvas.drawLine(
      c - Offset(math.sin(a), -math.cos(a)) * length * .15,
      c + Offset(math.sin(a), -math.cos(a)) * length,
      PaintKit.stroke(color, width),
    );
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) =>
      oldDelegate.minutes != minutes ||
      oldDelegate.cracked != cracked ||
      oldDelegate.sweep != sweep ||
      oldDelegate.tabletop != tabletop;
}

/// A torn note pinned to the wall.
class NotePainter extends CustomPainter {
  const NotePainter({this.seed = 7});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rnd = math.Random(seed);

    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-.07 + rnd.nextDouble() * .04);
    canvas.translate(-w / 2, -h / 2);

    final paper = Path()..moveTo(w * .06, h * .04);
    paper.lineTo(w * .94, h * .06);
    // Torn right and bottom edges.
    for (var i = 1; i <= 6; i++) {
      paper.lineTo(w * (.92 + rnd.nextDouble() * .05), h * (.06 + i * .15));
    }
    for (var i = 1; i <= 7; i++) {
      paper.lineTo(w * (.94 - i * .13), h * (.9 + rnd.nextDouble() * .08));
    }
    paper.close();

    canvas.drawPath(
      paper.shift(const Offset(2, 3)),
      Paint()
        ..color = AppColors.black.withValues(alpha: .55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      paper,
      PaintKit.radial(Offset(w * .45, h * .4), w * .8, [
        const Color(0xFF8E846F),
        const Color(0xFF6E6553),
        const Color(0xFF453E31),
      ]),
    );
    // Stain.
    canvas.drawCircle(
      Offset(w * .7, h * .7),
      w * .16,
      PaintKit.stroke(const Color(0xFF3A2A18).withValues(alpha: .25), 2),
    );
    // Scribbled lines.
    final ink = PaintKit.stroke(AppColors.ink.withValues(alpha: .7), 1.4);
    for (var i = 0; i < 4; i++) {
      final y = h * (.26 + i * .15);
      final len = i == 0 ? .5 : .55 + rnd.nextDouble() * .2;
      final path = Path()..moveTo(w * .2, y);
      for (var x = .2; x < .2 + len; x += .06) {
        path.lineTo(w * x, y + (rnd.nextDouble() - .5) * h * .04);
      }
      canvas.drawPath(path, ink);
    }
    // Pin.
    canvas.drawCircle(
      Offset(w * .5, h * .1),
      w * .06,
      PaintKit.fill(AppColors.bloodDeep),
    );
    canvas.drawCircle(
      Offset(w * .48, h * .085),
      w * .02,
      PaintKit.fill(AppColors.bone.withValues(alpha: .4)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(NotePainter oldDelegate) => oldDelegate.seed != seed;
}

/// Tall arched mirror. Its reflection is subtly wrong from the start:
/// the reflected painting hangs crooked.
class MirrorPainter extends CustomPainter {
  const MirrorPainter({
    required this.distorted,
    required this.apparition,
    this.phase = 0,
  });

  final bool distorted;
  final bool apparition;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final outer = _arch(Rect.fromLTWH(0, 0, w, h));
    final glassRect = Rect.fromLTWH(w * .1, w * .1, w * .8, h - w * .2);
    final glass = _arch(glassRect);

    canvas.drawPath(
      outer.shift(const Offset(3, 5)),
      Paint()
        ..color = AppColors.black.withValues(alpha: .6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      outer,
      PaintKit.wood(
        Offset.zero & size,
        base: const Color(0xFF3A2C1E),
        light: const Color(0xFF5E4A33),
      ),
    );
    canvas.drawPath(
      outer,
      PaintKit.stroke(AppColors.brass.withValues(alpha: .35), 1.2),
    );

    canvas.save();
    canvas.clipPath(glass);
    canvas.drawRect(
      glassRect,
      PaintKit.vertical(glassRect, [
        distorted ? const Color(0xFF221416) : AppColors.glass,
        AppColors.glassDark,
      ]),
    );

    // Reflected room: floor line and the crooked painting.
    final floorY = glassRect.top + glassRect.height * .78;
    final wave = distorted ? glassRect.width * .03 : 0.0;
    final floor = Path()..moveTo(glassRect.left, floorY);
    for (var x = 0.0; x <= 1.0; x += .05) {
      floor.lineTo(
        glassRect.left + glassRect.width * x,
        floorY + math.sin((x * 8 + phase * 6.28)) * wave,
      );
    }
    canvas.drawPath(
      floor,
      PaintKit.stroke(AppColors.bone.withValues(alpha: .07), 1),
    );

    canvas.save();
    final pc = Offset(
      glassRect.left + glassRect.width * .45 + math.sin(phase * 6.28) * wave,
      glassRect.top + glassRect.height * .33,
    );
    canvas.translate(pc.dx, pc.dy);
    canvas.rotate(.2);
    final reflected = Rect.fromCenter(
      center: Offset.zero,
      width: glassRect.width * .4,
      height: glassRect.width * .5,
    );
    canvas.drawRect(
      reflected,
      PaintKit.fill(AppColors.black.withValues(alpha: .35)),
    );
    canvas.drawRect(
      reflected,
      PaintKit.stroke(AppColors.brass.withValues(alpha: .18), 2),
    );
    canvas.restore();

    if (distorted) {
      final ripple = PaintKit.stroke(AppColors.bone.withValues(alpha: .05), 1);
      for (var i = 0; i < 9; i++) {
        final y = glassRect.top + glassRect.height * (i + .5) / 9;
        final p = Path()..moveTo(glassRect.left, y);
        for (var x = 0.0; x <= 1.0; x += .1) {
          p.lineTo(
            glassRect.left + glassRect.width * x,
            y + math.sin(x * 9 + i + phase * 6.28) * glassRect.height * .012,
          );
        }
        canvas.drawPath(p, ripple);
      }
      canvas.drawRect(
        glassRect,
        PaintKit.fill(AppColors.bloodDeep.withValues(alpha: .18)),
      );
    }

    if (apparition) _figure(canvas, glassRect);

    // Silvering streaks.
    final streak = PaintKit.stroke(
      AppColors.bone.withValues(alpha: .06),
      glassRect.width * .12,
    );
    canvas.drawLine(
      Offset(glassRect.left, glassRect.top + glassRect.height * .5),
      Offset(glassRect.right, glassRect.top + glassRect.height * .15),
      streak,
    );
    canvas.drawLine(
      Offset(glassRect.left, glassRect.top + glassRect.height * .75),
      Offset(glassRect.right, glassRect.top + glassRect.height * .45),
      PaintKit.stroke(
        AppColors.bone.withValues(alpha: .03),
        glassRect.width * .05,
      ),
    );
    // Dark, rotten silver at the edges.
    canvas.drawRect(
      glassRect,
      PaintKit.radial(
        glassRect.center,
        glassRect.height * .7,
        [_clear, AppColors.black.withValues(alpha: .6)],
        const [.55, 1],
      ),
    );
    canvas.restore();

    canvas.drawPath(
      glass,
      PaintKit.stroke(AppColors.black.withValues(alpha: .7), 2),
    );
  }

  /// Someone standing behind you.
  void _figure(Canvas canvas, Rect g) {
    final paint = Paint()
      ..color = const Color(0xF2020202)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final cx = g.center.dx + g.width * .08;
    final headY = g.top + g.height * .3;
    final headR = g.width * .15;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, headY),
        width: headR * 1.7,
        height: headR * 2.2,
      ),
      paint,
    );
    final body = Path()
      ..moveTo(cx - headR * .45, headY + headR)
      ..quadraticBezierTo(
        cx - g.width * .45,
        headY + headR * 1.6,
        cx - g.width * .5,
        g.bottom,
      )
      ..lineTo(cx + g.width * .5, g.bottom)
      ..quadraticBezierTo(
        cx + g.width * .45,
        headY + headR * 1.6,
        cx + headR * .45,
        headY + headR,
      )
      ..close();
    canvas.drawPath(body, paint);
    final eye = PaintKit.fill(AppColors.bone.withValues(alpha: .55));
    canvas.drawCircle(
      Offset(cx - headR * .32, headY - headR * .05),
      headR * .07,
      eye,
    );
    canvas.drawCircle(
      Offset(cx + headR * .32, headY - headR * .05),
      headR * .07,
      eye,
    );
  }

  Path _arch(Rect r) {
    final radius = r.width / 2;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + radius)
      ..arcToPoint(
        Offset(r.right, r.top + radius),
        radius: Radius.circular(radius),
      )
      ..lineTo(r.right, r.bottom)
      ..close();
  }

  @override
  bool shouldRepaint(MirrorPainter oldDelegate) =>
      oldDelegate.distorted != distorted ||
      oldDelegate.apparition != apparition ||
      oldDelegate.phase != phase;
}

/// A portrait with the face scratched out. When [moved] it hangs crooked
/// and shows the clean patch of wall behind it.
class PaintingPainter extends CustomPainter {
  const PaintingPainter({required this.moved});

  final bool moved;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final frame = Offset.zero & size;

    // Wire and nail.
    final nail = Offset(w / 2, -h * .1);
    canvas.drawCircle(nail, 2, PaintKit.fill(AppColors.ash));

    if (moved) {
      canvas.drawRect(
        frame,
        PaintKit.fill(AppColors.bone.withValues(alpha: .05)),
      );
      canvas.drawRect(
        frame,
        PaintKit.stroke(AppColors.black.withValues(alpha: .4), 1),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(w * .5, h * .55),
          width: w * .2,
          height: h * .07,
        ),
        PaintKit.fill(AppColors.paper.withValues(alpha: .35)),
      );
      canvas.save();
      canvas.translate(nail.dx, nail.dy);
      canvas.rotate(.16);
      canvas.translate(-nail.dx, -nail.dy + h * .05);
    }

    final wire = PaintKit.stroke(AppColors.ash.withValues(alpha: .6), 1);
    canvas.drawLine(nail, Offset(w * .2, h * .06), wire);
    canvas.drawLine(nail, Offset(w * .8, h * .06), wire);

    canvas.drawRect(
      frame.shift(const Offset(3, 5)),
      Paint()
        ..color = AppColors.black.withValues(alpha: .6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRect(
      frame,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFF6A5436),
            Color(0xFF2A1E12),
            Color(0xFF5A4630),
          ],
        ).createShader(frame),
    );
    final canvasRect = frame.deflate(w * .11);
    canvas.drawRect(
      canvasRect.inflate(2),
      PaintKit.stroke(AppColors.black.withValues(alpha: .6), 2),
    );
    canvas.drawRect(
      canvasRect,
      PaintKit.radial(canvasRect.center, canvasRect.height * .7, [
        const Color(0xFF332820),
        const Color(0xFF120D0A),
      ]),
    );

    // The sitter.
    final cw = canvasRect.width, ch = canvasRect.height;
    final o = canvasRect.topLeft;
    final shoulders = Path()
      ..moveTo(o.dx + cw * .08, o.dy + ch)
      ..quadraticBezierTo(
        o.dx + cw * .12,
        o.dy + ch * .66,
        o.dx + cw * .4,
        o.dy + ch * .62,
      )
      ..lineTo(o.dx + cw * .6, o.dy + ch * .62)
      ..quadraticBezierTo(
        o.dx + cw * .88,
        o.dy + ch * .66,
        o.dx + cw * .92,
        o.dy + ch,
      )
      ..close();
    canvas.drawPath(shoulders, PaintKit.fill(const Color(0xFF1C1612)));
    final head = Rect.fromCenter(
      center: Offset(o.dx + cw * .5, o.dy + ch * .4),
      width: cw * .36,
      height: ch * .4,
    );
    canvas.drawOval(head, PaintKit.fill(const Color(0xFF4A3B2E)));

    // Scratched-out face.
    final rnd = math.Random(5);
    final scratch = PaintKit.stroke(
      AppColors.paper.withValues(alpha: .55),
      1.1,
    );
    for (var i = 0; i < 9; i++) {
      final a = Offset(
        head.left + head.width * rnd.nextDouble() * .4,
        head.top + head.height * (.15 + rnd.nextDouble() * .7),
      );
      final b = Offset(
        head.right - head.width * rnd.nextDouble() * .4,
        head.top + head.height * (.15 + rnd.nextDouble() * .7),
      );
      canvas.drawLine(a, b, scratch);
    }
    // Varnish.
    canvas.drawRect(
      canvasRect,
      PaintKit.radial(canvasRect.center, canvasRect.height * .75, [
        _clear,
        AppColors.black.withValues(alpha: .5),
      ]),
    );

    if (moved) canvas.restore();
  }

  @override
  bool shouldRepaint(PaintingPainter oldDelegate) => oldDelegate.moved != moved;
}

/// A window onto nothing.
class WindowPainter extends CustomPainter {
  const WindowPainter({required this.fogged, this.writing, this.phase = 0});

  final bool fogged;

  /// Letters traced in the fog, or null.
  final String? writing;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final frame = Rect.fromLTWH(0, 0, w, h * .92);
    final glass = frame.deflate(w * .08);

    canvas.drawRect(
      frame.shift(const Offset(2, 4)),
      Paint()
        ..color = AppColors.black.withValues(alpha: .6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRect(frame, PaintKit.wood(frame));
    canvas.drawRect(
      glass,
      PaintKit.vertical(glass, [
        const Color(0xFF12181C),
        const Color(0xFF040506),
      ]),
    );

    // Faint reflection of the room's light.
    canvas.save();
    canvas.clipRect(glass);
    canvas.drawLine(
      Offset(glass.left, glass.top + glass.height * .7),
      Offset(glass.right, glass.top + glass.height * .1),
      PaintKit.stroke(AppColors.bone.withValues(alpha: .04), glass.width * .2),
    );

    if (fogged) {
      final breath = .75 + .25 * math.sin(phase * math.pi * 2);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(glass.center.dx, glass.top + glass.height * .7),
          width: glass.width * 1.1,
          height: glass.height * .8,
        ),
        PaintKit.radial(
          Offset(glass.center.dx, glass.top + glass.height * .7),
          glass.width * .6,
          [AppColors.coldLight.withValues(alpha: .22 * breath), _clear],
        ),
      );
    }
    final writing = this.writing;
    if (writing != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: writing,
          style: AppText.whisper.copyWith(
            fontSize: glass.width * .16,
            height: 1.1,
            color: AppColors.bone.withValues(alpha: .45),
            letterSpacing: 2,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: glass.width);
      tp.paint(
        canvas,
        Offset(glass.center.dx - tp.width / 2, glass.top + glass.height * .55),
      );
      tp.dispose();
    }
    canvas.restore();

    // Mullions.
    final bar = PaintKit.fill(AppColors.woodDark);
    canvas.drawRect(
      Rect.fromCenter(
        center: glass.center,
        width: w * .045,
        height: glass.height,
      ),
      bar,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: glass.center,
        width: glass.width,
        height: w * .045,
      ),
      bar,
    );
    // Sill.
    final sill = Rect.fromLTWH(-w * .05, h * .9, w * 1.1, h * .1);
    canvas.drawRect(
      sill,
      PaintKit.vertical(sill, [AppColors.woodLight, AppColors.woodDark]),
    );
  }

  @override
  bool shouldRepaint(WindowPainter oldDelegate) =>
      oldDelegate.fogged != fogged ||
      oldDelegate.writing != writing ||
      oldDelegate.phase != phase;
}
