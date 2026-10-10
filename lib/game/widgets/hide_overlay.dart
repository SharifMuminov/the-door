import 'package:flutter/material.dart';

import '../../app/settings_cubit.dart';
import '../../app/theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/ui_text.dart';
import 'ghost_button.dart';

/// The view from inside the wardrobe: darkness and two thin slits of room.
/// When [passing] is true, something walks past outside.
class HideOverlay extends StatefulWidget {
  const HideOverlay({
    super.key,
    required this.passing,
    required this.onStepOut,
  });

  final bool passing;
  final VoidCallback onStepOut;

  @override
  State<HideOverlay> createState() => _HideOverlayState();
}

class _HideOverlayState extends State<HideOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _walk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );

  @override
  void didUpdateWidget(HideOverlay old) {
    super.didUpdateWidget(old);
    if (widget.passing && !old.passing) _walk.forward(from: 0);
  }

  @override
  void dispose() {
    _walk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _walk,
            builder: (context, _) => CustomPaint(
              painter: _SlitsPainter(
                walk: _walk.isAnimating ? _walk.value : null,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, .92),
            child: AnimatedOpacity(
              opacity: widget.passing ? 0 : 1,
              duration: const Duration(milliseconds: 400),
              child: IgnorePointer(
                ignoring: widget.passing,
                child: GhostButton(
                  label: context.tr(UiText.stepOut),
                  style: AppText.menuButton.copyWith(
                    fontSize: 15,
                    letterSpacing: 6,
                  ),
                  onTap: widget.onStepOut,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlitsPainter extends CustomPainter {
  const _SlitsPainter({required this.walk});

  /// 0..1 while something walks past, else null.
  final double? walk;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final slits = [
      Rect.fromLTWH(w * .47, h * .08, w * .025, h * .8),
      Rect.fromLTWH(w * .505, h * .1, w * .02, h * .76),
    ];
    final dark = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    for (final s in slits) {
      dark.addRRect(RRect.fromRectAndRadius(s, const Radius.circular(3)));
    }
    canvas.drawPath(dark, Paint()..color = AppColors.black);

    final walk = this.walk;
    if (walk != null) {
      // During a blackout the slits show only a faint grey…
      for (final s in slits) {
        canvas.drawRect(s, Paint()..color = const Color(0xFF15161A));
      }
      // …until something tall crosses them.
      final x = w * (-.1 + 1.2 * walk);
      for (final s in slits) {
        canvas.save();
        canvas.clipRect(s);
        canvas.drawRect(
          Rect.fromLTWH(x - w * .06, h * .05, w * .12, h * .9),
          Paint()
            ..color = const Color(0xFF020202)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.restore();
      }
    }

    // Wood grain inside the wardrobe doors, barely lit.
    final grain = Paint()
      ..color = AppColors.woodDark.withValues(alpha: .35)
      ..strokeWidth = 1;
    for (var i = 1; i < 9; i++) {
      final x = w * i / 9;
      if (x > w * .44 && x < w * .55) continue;
      canvas.drawLine(Offset(x, 0), Offset(x + 4, h), grain);
    }
  }

  @override
  bool shouldRepaint(_SlitsPainter oldDelegate) => oldDelegate.walk != walk;
}
