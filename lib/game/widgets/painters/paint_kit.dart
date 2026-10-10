import 'dart:math' as math;
import 'dart:ui';

import '../../../core/constants/app_colors.dart';

/// Small drawing helpers shared by the object painters.
abstract final class PaintKit {
  static Paint fill(Color color) => Paint()..color = color;

  static Paint stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  /// Horizontal wood gradient with a soft highlight, as if lit from the left.
  static Paint wood(
    Rect rect, {
    Color dark = AppColors.woodDark,
    Color base = AppColors.wood,
    Color light = AppColors.woodLight,
  }) => Paint()
    ..shader = Gradient.linear(
      rect.centerLeft,
      rect.centerRight,
      [dark, light, base, dark],
      const [0, .32, .7, 1],
    );

  static Paint vertical(Rect rect, List<Color> colors, [List<double>? stops]) =>
      Paint()
        ..shader = Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          colors,
          stops ?? _even(colors),
        );

  static Paint radial(
    Offset center,
    double radius,
    List<Color> colors, [
    List<double>? stops,
  ]) => Paint()
    ..shader = Gradient.radial(center, radius, colors, stops ?? _even(colors));

  /// dart:ui needs explicit stops for more than two colours.
  static List<double>? _even(List<Color> colors) => colors.length <= 2
      ? null
      : [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)];

  /// Faint wavy grain lines inside [rect].
  static void grain(
    Canvas canvas,
    Rect rect, {
    int lines = 7,
    double alpha = .07,
    bool vertical = true,
    int seed = 3,
  }) {
    final rnd = math.Random(seed);
    final paint = stroke(AppColors.black.withValues(alpha: alpha), 1);
    for (var i = 0; i < lines; i++) {
      final path = Path();
      if (vertical) {
        final x = rect.left + rect.width * (i + rnd.nextDouble()) / lines;
        path.moveTo(x, rect.top);
        path.cubicTo(
          x + rect.width * (rnd.nextDouble() - .5) * .08,
          rect.top + rect.height * .33,
          x + rect.width * (rnd.nextDouble() - .5) * .08,
          rect.top + rect.height * .66,
          x,
          rect.bottom,
        );
      } else {
        final y = rect.top + rect.height * (i + rnd.nextDouble()) / lines;
        path.moveTo(rect.left, y);
        path.cubicTo(
          rect.left + rect.width * .33,
          y + rect.height * (rnd.nextDouble() - .5) * .1,
          rect.left + rect.width * .66,
          y + rect.height * (rnd.nextDouble() - .5) * .1,
          rect.right,
          y,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  /// Soft contact shadow under furniture.
  static void floorShadow(
    Canvas canvas,
    Rect objectRect, {
    double alpha = .75,
  }) {
    final r = Rect.fromCenter(
      center: Offset(objectRect.center.dx, objectRect.bottom),
      width: objectRect.width * 1.15,
      height: math.max(6, objectRect.height * .1),
    );
    canvas.drawOval(
      r,
      Paint()
        ..color = AppColors.black.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  /// Bevelled recessed panel: dark top-left edge, faint highlight bottom-right.
  static void recessedPanel(Canvas canvas, Rect r, {double inset = 2}) {
    canvas.drawRect(r, fill(AppColors.black.withValues(alpha: .28)));
    final shadow = stroke(AppColors.black.withValues(alpha: .55), inset);
    final light = stroke(AppColors.bone.withValues(alpha: .06), inset * .7);
    canvas.drawLine(r.topLeft, r.topRight, shadow);
    canvas.drawLine(r.topLeft, r.bottomLeft, shadow);
    canvas.drawLine(r.bottomLeft, r.bottomRight, light);
    canvas.drawLine(r.topRight, r.bottomRight, light);
  }
}
