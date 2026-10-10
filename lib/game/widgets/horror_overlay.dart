import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_timings.dart';
import 'room_layout.dart';

/// Wraps the room and plays short horror effects on top of it:
/// camera shake, flashes, light flicker, a shadow figure, glitches and
/// the word KNOCK appearing in the dark.
///
/// Effects are one-shot, so they are triggered imperatively through a
/// `GlobalKey<HorrorOverlayState>`. [darkness] is the persistent dimming.
class HorrorOverlay extends StatefulWidget {
  const HorrorOverlay({super.key, required this.child, this.darkness = 0});

  final Widget child;
  final double darkness;

  @override
  State<HorrorOverlay> createState() => HorrorOverlayState();
}

class HorrorOverlayState extends State<HorrorOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _shake = _controller(450);
  late final AnimationController _flash = _controller(300);
  late final AnimationController _flicker = _controller(1100);
  late final AnimationController _shadow = _controller(1300);
  late final AnimationController _glitch = _controller(260);
  late final AnimationController _eyes = _controller(1400);

  final _random = math.Random();
  final _words = <_Word>[];
  final _wordTimers = <Timer>[];
  int _wordId = 0;
  double _shakeStrength = 4;
  Color _flashColor = AppColors.bone;
  double _flashStrength = .6;

  static final _flickerCurve = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: .92), weight: 4),
    TweenSequenceItem(tween: Tween(begin: .92, end: .15), weight: 6),
    TweenSequenceItem(tween: Tween(begin: .15, end: .85), weight: 5),
    TweenSequenceItem(tween: ConstantTween(.85), weight: 8),
    TweenSequenceItem(tween: Tween(begin: .85, end: .1), weight: 6),
    TweenSequenceItem(tween: Tween(begin: .1, end: .95), weight: 4),
    TweenSequenceItem(tween: ConstantTween(.95), weight: 12),
    TweenSequenceItem(tween: Tween(begin: .95, end: 0), weight: 55),
  ]);

  static final _shadowCurve = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 8,
    ),
    TweenSequenceItem(tween: ConstantTween(1), weight: 70),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 22),
  ]);

  AnimationController _controller(int ms) => AnimationController(
    vsync: this,
    duration: Duration(milliseconds: ms),
  );

  // ------------------------------------------------------------ triggers

  void shake([double strength = 4]) {
    _shakeStrength = strength;
    _shake.forward(from: 0);
  }

  void flash(Color color, {double strength = .6}) {
    _flashColor = color;
    _flashStrength = strength;
    _flash.forward(from: 0);
  }

  void flicker() => _flicker.forward(from: 0);

  void shadow() => _shadow.forward(from: 0);

  void glitch() => _glitch.forward(from: 0);

  /// Two pale eyes, very close, in the dark.
  void eyes() => _eyes.forward(from: 0);

  /// Shows [text] near the door; [index] picks one of a few positions.
  void word(String text, int index) {
    final id = _wordId++;
    setState(() => _words.add(_Word(id, text, index % 3)));
    late final Timer timer;
    timer = Timer(const Duration(milliseconds: 1200), () {
      _wordTimers.remove(timer);
      if (mounted) setState(() => _words.removeWhere((w) => w.id == id));
    });
    _wordTimers.add(timer);
  }

  @override
  void dispose() {
    for (final t in _wordTimers) {
      t.cancel();
    }
    _shake.dispose();
    _flash.dispose();
    _flicker.dispose();
    _shadow.dispose();
    _glitch.dispose();
    _eyes.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = RoomLayout.of(constraints.biggest);
        return AnimatedBuilder(
          animation: Listenable.merge([_shake, _glitch]),
          builder: (context, child) {
            var offset = Offset.zero;
            if (_shake.isAnimating) {
              final s = _shake.value;
              final decay = 1 - s;
              offset += Offset(
                math.sin(s * 47) * _shakeStrength * decay,
                math.cos(s * 37) * _shakeStrength * .6 * decay,
              );
            }
            if (_glitch.isAnimating) {
              offset += Offset((_random.nextDouble() - .5) * 16, 0);
            }
            return Transform.translate(offset: offset, child: child);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              _darkness(),
              _layer(_shadow, (v) {
                final o = _shadowCurve.transform(v);
                return CustomPaint(painter: _ShadowFigurePainter(layout, o));
              }),
              _layer(
                _flicker,
                (v) => ColoredBox(
                  color: AppColors.black.withValues(
                    alpha: _flickerCurve.transform(v),
                  ),
                ),
              ),
              _layer(
                _glitch,
                (v) => CustomPaint(
                  painter: _GlitchPainter((v * 7).floor() + _wordId),
                ),
              ),
              _layer(_eyes, (v) {
                final o = _shadowCurve.transform(v);
                return CustomPaint(painter: _EyesPainter(o));
              }),
              _layer(_flash, (v) {
                final a = _flashStrength * math.pow(1 - v, 2);
                return ColoredBox(
                  color: _flashColor.withValues(alpha: a.toDouble()),
                );
              }),
              for (final w in _words) _wordWidget(w, layout),
            ],
          ),
        );
      },
    );
  }

  Widget _darkness() {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.darkness),
        duration: GameTimings.darkness,
        builder: (context, value, _) => value <= 0
            ? const SizedBox.shrink()
            : ColoredBox(color: AppColors.black.withValues(alpha: value)),
      ),
    );
  }

  /// A full-size layer that only exists while [controller] runs.
  Widget _layer(
    AnimationController controller,
    Widget Function(double v) build,
  ) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => controller.isAnimating
            ? build(controller.value)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _wordWidget(_Word w, RoomLayout layout) {
    const spots = [Offset(.4, .58), Offset(.6, .44), Offset(.46, .3)];
    final p = layout.point(spots[w.slot].dx, spots[w.slot].dy);
    return Positioned(
      left: p.dx,
      top: p.dy,
      child: IgnorePointer(
        child: FractionalTranslation(
          translation: const Offset(-.5, -.5),
          child: TweenAnimationBuilder<double>(
            key: ValueKey(w.id),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1100),
            builder: (context, t, child) => Opacity(
              opacity: math.sin(t * math.pi).clamp(0, 1),
              child: Transform.scale(scale: 1 + .12 * t, child: child),
            ),
            child: Text(
              w.text,
              style: AppText.label.copyWith(
                fontSize: 20,
                letterSpacing: 9,
                color: AppColors.bone.withValues(alpha: .8),
                shadows: const [Shadow(color: AppColors.black, blurRadius: 12)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Word {
  const _Word(this.id, this.text, this.slot);
  final int id;
  final String text;
  final int slot;
}

/// A tall, thin figure standing beside the door.
class _ShadowFigurePainter extends CustomPainter {
  const _ShadowFigurePainter(this.layout, this.opacity);

  final RoomLayout layout;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    // The whole room dims a little while it is here.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.black.withValues(alpha: .3 * opacity),
    );

    final u = layout.unit;
    final feet = layout.point(.72, -.02);
    final height = u * .82;
    final top = feet.dy - height;
    final cx = feet.dx;
    final paint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: .9 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, top + height * .07),
        width: u * .1,
        height: u * .14,
      ),
      paint,
    );
    final body = Path()
      ..moveTo(cx - u * .025, top + height * .13)
      ..lineTo(cx - u * .12, top + height * .2)
      // left arm, far too long
      ..lineTo(cx - u * .15, top + height * .7)
      ..lineTo(cx - u * .125, top + height * .72)
      ..lineTo(cx - u * .085, top + height * .32)
      ..lineTo(cx - u * .07, top + height * .6)
      ..lineTo(cx - u * .055, feet.dy)
      ..lineTo(cx - u * .015, feet.dy)
      ..lineTo(cx, top + height * .62)
      ..lineTo(cx + u * .015, feet.dy)
      ..lineTo(cx + u * .055, feet.dy)
      ..lineTo(cx + u * .07, top + height * .6)
      ..lineTo(cx + u * .085, top + height * .32)
      ..lineTo(cx + u * .125, top + height * .72)
      ..lineTo(cx + u * .15, top + height * .7)
      ..lineTo(cx + u * .12, top + height * .2)
      ..lineTo(cx + u * .025, top + height * .13)
      ..close();
    canvas.drawPath(body, paint);

    // Its shadow stretched across the floor.
    canvas.drawOval(
      Rect.fromCenter(
        center: feet.translate(-u * .1, u * .03),
        width: u * .5,
        height: u * .05,
      ),
      Paint()
        ..color = AppColors.black.withValues(alpha: .6 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(_ShadowFigurePainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.layout != layout;
}

/// Horizontal tears for a very short glitch.
class _GlitchPainter extends CustomPainter {
  const _GlitchPainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    for (var i = 0; i < 9; i++) {
      final y = rnd.nextDouble() * size.height;
      final h = 2 + rnd.nextDouble() * 14;
      final color = rnd.nextBool()
          ? AppColors.bloodLight.withValues(alpha: .35)
          : AppColors.bone.withValues(alpha: .1);
      canvas.drawRect(
        Rect.fromLTWH((rnd.nextDouble() - .5) * 40, y, size.width, h),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_GlitchPainter oldDelegate) => oldDelegate.seed != seed;
}

/// Pale eyes just in front of the viewer. Visible even in total darkness.
class _EyesPainter extends CustomPainter {
  const _EyesPainter(this.opacity);

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final c = Offset(size.width / 2, size.height * .42);
    final gap = size.width * .16;
    final r = size.width * .035;
    // A barely-there face around them.
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, r * 3),
        width: gap * 3.4,
        height: gap * 4.4,
      ),
      Paint()
        ..color = AppColors.bone.withValues(alpha: .05 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    for (final dx in [-gap / 2, gap / 2]) {
      final e = c.translate(dx, 0);
      canvas.drawCircle(
        e,
        r * 3,
        Paint()
          ..color = AppColors.bone.withValues(alpha: .18 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
      canvas.drawOval(
        Rect.fromCenter(center: e, width: r * 2.2, height: r * 1.3),
        Paint()
          ..color = const Color(0xFFE8E2D4).withValues(alpha: .9 * opacity),
      );
      canvas.drawCircle(
        e,
        r * .45,
        Paint()..color = AppColors.black.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_EyesPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
