import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_colors.dart';
import 'paint_kit.dart';

const _clear = Color(0x00000000);
const _iron = Color(0xFF26231F);
const _ironLight = Color(0xFF4A453E);

/// A tall iron candlestick with a wax candle. [phase] animates the flame.
class CandlePainter extends CustomPainter {
  const CandlePainter({required this.lit, this.phase = 0});

  final bool lit;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    PaintKit.floorShadow(
      canvas,
      Rect.fromLTWH(w * .1, 0, w * .8, h),
      alpha: .6,
    );

    // Tripod feet and pole.
    final leg = PaintKit.stroke(_iron, w * .05);
    for (final dx in [-.38, 0.0, .38]) {
      canvas.drawLine(Offset(cx, h * .9), Offset(cx + w * dx, h), leg);
    }
    final pole = Rect.fromLTWH(cx - w * .045, h * .26, w * .09, h * .66);
    canvas.drawRect(
      pole,
      PaintKit.wood(pole, dark: _iron, base: _iron, light: _ironLight),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * .6),
        width: w * .2,
        height: h * .02,
      ),
      PaintKit.fill(_ironLight),
    );
    // Drip tray.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * .265),
        width: w * .78,
        height: h * .035,
      ),
      PaintKit.fill(_iron),
    );

    // Wax candle with drips.
    final wax = Rect.fromLTWH(cx - w * .14, h * .1, w * .28, h * .16);
    canvas.drawRect(
      wax,
      PaintKit.wood(
        wax,
        dark: const Color(0xFF8E8168),
        base: const Color(0xFFBEB194),
        light: const Color(0xFFDCD0B4),
      ),
    );
    final drip = PaintKit.fill(const Color(0xFFCDBF9F));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * .12, h * .1, w * .05, h * .07),
        Radius.circular(w * .03),
      ),
      drip,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + w * .05, h * .1, w * .045, h * .11),
        Radius.circular(w * .03),
      ),
      drip,
    );
    canvas.drawLine(
      Offset(cx, h * .1),
      Offset(cx, h * .085),
      PaintKit.stroke(AppColors.black, 1.5),
    );

    if (!lit) return;

    // Flame: a flickering teardrop with a warm halo.
    final f = phase * math.pi * 2;
    final sway = math.sin(f * 3) * w * .02 + math.sin(f * 7) * w * .01;
    final tall = h * (.075 + .012 * math.sin(f * 5));
    final base = Offset(cx, h * .088);
    canvas.drawCircle(
      base,
      w * 2.2,
      PaintKit.radial(base, w * 2.2, [
        AppColors.ember.withValues(alpha: .26 + .05 * math.sin(f * 4)),
        AppColors.ember.withValues(alpha: .06),
        _clear,
      ]),
    );
    final flame = Path()
      ..moveTo(base.dx - w * .07, base.dy)
      ..quadraticBezierTo(
        base.dx - w * .09,
        base.dy - tall * .55,
        base.dx + sway,
        base.dy - tall,
      )
      ..quadraticBezierTo(
        base.dx + w * .09,
        base.dy - tall * .55,
        base.dx + w * .07,
        base.dy,
      )
      ..quadraticBezierTo(
        base.dx,
        base.dy + w * .05,
        base.dx - w * .07,
        base.dy,
      )
      ..close();
    canvas.drawPath(
      flame,
      Paint()
        ..shader =
            RadialGradient(
              center: const Alignment(0, .5),
              radius: .9,
              colors: const [
                Color(0xFFFFF4D6),
                Color(0xFFFFC46B),
                Color(0xFFD9682A),
                Color(0x00D9682A),
              ],
              stops: const [0, .35, .75, 1],
            ).createShader(
              Rect.fromLTRB(
                base.dx - w * .1,
                base.dy - tall,
                base.dx + w * .1,
                base.dy,
              ),
            ),
    );
  }

  @override
  bool shouldRepaint(CandlePainter oldDelegate) =>
      oldDelegate.lit != lit || oldDelegate.phase != phase;
}

/// An old family photograph: three people, one of them blurred out.
class PhotoPainter extends CustomPainter {
  const PhotoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final frame = Offset.zero & size;
    canvas.drawRect(
      frame.shift(const Offset(2, 4)),
      Paint()
        ..color = AppColors.black.withValues(alpha: .6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRect(frame, PaintKit.wood(frame, base: const Color(0xFF241810)));
    final photo = frame.deflate(w * .12);
    canvas.drawRect(
      photo,
      PaintKit.vertical(photo, const [Color(0xFF7A6646), Color(0xFF4A3A26)]),
    );

    // Three sitters. The middle one is smudged, as if it moved.
    for (final (i, x) in const [.24, .5, .76].indexed) {
      final cx = photo.left + photo.width * x;
      final headR = photo.width * .075;
      final headY = photo.top + photo.height * .4;
      final p = Paint()
        ..color = Color(i == 1 ? 0xCC2A2016 : 0xFF2A2016)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i == 1 ? 2.5 : .6);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, headY),
          width: headR * 1.8,
          height: headR * 2.3,
        ),
        p,
      );
      canvas.drawPath(
        Path()
          ..moveTo(cx - headR * .5, headY + headR * 1.1)
          ..quadraticBezierTo(
            cx - headR * 2,
            headY + headR * 1.5,
            cx - headR * 2.1,
            photo.bottom,
          )
          ..lineTo(cx + headR * 2.1, photo.bottom)
          ..quadraticBezierTo(
            cx + headR * 2,
            headY + headR * 1.5,
            cx + headR * .5,
            headY + headR * 1.1,
          )
          ..close(),
        p,
      );
    }
    // Age: vignette and a crease.
    canvas.drawRect(
      photo,
      PaintKit.radial(photo.center, photo.height * .7, [
        _clear,
        AppColors.black.withValues(alpha: .55),
      ]),
    );
    canvas.drawLine(
      Offset(photo.left, photo.top + photo.height * .3),
      Offset(photo.right, photo.top + photo.height * .38),
      PaintKit.stroke(AppColors.bone.withValues(alpha: .15), 1),
    );
    // Glass glint.
    canvas.drawLine(
      Offset(frame.left + w * .2, frame.bottom - h * .1),
      Offset(frame.right - w * .1, frame.top + h * .2),
      PaintKit.stroke(AppColors.bone.withValues(alpha: .05), w * .12),
    );
  }

  @override
  bool shouldRepaint(PhotoPainter oldDelegate) => false;
}

/// A tall two-door wardrobe. [occupied] leaves a dark gap between the doors.
class WardrobePainter extends CustomPainter {
  const WardrobePainter({this.occupied = false});

  final bool occupied;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    PaintKit.floorShadow(canvas, Offset.zero & size);

    for (final x in [w * .06, w * .86]) {
      canvas.drawRect(
        Rect.fromLTWH(x, h * .95, w * .08, h * .05),
        PaintKit.fill(AppColors.woodDark),
      );
    }
    final body = Rect.fromLTWH(w * .03, h * .05, w * .94, h * .9);
    canvas.drawRect(body, PaintKit.wood(body));
    PaintKit.grain(canvas, body, lines: 9, seed: 31);

    // Cornice.
    final cornice = Rect.fromLTWH(0, 0, w, h * .06);
    canvas.drawRect(
      cornice,
      PaintKit.vertical(cornice, [AppColors.woodLight, AppColors.woodDark]),
    );

    // Two doors with long panels.
    final mid = w / 2;
    for (final left in [w * .08, mid + w * .02]) {
      PaintKit.recessedPanel(
        canvas,
        Rect.fromLTWH(left, h * .1, w * .38, h * .78),
        inset: w * .012,
      );
    }
    canvas.drawLine(
      Offset(mid, h * .06),
      Offset(mid, h * .95),
      PaintKit.stroke(
        AppColors.black.withValues(alpha: occupied ? .95 : .7),
        occupied ? w * .025 : 1.5,
      ),
    );
    // Knobs.
    for (final dx in [-w * .05, w * .05]) {
      final k = Offset(mid + dx, h * .5);
      canvas.drawCircle(
        k,
        w * .025,
        PaintKit.radial(k - Offset(w * .008, w * .008), w * .03, const [
          Color(0xFFA6906A),
          AppColors.brass,
          Color(0xFF241B11),
        ]),
      );
    }
  }

  @override
  bool shouldRepaint(WardrobePainter oldDelegate) =>
      oldDelegate.occupied != occupied;
}

/// A bare bulb hanging on a cord from the ceiling.
class BulbPainter extends CustomPainter {
  const BulbPainter({
    required this.cordLength,
    required this.on,
    this.flickering = false,
    this.phase = 0,
  });

  /// How far up the cord goes (to the top of the room).
  final double cordLength;
  final bool on;
  final bool flickering;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;

    var light = on ? 1.0 : 0.0;
    if (flickering) {
      final f = phase * math.pi * 2;
      light = (math.sin(f * 9) * math.sin(f * 23 + 1)).abs() > .35 ? 1 : .05;
    }

    canvas.drawLine(
      Offset(cx, -cordLength),
      Offset(cx, h * .2),
      PaintKit.stroke(const Color(0xFF151312), 1.5),
    );
    final bulbCenter = Offset(cx, h * .62);
    if (light > .1) {
      canvas.drawCircle(
        bulbCenter,
        w * 4,
        PaintKit.radial(bulbCenter, w * 4, [
          const Color(0xFFE8D8B0).withValues(alpha: .22 * light),
          const Color(0xFFE8D8B0).withValues(alpha: .05 * light),
          _clear,
        ]),
      );
    }
    // Socket.
    canvas.drawRect(
      Rect.fromLTWH(cx - w * .16, h * .18, w * .32, h * .2),
      PaintKit.fill(const Color(0xFF1C1A18)),
    );
    // Glass.
    canvas.drawOval(
      Rect.fromCenter(center: bulbCenter, width: w * .62, height: h * .5),
      PaintKit.radial(bulbCenter - Offset(w * .08, h * .06), w * .4, [
        Color.lerp(const Color(0xFF3A3834), const Color(0xFFFFF2D0), light)!,
        Color.lerp(const Color(0xFF1E1C1A), const Color(0xFFE0B870), light)!,
      ]),
    );
    canvas.drawLine(
      bulbCenter - Offset(w * .08, 0),
      bulbCenter + Offset(w * .08, 0),
      PaintKit.stroke(Color.lerp(AppColors.smoke, Colors.white, light)!, 1),
    );
  }

  @override
  bool shouldRepaint(BulbPainter oldDelegate) =>
      oldDelegate.on != on ||
      oldDelegate.flickering != flickering ||
      oldDelegate.phase != phase ||
      oldDelegate.cordLength != cordLength;
}

/// An old iron key lying on the floor, catching a little light.
class FloorKeyPainter extends CustomPainter {
  const FloorKeyPainter({this.phase = 0});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final iron = PaintKit.stroke(const Color(0xFF5A5246), h * .14);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .5, h * .78),
        width: w * .9,
        height: h * .25,
      ),
      Paint()
        ..color = AppColors.black.withValues(alpha: .6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(Offset(w * .2, h * .55), h * .2, iron);
    canvas.drawLine(Offset(w * .32, h * .55), Offset(w * .9, h * .55), iron);
    canvas.drawLine(Offset(w * .78, h * .55), Offset(w * .78, h * .8), iron);
    canvas.drawLine(Offset(w * .88, h * .55), Offset(w * .88, h * .75), iron);
    final glint = .4 + .6 * math.sin(phase * math.pi * 2).abs();
    canvas.drawCircle(
      Offset(w * .55, h * .5),
      w * .08,
      PaintKit.radial(Offset(w * .55, h * .5), w * .08, [
        AppColors.bone.withValues(alpha: .7 * glint),
        _clear,
      ]),
    );
  }

  @override
  bool shouldRepaint(FloorKeyPainter oldDelegate) => oldDelegate.phase != phase;
}

/// A wooden valve radio. [station] moves the needle, 0 = off.
class RadioPainter extends CustomPainter {
  const RadioPainter({required this.station, this.phase = 0});

  final int station;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final on = station > 0;
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, w, h),
      topLeft: Radius.circular(w * .3),
      topRight: Radius.circular(w * .3),
      bottomLeft: Radius.circular(w * .03),
      bottomRight: Radius.circular(w * .03),
    );
    if (on) {
      canvas.drawCircle(
        Offset(w * .5, h * .4),
        w * 1.2,
        PaintKit.radial(Offset(w * .5, h * .4), w * 1.2, [
          AppColors.ember.withValues(alpha: .12),
          _clear,
        ]),
      );
    }
    canvas.drawRRect(
      body,
      PaintKit.wood(
        body.outerRect,
        base: const Color(0xFF3B281A),
        light: const Color(0xFF5C3F28),
      ),
    );

    // Speaker cloth with grille.
    final cloth = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .1, h * .14, w * .8, h * .42),
      Radius.circular(w * .2),
    );
    canvas.drawRRect(cloth, PaintKit.fill(const Color(0xFF2A221A)));
    canvas.save();
    canvas.clipRRect(cloth);
    final bar = PaintKit.stroke(const Color(0xFF4A3826), w * .025);
    for (var x = .2; x < .85; x += .12) {
      canvas.drawLine(Offset(w * x, h * .1), Offset(w * x, h * .6), bar);
    }
    canvas.restore();

    // Dial window.
    final dial = Rect.fromLTWH(w * .14, h * .64, w * .72, h * .15);
    canvas.drawRect(
      dial,
      PaintKit.fill(on ? const Color(0xFFB98A48) : const Color(0xFF3A3024)),
    );
    final mark = PaintKit.stroke(AppColors.ink.withValues(alpha: .7), 1);
    for (var i = 0; i <= 10; i++) {
      final x = dial.left + dial.width * i / 10;
      canvas.drawLine(
        Offset(x, dial.top + 2),
        Offset(x, dial.top + dial.height * (i.isEven ? .5 : .3)),
        mark,
      );
    }
    final needleX =
        dial.left + dial.width * const [.08, .3, .58, .86][station.clamp(0, 3)];
    canvas.drawLine(
      Offset(needleX, dial.top),
      Offset(needleX, dial.bottom),
      PaintKit.stroke(const Color(0xFF8E1A1A), 2),
    );
    if (on) {
      final hum = .6 + .4 * math.sin(phase * math.pi * 2);
      canvas.drawRect(
        dial,
        PaintKit.fill(const Color(0xFFFFD08A).withValues(alpha: .12 * hum)),
      );
    }

    // Knobs.
    for (final x in [.24, .76]) {
      final k = Offset(w * x, h * .9);
      canvas.drawCircle(
        k,
        w * .06,
        PaintKit.radial(k - Offset(w * .02, w * .02), w * .07, const [
          Color(0xFF6A5236),
          Color(0xFF1E140C),
        ]),
      );
    }
  }

  @override
  bool shouldRepaint(RadioPainter oldDelegate) =>
      oldDelegate.station != station || oldDelegate.phase != phase;
}

/// A wall calendar with one day circled in red.
class CalendarPainter extends CustomPainter {
  const CalendarPainter({required this.month, this.year = ''});

  final String month;
  final String year;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawCircle(Offset(w / 2, -h * .03), 2, PaintKit.fill(AppColors.ash));
    final sheet = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      sheet.shift(const Offset(2, 3)),
      Paint()
        ..color = AppColors.black.withValues(alpha: .55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRect(
      sheet,
      PaintKit.radial(sheet.center, w, const [
        Color(0xFF8E846F),
        Color(0xFF5E5545),
      ]),
    );
    // Torn stubs of earlier months.
    for (var i = 0; i < 6; i++) {
      canvas.drawRect(
        Rect.fromLTWH(w * (.05 + i * .16), 0, w * .1, h * .04),
        PaintKit.fill(const Color(0xFF6E6553)),
      );
    }
    final header = Rect.fromLTWH(0, h * .05, w, h * .2);
    canvas.drawRect(header, PaintKit.fill(const Color(0xFF4A1612)));
    void label(String text, double fontSize, double y) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: AppText.label.copyWith(
            fontSize: fontSize,
            letterSpacing: fontSize * .18,
            color: const Color(0xFFD8CBB0),
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: w);
      tp.paint(
        canvas,
        Offset(header.center.dx - tp.width / 2, y - tp.height / 2),
      );
      tp.dispose();
    }

    if (year.isEmpty) {
      label(month, h * .11, header.center.dy);
    } else {
      label(month, h * .085, header.top + header.height * .36);
      label(year, h * .055, header.top + header.height * .78);
    }

    // Day grid: 5 rows × 7 columns.
    final grid = Rect.fromLTWH(w * .06, h * .3, w * .88, h * .64);
    final line = PaintKit.stroke(AppColors.ink.withValues(alpha: .35), .8);
    for (var r = 0; r <= 5; r++) {
      final y = grid.top + grid.height * r / 5;
      canvas.drawLine(Offset(grid.left, y), Offset(grid.right, y), line);
    }
    for (var c = 0; c <= 7; c++) {
      final x = grid.left + grid.width * c / 7;
      canvas.drawLine(Offset(x, grid.top), Offset(x, grid.bottom), line);
    }
    // The 9th: second row, second column (the month starts on a Monday).
    final cell = Rect.fromLTWH(
      grid.left + grid.width * 1 / 7,
      grid.top + grid.height * 1 / 5,
      grid.width / 7,
      grid.height / 5,
    );
    canvas.drawOval(
      cell.inflate(w * .025),
      PaintKit.stroke(const Color(0xFFA01818), w * .025),
    );
  }

  @override
  bool shouldRepaint(CalendarPainter oldDelegate) =>
      oldDelegate.month != month || oldDelegate.year != year;
}
