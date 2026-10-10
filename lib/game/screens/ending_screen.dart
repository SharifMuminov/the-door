import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/settings_cubit.dart';
import '../../app/theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/l_text.dart';
import '../../core/l10n/ui_text.dart';
import '../../core/utils/audio_manager.dart';
import '../../core/utils/fade_route.dart';
import '../../core/utils/game_storage.dart';
import '../logic/game_state.dart';
import '../widgets/ghost_button.dart';
import 'main_menu_screen.dart';

/// Black screen. A few lines, typed slowly, one after another. THE END.
class EndingScreen extends StatefulWidget {
  const EndingScreen({super.key, required this.ending});

  final GameEnding ending;

  @override
  State<EndingScreen> createState() => _EndingScreenState();
}

class _EndingScreenState extends State<EndingScreen> {
  final _timers = <Timer>[];

  /// 1..n: lines shown so far; n + 1: THE END; n + 2: the way back.
  int _step = 0;

  List<LText> get _lines => switch (widget.ending) {
    GameEnding.bad => const [
      LText('You opened it.', 'Siz uni ochdingiz.'),
      LText(
        'You wake in a dark room. There is a note on the wall.',
        'Qorong‘i xonada uyg‘onasiz. Devorda eslatma bor.',
      ),
      LText(
        'On the table, someone has scratched a new mark. Forty-two.',
        'Stolda kimdir yangi iz tirnab qo‘yibdi. Qirq ikkinchisi.',
      ),
    ],
    GameEnding.good => const [
      LText(
        'The key turns. The knocking stops.',
        'Kalit buraladi. Taqillatish tinadi.',
      ),
      LText(
        'Somewhere in the house, a clock moves on. 3:18.',
        'Uyning qayeridadir soat yurib ketadi. 3:18.',
      ),
      LText(
        'You were never supposed to leave.',
        'Siz hech qachon ketmasligingiz kerak edi.',
      ),
    ],
    GameEnding.none => const [],
  };

  LText get _name => switch (widget.ending) {
    GameEnding.bad => const LText('THE OPEN DOOR', 'OCHIQ ESHIK'),
    GameEnding.good => const LText('THE LOCKED ROOM', 'QULFLANGAN XONA'),
    GameEnding.none => const LText('', ''),
  };

  /// Typing takes longer for longer lines, in whichever language is longer.
  static int _typing(LText line) =>
      _msPerLetter * math.max(line.en.length, line.uz.length);

  static const _msPerLetter = 55;

  @override
  void initState() {
    super.initState();
    var t = 1400;
    for (final (i, line) in _lines.indexed) {
      _at(t, i + 1);
      t += _typing(line) + 1300;
    }
    _at(t + 400, _lines.length + 1);
    _at(t + 2200, _lines.length + 2);
    if (widget.ending == GameEnding.bad) {
      _timers.add(
        Timer(const Duration(milliseconds: 1300), () {
          if (!mounted) return;
          unawaited(
            context.read<AudioManager>().play(Sfx.heartbeat, volume: .8),
          );
        }),
      );
    }
  }

  void _at(int ms, int step) {
    _timers.add(
      Timer(Duration(milliseconds: ms), () {
        if (mounted) setState(() => _step = step);
      }),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _return() {
    unawaited(
      Navigator.of(context).pushAndRemoveUntil(
        FadeRoute<void>(
          builder: (_) => const MainMenuScreen(),
          duration: const Duration(milliseconds: 1200),
        ),
        (_) => false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final endings = context.read<GameStorage>().endingsSeen.length;
    final lines = _lines;
    final theEnd = lines.length + 1;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > theEnd) _return();
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              for (final (i, line) in lines.indexed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 22),
                  child: _step > i
                      ? _Typewriter(text: context.tr(line), first: i == 0)
                      : const SizedBox.shrink(),
                ),
              const SizedBox(height: 20),
              AnimatedOpacity(
                opacity: _step >= theEnd ? 1 : 0,
                duration: const Duration(milliseconds: 1600),
                child: Text(
                  context.tr(UiText.theEnd),
                  style: AppText.label.copyWith(
                    color: AppColors.bloodLight,
                    fontSize: 16,
                    letterSpacing: 12,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              AnimatedOpacity(
                opacity: _step > theEnd ? 1 : 0,
                duration: const Duration(milliseconds: 1200),
                child: IgnorePointer(
                  ignoring: _step <= theEnd,
                  child: Column(
                    children: [
                      Text(
                        '${context.tr(_name)}  ·  ${context.tr(UiText.endings)} $endings / 2',
                        style: AppText.label.copyWith(
                          fontSize: 10,
                          color: AppColors.smoke,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GhostButton(
                        label: context.tr(UiText.back),
                        style: AppText.menuButton,
                        onTap: _return,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// Types [text] letter by letter without moving the centred line.
/// The [first] line is set larger than the ones that follow it.
class _Typewriter extends StatelessWidget {
  const _Typewriter({required this.text, this.first = false});

  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: text.length),
      duration: Duration(
        milliseconds: _EndingScreenState._msPerLetter * text.length,
      ),
      builder: (context, n, _) => Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text.substring(0, n)),
            TextSpan(
              text: text.substring(n),
              style: const TextStyle(color: Colors.transparent),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: AppText.title.copyWith(
          fontSize: first ? 25 : 19,
          letterSpacing: first ? 1.5 : .8,
          fontStyle: FontStyle.italic,
          height: 1.4,
          color: first ? AppColors.bone : AppColors.ash,
        ),
      ),
    );
  }
}
