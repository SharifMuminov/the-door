import 'package:flutter/material.dart';

import '../../app/settings_cubit.dart';
import '../../app/theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_timings.dart';
import '../models/level.dart';

/// Black card with the room's name and one line of the story, then the
/// room fades in. A tap hurries it along.
class LevelIntro extends StatefulWidget {
  const LevelIntro({super.key, required this.level, required this.onDone});

  final Level level;
  final VoidCallback onDone;

  @override
  State<LevelIntro> createState() => _LevelIntroState();
}

class _LevelIntroState extends State<LevelIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: GameTimings.intro,
  );

  static const _titleIn = Interval(.03, .14, curve: Curves.easeOut);
  static const _storyIn = Interval(.17, .3, curve: Curves.easeOut);
  static const _textOut = Interval(.72, .8, curve: Curves.easeIn);
  static const _veilOut = Interval(.76, 1, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) widget.onDone();
    });
    _c.forward();
  }

  void _skip() {
    if (_c.value >= _textOut.begin) return;
    _c.value = _textOut.begin;
    _c.animateTo(1, duration: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(
      context.tr(widget.level.title),
      textAlign: TextAlign.center,
      style: AppText.title.copyWith(fontSize: 26, letterSpacing: 6),
    );
    final story = Text(
      context.tr(widget.level.epigraph),
      textAlign: TextAlign.center,
      style: AppText.whisper.copyWith(color: AppColors.ash, fontSize: 16),
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = _c.value;
        final out = 1 - _textOut.transform(v);
        final veil = 1 - _veilOut.transform(v);
        return IgnorePointer(
          ignoring: v > .9,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _skip,
            child: ColoredBox(
              color: AppColors.black.withValues(alpha: veil),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: _titleIn.transform(v) * out,
                        child: Column(
                          children: [
                            Text(
                              context.tr(widget.level.code),
                              style: AppText.label.copyWith(letterSpacing: 8),
                            ),
                            const SizedBox(height: 16),
                            title,
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: _storyIn.transform(v) * out,
                        child: story,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
