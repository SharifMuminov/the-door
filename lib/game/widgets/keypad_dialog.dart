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
import '../models/puzzle.dart';
import 'ghost_button.dart';

/// Shows the door keypad. [onSubmit] returns true when the code is right;
/// the dialog then closes by itself. A wrong code shakes the keypad.
Future<void> showKeypadDialog(
  BuildContext context, {
  required Puzzle puzzle,
  required bool Function(String code) onSubmit,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: AppColors.black.withValues(alpha: .75),
    transitionDuration: GameTimings.dialog,
    pageBuilder: (context, _, _) =>
        KeypadDialog(puzzle: puzzle, onSubmit: onSubmit),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class KeypadDialog extends StatefulWidget {
  const KeypadDialog({super.key, required this.puzzle, required this.onSubmit});

  final Puzzle puzzle;
  final bool Function(String code) onSubmit;

  @override
  State<KeypadDialog> createState() => _KeypadDialogState();
}

class _KeypadDialogState extends State<KeypadDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  String _entry = '';
  bool _busy = false;
  bool? _result;

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _feedback() {
    unawaited(context.read<AudioManager>().play(Sfx.click, volume: .6));
    unawaited(context.read<Haptics>().tap());
  }

  void _press(String digit) {
    if (_busy || _entry.length >= widget.puzzle.length) return;
    _feedback();
    setState(() => _entry += digit);
    if (_entry.length == widget.puzzle.length) unawaited(_submit());
  }

  void _erase() {
    if (_busy || _entry.isEmpty) return;
    _feedback();
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _submit() async {
    _busy = true;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    final ok = widget.onSubmit(_entry);
    setState(() => _result = ok);

    if (ok) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    unawaited(_shake.forward(from: 0));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _entry = '';
      _result = null;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width * .82, 330.0);
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final t = _shake.value;
                  return Transform.translate(
                    offset: Offset(math.sin(t * math.pi * 6) * (1 - t) * 14, 0),
                    child: child,
                  );
                },
                child: _panel(width),
              ),
              const SizedBox(height: 20),
              GhostButton(
                label: context.tr(UiText.stepBack),
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel(double width) {
    const rows = [
      ['0', '1', '2'],
      ['3', '4', '5'],
      ['6', '7', '8'],
    ];
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1817), Color(0xFF0C0A0A)],
        ),
        border: Border.all(color: AppColors.smoke),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 40)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.tr(widget.puzzle.title), style: AppText.label),
          const SizedBox(height: 18),
          _Display(
            entry: _entry,
            length: widget.puzzle.length,
            result: _result,
          ),
          const SizedBox(height: 22),
          for (final row in rows)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final d in row) _Key(label: d, onTap: () => _press(d)),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: _Key.size, height: _Key.size),
              _Key(label: '9', onTap: () => _press('9')),
              _Key(icon: Icons.backspace_outlined, onTap: _erase),
            ],
          ),
        ],
      ),
    );
  }
}

class _Display extends StatelessWidget {
  const _Display({
    required this.entry,
    required this.length,
    required this.result,
  });

  final String entry;
  final int length;
  final bool? result;

  @override
  Widget build(BuildContext context) {
    final color = switch (result) {
      true => const Color(0xFF9FB59A),
      false => AppColors.bloodLight,
      null => AppColors.bone,
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF050404),
        border: Border.all(color: AppColors.soot),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < length; i++)
            Container(
              width: 38,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color.withValues(alpha: .5)),
                ),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppText.mono.copyWith(fontSize: 30, color: color),
                child: Text(
                  i < entry.length ? entry[i] : ' ',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({this.label, this.icon, required this.onTap});

  static const size = 64.0;

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    return Semantics(
      button: true,
      label: widget.label ?? 'Erase',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: _Key.size,
          height: _Key.size,
          margin: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _down ? AppColors.bloodDeep : const Color(0xFF141110),
            border: Border.all(
              color: _down ? AppColors.blood : AppColors.smoke,
            ),
          ),
          child: icon != null
              ? Icon(icon, size: 20, color: AppColors.ash)
              : Text(
                  widget.label ?? '',
                  style: AppText.mono.copyWith(fontSize: 22),
                ),
        ),
      ),
    );
  }
}
