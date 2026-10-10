import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/utils/audio_manager.dart';
import '../core/utils/game_storage.dart';
import '../core/utils/haptics.dart';
import '../game/screens/splash_screen.dart';
import 'settings_cubit.dart';
import 'theme.dart';

class TheDoorApp extends StatefulWidget {
  const TheDoorApp({
    super.key,
    required this.storage,
    required this.audio,
    required this.haptics,
  });

  final GameStorage storage;
  final AudioManager audio;
  final Haptics haptics;

  @override
  State<TheDoorApp> createState() => _TheDoorAppState();
}

class _TheDoorAppState extends State<TheDoorApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Stop the drone when the phone is put away; resume when it comes back.
    _lifecycle = AppLifecycleListener(
      onHide: () => unawaited(widget.audio.pauseAll()),
      onShow: () => unawaited(widget.audio.resumeAll()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(widget.audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.storage),
        RepositoryProvider.value(value: widget.audio),
        RepositoryProvider.value(value: widget.haptics),
      ],
      child: BlocProvider(
        create: (_) => SettingsCubit(
          storage: widget.storage,
          audio: widget.audio,
          haptics: widget.haptics,
        ),
        child: MaterialApp(
          title: 'The Door',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
