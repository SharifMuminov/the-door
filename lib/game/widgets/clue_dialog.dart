import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/settings_cubit.dart';
import '../../app/theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_timings.dart';
import '../../core/l10n/ui_text.dart';
import '../../core/utils/audio_manager.dart';
import '../../core/utils/haptics.dart';
import '../models/clue.dart';
import 'ghost_button.dart';

/// Shows a clue full-screen over a dark veil. Completes when closed.
Future<void> showClueDialog(BuildContext context, Clue clue) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: AppColors.black.withValues(alpha: .8),
    transitionDuration: GameTimings.dialog,
    pageBuilder: (context, _, _) => ClueDialog(clue: clue),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: .96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class ClueDialog extends StatelessWidget {
  const ClueDialog({super.key, required this.clue});

  final Clue clue;

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width * .84, 360.0);
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: width,
                  child: switch (clue.style) {
                    ClueStyle.paper => _PaperNote(clue: clue),
                    ClueStyle.phone => _PhoneScreen(clue: clue),
                    ClueStyle.plain => _PlainText(clue: clue),
                  },
                ),
                const SizedBox(height: 28),
                GhostButton(
                  label: context.tr(UiText.close),
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades its child in after [delay].
class _Delayed extends StatelessWidget {
  const _Delayed({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const fade = 600;
    final total = delay.inMilliseconds + fade;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay.inMilliseconds / total, 1, curve: Curves.easeOut),
      builder: (context, v, child) => Opacity(opacity: v, child: child),
      child: child,
    );
  }
}

// ------------------------------------------------------------------ paper

class _PaperNote extends StatelessWidget {
  const _PaperNote({required this.clue});

  final Clue clue;

  @override
  Widget build(BuildContext context) {
    final faded = AppColors.ink.withValues(alpha: .55);
    return Transform.rotate(
      angle: -.025,
      child: CustomPaint(
        painter: _OldPaperPainter(seed: clue.id.index + 3),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 40, 30, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(clue.title),
                textAlign: TextAlign.center,
                style: AppText.label.copyWith(
                  color: faded,
                  fontSize: 12,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '────────────',
                style: TextStyle(color: faded, letterSpacing: -1),
              ),
              const SizedBox(height: 22),
              for (final (i, line) in clue.lines.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _Delayed(
                    delay: Duration(milliseconds: 250 + i * 650),
                    child: Text(
                      context.tr(line),
                      textAlign: TextAlign.center,
                      style: AppText.ink,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                '────────────',
                style: TextStyle(color: faded, letterSpacing: -1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Old paper: torn edges, burnt rim, stains, a fold and foxing.
class _OldPaperPainter extends CustomPainter {
  const _OldPaperPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rnd = math.Random(seed);
    double jitter(double amount) => (rnd.nextDouble() - .5) * amount;

    final path = Path()..moveTo(0, jitter(4));
    for (var x = 14.0; x < w; x += 14) {
      path.lineTo(x, jitter(5));
    }
    for (var y = 14.0; y < h; y += 14) {
      path.lineTo(w + jitter(5), y);
    }
    for (var x = w - 12; x > 0; x -= 12) {
      path.lineTo(x, h + jitter(12));
    }
    for (var y = h - 14; y > 0; y -= 14) {
      path.lineTo(jitter(5), y);
    }
    path.close();

    canvas.drawPath(
      path.shift(const Offset(4, 8)),
      Paint()
        ..color = AppColors.black.withValues(alpha: .7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.1, -.2),
          radius: .95,
          colors: const [
            Color(0xFFC9BDA2),
            Color(0xFFAE9F80),
            Color(0xFF6E5F48),
          ],
          stops: const [0, .65, 1],
        ).createShader(Offset.zero & size),
    );

    canvas.save();
    canvas.clipPath(path);
    // Burnt rim.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3A2614).withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Coffee ring and a damp blot.
    canvas.drawCircle(
      Offset(w * .78, h * .78),
      w * .13,
      Paint()
        ..color = const Color(0xFF5A3D1E).withValues(alpha: .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      Offset(w * .2, h * .2),
      w * .1,
      Paint()
        ..color = const Color(0xFF5A3D1E).withValues(alpha: .08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Fold.
    canvas.drawLine(
      Offset(0, h * .45),
      Offset(w, h * .5),
      Paint()
        ..color = const Color(0xFF4A3A28).withValues(alpha: .25)
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(0, h * .45 + 2),
      Offset(w, h * .5 + 2),
      Paint()
        ..color = const Color(0xFFE6DCC6).withValues(alpha: .18)
        ..strokeWidth = 1.2,
    );
    // Foxing.
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * w, rnd.nextDouble() * h),
        .6 + rnd.nextDouble() * 2.2,
        Paint()
          ..color = const Color(
            0xFF5A3D1E,
          ).withValues(alpha: .05 + rnd.nextDouble() * .12),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OldPaperPainter oldDelegate) => oldDelegate.seed != seed;
}

// ------------------------------------------------------------------ phone

class _PhoneScreen extends StatefulWidget {
  const _PhoneScreen({required this.clue});

  final Clue clue;

  @override
  State<_PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<_PhoneScreen> {
  final _timers = <Timer>[];
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.clue.lines.length; i++) {
      _timers.add(
        Timer(Duration(milliseconds: 700 + i * 1900), () {
          if (!mounted) return;
          setState(() => _shown = i + 1);
          // The first buzz already played when the phone was picked up.
          if (i > 0) {
            unawaited(context.read<AudioManager>().play(Sfx.buzz, volume: .7));
            unawaited(context.read<Haptics>().medium());
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final small = AppText.mono.copyWith(
      fontSize: 11,
      color: AppColors.ash,
      letterSpacing: 2,
    );
    return Container(
      height: 440,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0B0C),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.smoke, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.coldLight.withValues(alpha: .08),
            blurRadius: 50,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(context.tr(UiText.noService), style: small),
              const Spacer(),
              Text('3:17', style: small),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            context.tr(widget.clue.title),
            style: small.copyWith(color: AppColors.bone),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.clue.lines.length}${context.tr(UiText.messages)}',
            style: small.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 22),
          for (final (i, line) in widget.clue.lines.indexed)
            AnimatedOpacity(
              opacity: i < _shown ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedSlide(
                offset: i < _shown ? Offset.zero : const Offset(0, .3),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1F21),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    context.tr(line),
                    style: AppText.mono.copyWith(fontSize: 15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ plain

class _PlainText extends StatelessWidget {
  const _PlainText({required this.clue});

  final Clue clue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.tr(clue.title), style: AppText.label),
        const SizedBox(height: 30),
        for (final (i, line) in clue.lines.map(context.tr).indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _Delayed(
              delay: Duration(milliseconds: 300 + i * 1000),
              child: Text(
                line,
                textAlign: TextAlign.center,
                // Shouted lines (all capitals) read like something written.
                style: line == line.toUpperCase()
                    ? AppText.label.copyWith(
                        fontSize: 18,
                        letterSpacing: 4,
                        color: AppColors.bone,
                      )
                    : AppText.whisper.copyWith(fontSize: 17),
              ),
            ),
          ),
      ],
    );
  }
}
