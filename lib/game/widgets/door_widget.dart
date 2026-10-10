import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/game_timings.dart';
import 'painters/paint_kit.dart';

/// What is behind the door when it opens.
enum DoorBeyond { light, dark }

/// The door: frame, swinging panel, light leaking underneath.
///
/// - [isOpen] swings the panel open (perspective rotation on its hinge).
/// - Every change of [knockSeq] jolts the panel once — one knock.
/// - [presence] puts two shadows in the light under the door.
class DoorWidget extends StatefulWidget {
  const DoorWidget({
    super.key,
    required this.lightColor,
    this.hasKeypad = false,
    this.isOpen = false,
    this.knockSeq = 0,
    this.presence = false,
    this.beyond = DoorBeyond.light,
  });

  final Color lightColor;
  final bool hasKeypad;
  final bool isOpen;
  final int knockSeq;
  final bool presence;
  final DoorBeyond beyond;

  @override
  State<DoorWidget> createState() => _DoorWidgetState();
}

class _DoorWidgetState extends State<DoorWidget> with TickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: GameTimings.doorSwing,
    value: widget.isOpen ? 1 : 0,
  );
  late final AnimationController _knock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void didUpdateWidget(DoorWidget old) {
    super.didUpdateWidget(old);
    if (widget.isOpen != old.isOpen) {
      if (widget.isOpen) {
        _open.forward();
      } else {
        _open.value = 0;
      }
    }
    if (widget.knockSeq != old.knockSeq) _knock.forward(from: 0);
  }

  @override
  void dispose() {
    _open.dispose();
    _knock.dispose();
    _flicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final opening = _DoorGeometry.opening(size);
        final panel = Rect.fromLTRB(
          opening.left,
          opening.top,
          opening.right,
          opening.bottom - _DoorGeometry.gap(size),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DoorFramePainter(
                  lightColor: widget.lightColor,
                  presence: widget.presence,
                  beyond: widget.beyond,
                  flicker: _flicker,
                  open: _open,
                ),
              ),
            ),
            Positioned.fromRect(
              rect: panel,
              child: AnimatedBuilder(
                animation: Listenable.merge([_open, _knock]),
                builder: (context, child) {
                  final swing = Curves.easeInOutCubic.transform(_open.value);
                  final k = _knock.value;
                  final jolt = k == 0
                      ? 0.0
                      : math.sin(k * math.pi * 4) * (1 - k) * size.width * .025;
                  return Transform.translate(
                    offset: Offset(jolt, 0),
                    child: Transform(
                      alignment: Alignment.centerLeft,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, .0016)
                        ..rotateY(-swing * 1.3),
                      child: child,
                    ),
                  );
                },
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _DoorPanelPainter(
                      hasKeypad: widget.hasKeypad,
                      unlocked: widget.isOpen,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

abstract final class _DoorGeometry {
  static double frame(Size s) => s.width * .075;

  static double gap(Size s) => math.max(2, s.height * .012);

  static Rect opening(Size s) {
    final f = frame(s);
    return Rect.fromLTRB(f, f, s.width - f, s.height);
  }
}

class _DoorFramePainter extends CustomPainter {
  _DoorFramePainter({
    required this.lightColor,
    required this.presence,
    required this.beyond,
    required this.flicker,
    required this.open,
  }) : super(repaint: Listenable.merge([flicker, open]));

  final Color lightColor;
  final bool presence;
  final DoorBeyond beyond;
  final Animation<double> flicker;
  final Animation<double> open;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final opening = _DoorGeometry.opening(size);
    final f = flicker.value * math.pi * 2;
    final flick = .82 + .18 * math.sin(f * 5) * math.sin(f * 1.3);
    final o = open.value;

    // Shadow cast by the frame onto the wall.
    canvas.drawRect(
      (Offset.zero & size).inflate(4).shift(const Offset(4, 0)),
      Paint()
        ..color = AppColors.black.withValues(alpha: .55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // What lies beyond.
    if (beyond == DoorBeyond.dark) {
      canvas.drawRect(opening, PaintKit.fill(const Color(0xFF000000)));
      canvas.drawRect(
        opening,
        PaintKit.radial(opening.center, opening.height * .6, [
          AppColors.bloodDeep.withValues(alpha: .35 * o),
          const Color(0x00000000),
        ]),
      );
    } else {
      canvas.drawRect(
        opening,
        PaintKit.radial(
          opening.center - Offset(0, opening.height * .1),
          opening.height * .7,
          const [Color(0xFFE6DDCD), Color(0xFF9A9286), Color(0xFF2A2522)],
        ),
      );
    }

    // Casing.
    final casing = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(opening);
    canvas.drawPath(casing, PaintKit.wood(Offset.zero & size));
    PaintKit.grain(
      canvas,
      Rect.fromLTWH(0, 0, opening.left, h),
      lines: 2,
      seed: 4,
    );
    PaintKit.grain(
      canvas,
      Rect.fromLTWH(opening.right, 0, w - opening.right, h),
      lines: 2,
      seed: 9,
    );
    canvas.drawRect(
      opening,
      PaintKit.stroke(AppColors.black.withValues(alpha: .7), 2),
    );
    canvas.drawLine(
      const Offset(0, 0),
      Offset(w, 0),
      PaintKit.stroke(AppColors.bone.withValues(alpha: .07), 1.5),
    );

    // Light under the door, spilling on the floor.
    final gap = _DoorGeometry.gap(size);
    final strip = Rect.fromLTRB(opening.left, h - gap, opening.right, h);
    final light = beyond == DoorBeyond.dark && o > 0 ? 0.0 : flick;
    canvas.drawRect(
      strip,
      PaintKit.fill(lightColor.withValues(alpha: .9 * light)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h + gap * 2),
        width: opening.width * 1.5,
        height: h * .06,
      ),
      Paint()
        ..color = lightColor.withValues(alpha: .22 * light)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    if (presence && o == 0) {
      // Two feet standing on the other side.
      final feet = PaintKit.fill(const Color(0xFF020101));
      for (final x in [.36, .56]) {
        canvas.drawRect(
          Rect.fromLTWH(
            opening.left + opening.width * x,
            h - gap,
            opening.width * .1,
            gap,
          ),
          feet,
        );
        canvas.drawOval(
          Rect.fromLTWH(
            opening.left + opening.width * (x - .02),
            h,
            opening.width * .14,
            h * .025,
          ),
          Paint()
            ..color = AppColors.black.withValues(alpha: .6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }

    // When the door opens onto light, it pours onto the floor.
    if (o > 0 && beyond == DoorBeyond.light) {
      final pour = Path()
        ..moveTo(opening.left, h)
        ..lineTo(opening.right, h)
        ..lineTo(opening.right + w * .5, h + h * .45)
        ..lineTo(opening.left - w * .5, h + h * .45)
        ..close();
      canvas.drawPath(
        pour,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE6DDCD).withValues(alpha: .28 * o),
              const Color(0x00000000),
            ],
          ).createShader(Rect.fromLTWH(0, h, w, h * .45)),
      );
    }
  }

  @override
  bool shouldRepaint(_DoorFramePainter oldDelegate) =>
      oldDelegate.lightColor != lightColor ||
      oldDelegate.presence != presence ||
      oldDelegate.beyond != beyond;
}

class _DoorPanelPainter extends CustomPainter {
  const _DoorPanelPainter({required this.hasKeypad, required this.unlocked});

  final bool hasKeypad;
  final bool unlocked;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    canvas.drawRect(rect, PaintKit.wood(rect));
    PaintKit.grain(canvas, rect, lines: 12, alpha: .1, seed: 21);

    for (final col in const [(.12, .46), (.54, .88)]) {
      for (final row in const [(.06, .44), (.5, .92)]) {
        PaintKit.recessedPanel(
          canvas,
          Rect.fromLTRB(w * col.$1, h * row.$1, w * col.$2, h * row.$2),
          inset: w * .014,
        );
      }
    }

    // Thickness: the free edge is darker.
    canvas.drawRect(
      Rect.fromLTWH(w * .93, 0, w * .07, h),
      PaintKit.fill(AppColors.black.withValues(alpha: .35)),
    );

    // Old scratches near the floor.
    final scratch = PaintKit.stroke(AppColors.bone.withValues(alpha: .06), 1);
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(w * (.2 + i * .05), h * .97),
        Offset(w * (.26 + i * .06), h * .86),
        scratch,
      );
    }

    // Handle and keyhole.
    final knob = Offset(w * .84, h * .53);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: knob + Offset(0, h * .015),
          width: w * .08,
          height: h * .13,
        ),
        Radius.circular(w * .03),
      ),
      PaintKit.fill(const Color(0xFF3B3022)),
    );
    canvas.drawCircle(
      knob,
      w * .05,
      PaintKit.radial(knob - Offset(w * .015, w * .015), w * .06, const [
        Color(0xFFA6906A),
        AppColors.brass,
        Color(0xFF241B11),
      ]),
    );
    final hole = knob + Offset(0, h * .05);
    canvas.drawCircle(hole, w * .013, PaintKit.fill(AppColors.black));
    canvas.drawRect(
      Rect.fromCenter(
        center: hole + Offset(0, w * .02),
        width: w * .012,
        height: w * .035,
      ),
      PaintKit.fill(AppColors.black),
    );

    if (hasKeypad) _keypad(canvas, w, h);
  }

  void _keypad(Canvas canvas, double w, double h) {
    final plate = Rect.fromLTWH(w * .68, h * .33, w * .24, h * .11);
    canvas.drawRect(plate, PaintKit.fill(const Color(0xFF0E0C0B)));
    canvas.drawRect(
      plate,
      PaintKit.stroke(AppColors.brass.withValues(alpha: .4), 1),
    );
    final dot = PaintKit.fill(AppColors.ash.withValues(alpha: .45));
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 3; c++) {
        canvas.drawCircle(
          Offset(
            plate.left + plate.width * (.25 + c * .25),
            plate.top + plate.height * (.22 + r * .19),
          ),
          w * .009,
          dot,
        );
      }
    }
    final led = Offset(
      plate.right - plate.width * .1,
      plate.top + plate.height * .1,
    );
    final ledColor = unlocked
        ? const Color(0xFF9FB59A)
        : const Color(0xFFB01818);
    canvas.drawCircle(
      led,
      w * .04,
      PaintKit.radial(led, w * .04, [
        ledColor.withValues(alpha: .5),
        const Color(0x00000000),
      ]),
    );
    canvas.drawCircle(led, w * .011, PaintKit.fill(ledColor));
  }

  @override
  bool shouldRepaint(_DoorPanelPainter oldDelegate) =>
      oldDelegate.hasKeypad != hasKeypad || oldDelegate.unlocked != unlocked;
}
