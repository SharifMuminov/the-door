import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/settings_cubit.dart';
import '../../app/theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_timings.dart';
import '../../core/l10n/ui_text.dart';
import 'ghost_button.dart';

Future<void> showSettingsDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: AppColors.black.withValues(alpha: .8),
    transitionDuration: GameTimings.dialog,
    pageBuilder: (context, _, _) => const SettingsDialog(),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width * .84, 340.0);
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(26, 30, 26, 14),
          decoration: BoxDecoration(
            color: AppColors.night,
            border: Border.all(color: AppColors.smoke.withValues(alpha: .7)),
          ),
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              final cubit = context.read<SettingsCubit>();
              String onOff(bool v) => context.tr(v ? UiText.on : UiText.off);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.tr(UiText.settings), style: AppText.label),
                  const SizedBox(height: 26),
                  _Row(
                    label: context.tr(UiText.sound),
                    value: onOff(state.soundEnabled),
                    active: state.soundEnabled,
                    onTap: cubit.toggleSound,
                  ),
                  _Row(
                    label: context.tr(UiText.vibration),
                    value: onOff(state.vibrationEnabled),
                    active: state.vibrationEnabled,
                    onTap: cubit.toggleVibration,
                  ),
                  _Row(
                    label: context.tr(UiText.language),
                    value: state.language.label,
                    active: true,
                    onTap: cubit.cycleLanguage,
                  ),
                  const SizedBox(height: 16),
                  GhostButton(
                    label: context.tr(UiText.close),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.menuButton.copyWith(
                    fontSize: 15,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedDefaultTextStyle(
                duration: GameTimings.tap,
                style: AppText.label.copyWith(
                  color: active ? AppColors.bone : AppColors.smoke,
                  letterSpacing: 3,
                ),
                child: Text(value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
