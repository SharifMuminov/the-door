import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/settings_cubit.dart';
import '../../app/theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_timings.dart';
import '../../core/l10n/l_text.dart';
import 'ghost_button.dart';

class ChoiceDialogOption<T> {
  const ChoiceDialogOption(this.label, this.value, {this.danger = false});

  final LText label;
  final T value;
  final bool danger;
}

/// A dark card with a short text and a few choices.
/// Returns the chosen value, or null if dismissed.
Future<T?> showChoiceDialog<T>(
  BuildContext context, {
  required LText title,
  required LText body,
  required List<ChoiceDialogOption<T>> options,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: AppColors.black.withValues(alpha: .75),
    transitionDuration: GameTimings.dialog,
    pageBuilder: (context, _, _) =>
        ChoiceDialog<T>(title: title, body: body, options: options),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class ChoiceDialog<T> extends StatelessWidget {
  const ChoiceDialog({
    super.key,
    required this.title,
    required this.body,
    required this.options,
  });

  final LText title;
  final LText body;
  final List<ChoiceDialogOption<T>> options;

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width * .84, 340.0);
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 18),
          decoration: BoxDecoration(
            color: AppColors.night.withValues(alpha: .96),
            border: Border.all(color: AppColors.smoke.withValues(alpha: .7)),
            boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 40)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.tr(title), style: AppText.label),
              const SizedBox(height: 20),
              Text(
                context.tr(body),
                textAlign: TextAlign.center,
                style: AppText.whisper.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 22),
              for (final option in options)
                GhostButton(
                  label: context.tr(option.label),
                  style: AppText.menuButton.copyWith(
                    fontSize: 15,
                    letterSpacing: 5,
                  ),
                  color: option.danger ? AppColors.bloodLight : AppColors.bone,
                  onTap: () => Navigator.of(context).pop(option.value),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
