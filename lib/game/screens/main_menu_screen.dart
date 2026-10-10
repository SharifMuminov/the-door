import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/settings_cubit.dart';
import '../../app/theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/ui_text.dart';
import '../../core/utils/audio_manager.dart';
import '../../core/utils/fade_route.dart';
import '../../core/utils/game_storage.dart';
import '../logic/game_controller.dart';
import '../widgets/ghost_button.dart';
import '../widgets/settings_dialog.dart';
import 'game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  /// Slow fade in/out of the title.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  )..repeat(reverse: true);

  /// Rare, short stutter of the title — and someone behind the door.
  late final AnimationController _stutter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final Timer _stutterTimer;

  late final GameStorage _storage = context.read<GameStorage>();
  bool _hasSave = false;
  int _endings = 0;
  bool _busy = false;

  static final _dip = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(1), weight: 2),
    TweenSequenceItem(tween: ConstantTween(.15), weight: 1),
    TweenSequenceItem(tween: ConstantTween(1), weight: 2),
    TweenSequenceItem(tween: ConstantTween(.3), weight: 1),
    TweenSequenceItem(tween: ConstantTween(1), weight: 30),
  ]);

  @override
  void initState() {
    super.initState();
    _refresh();
    unawaited(context.read<AudioManager>().startAmbience(volume: .45));
    _stutterTimer = Timer.periodic(const Duration(seconds: 9), (_) {
      if (mounted && !_stutter.isAnimating) _stutter.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _stutterTimer.cancel();
    _pulse.dispose();
    _stutter.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _hasSave = _storage.hasSave;
      _endings = _storage.endingsSeen.length;
    });
  }

  Future<void> _start({required bool fresh}) async {
    if (_busy) return;
    final level = fresh ? 1 : GameController.resolveLevel(_storage.savedLevel);
    _busy = true;
    await Navigator.of(context).push(
      FadeRoute<void>(
        builder: (_) => GameScreen(startLevel: level, fresh: fresh),
        duration: const Duration(milliseconds: 900),
      ),
    );
    _busy = false;
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _LightUnderTheDoor(pulse: _pulse, presence: _stutter),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                _title(),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    context.tr(UiText.tagline),
                    textAlign: TextAlign.center,
                    style: AppText.tagline,
                  ),
                ),
                const Spacer(flex: 2),
                GhostButton(
                  label: context.tr(UiText.play),
                  style: AppText.menuButton,
                  onTap: () => _start(fresh: true),
                ),
                GhostButton(
                  label: context.tr(UiText.resume),
                  style: AppText.menuButton,
                  enabled: _hasSave,
                  onTap: () => _start(fresh: false),
                ),
                GhostButton(
                  label: context.tr(UiText.settings),
                  style: AppText.menuButton,
                  onTap: () => showSettingsDialog(context),
                ),
                const Spacer(flex: 3),
                AnimatedOpacity(
                  opacity: _endings > 0 ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    '${context.tr(UiText.endings)}  $_endings / 2',
                    style: AppText.label.copyWith(
                      fontSize: 10,
                      color: AppColors.smoke,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _title() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _stutter]),
      builder: (context, child) {
        final glow = Curves.easeInOut.transform(_pulse.value);
        final dip = _stutter.isAnimating ? _dip.transform(_stutter.value) : 1.0;
        return Opacity(
          opacity: ((.3 + .7 * glow) * dip).clamp(0, 1),
          child: child,
        );
      },
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'THE DOOR',
            style: AppText.title,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// The only light in the menu: a thin line under an unseen door.
/// Now and then, two shadows stand in it.
class _LightUnderTheDoor extends CustomPainter {
  _LightUnderTheDoor({required this.pulse, required this.presence})
    : super(repaint: Listenable.merge([pulse, presence]));

  final Animation<double> pulse;
  final Animation<double> presence;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final glow = .6 + .4 * Curves.easeInOut.transform(pulse.value);
    final y = h * .86;
    final lineW = math.min(w * .42, 200.0);
    final line = Rect.fromCenter(
      center: Offset(w / 2, y),
      width: lineW,
      height: 2,
    );

    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.black);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, y + 14),
        width: lineW * 2.2,
        height: 60,
      ),
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                AppColors.ember.withValues(alpha: .16 * glow),
                AppColors.ember.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCenter(
                center: Offset(w / 2, y + 14),
                width: lineW * 2.2,
                height: 60,
              ),
            ),
    );
    canvas.drawRect(
      line,
      Paint()
        ..color = AppColors.ember.withValues(alpha: .75 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );

    // Two feet, briefly.
    final p = presence.value;
    if (presence.isAnimating && p > .15 && p < .85) {
      final feet = Paint()..color = AppColors.black;
      for (final x in [.36, .56]) {
        canvas.drawRect(
          Rect.fromLTWH(line.left + line.width * x, y - 2, line.width * .1, 5),
          feet,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LightUnderTheDoor oldDelegate) => false;
}
