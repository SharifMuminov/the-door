import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/settings_cubit.dart';
import '../../app/theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/l_text.dart';
import '../../core/l10n/ui_text.dart';
import '../../core/utils/fade_route.dart';
import '../widgets/ghost_button.dart';
import 'main_menu_screen.dart';

/// First launch: pick a language. Then a few seconds of black and a
/// warning. Tap to skip.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late bool _choosing = !context.read<SettingsCubit>().state.languageChosen;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    if (!_choosing) _run();
  }

  void _run() => _c.forward().whenComplete(_leave);

  void _choose(AppLanguage language) {
    context.read<SettingsCubit>().setLanguage(language);
    setState(() => _choosing = false);
    _run();
  }

  void _leave() {
    if (_left || _choosing || !mounted) return;
    _left = true;
    unawaited(
      Navigator.of(context).pushReplacement(
        FadeRoute(
          builder: (_) => const MainMenuScreen(),
          duration: const Duration(milliseconds: 900),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _choosing ? _languagePicker() : _warning(),
      ),
    );
  }

  Widget _languagePicker() {
    return Center(
      key: const ValueKey('language'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('CHOOSE A LANGUAGE', style: AppText.label),
          const SizedBox(height: 6),
          Text(
            'TILNI TANLANG',
            style: AppText.label.copyWith(color: AppColors.smoke),
          ),
          const SizedBox(height: 36),
          for (final language in AppLanguage.values)
            GhostButton(
              label: language.label,
              style: AppText.menuButton,
              onTap: () => _choose(language),
            ),
        ],
      ),
    );
  }

  Widget _warning() {
    return GestureDetector(
      key: const ValueKey('warning'),
      behavior: HitTestBehavior.opaque,
      onTap: _leave,
      child: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => Opacity(
            opacity: math.sin(_c.value * math.pi).clamp(0, 1),
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 1,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ember.withValues(alpha: .6),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                  color: AppColors.ember.withValues(alpha: .8),
                ),
              ),
              const SizedBox(height: 34),
              Text(context.tr(UiText.headphones), style: AppText.label),
              const SizedBox(height: 10),
              Text(
                context.tr(UiText.playInDark),
                style: AppText.tagline.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
