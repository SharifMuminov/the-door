import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/l10n/l_text.dart';
import '../core/utils/audio_manager.dart';
import '../core/utils/game_storage.dart';
import '../core/utils/haptics.dart';

@immutable
class SettingsState {
  const SettingsState({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.language,
    required this.languageChosen,
  });

  final bool soundEnabled;
  final bool vibrationEnabled;
  final AppLanguage language;

  /// False until the player picks a language on first launch.
  final bool languageChosen;

  SettingsState copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    AppLanguage? language,
    bool? languageChosen,
  }) => SettingsState(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    language: language ?? this.language,
    languageChosen: languageChosen ?? this.languageChosen,
  );
}

/// Sound, vibration and language. Persists them and applies sound and
/// vibration to their services immediately.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required GameStorage storage,
    required AudioManager audio,
    required Haptics haptics,
  }) : _storage = storage,
       _audio = audio,
       _haptics = haptics,
       super(_initial(storage)) {
    _apply(state);
  }

  final GameStorage _storage;
  final AudioManager _audio;
  final Haptics _haptics;

  static SettingsState _initial(GameStorage storage) {
    final saved = AppLanguage.fromCode(storage.languageCode);
    final device = PlatformDispatcher.instance.locale.languageCode;
    return SettingsState(
      soundEnabled: storage.soundEnabled,
      vibrationEnabled: storage.vibrationEnabled,
      language: saved ?? (device == 'uz' ? AppLanguage.uz : AppLanguage.en),
      languageChosen: saved != null,
    );
  }

  void toggleSound() {
    final next = state.copyWith(soundEnabled: !state.soundEnabled);
    _apply(next);
    emit(next);
    unawaited(_storage.setSoundEnabled(next.soundEnabled));
  }

  void toggleVibration() {
    final next = state.copyWith(vibrationEnabled: !state.vibrationEnabled);
    _apply(next);
    emit(next);
    unawaited(_storage.setVibrationEnabled(next.vibrationEnabled));
    if (next.vibrationEnabled) unawaited(_haptics.medium());
  }

  void setLanguage(AppLanguage language) {
    emit(state.copyWith(language: language, languageChosen: true));
    unawaited(_storage.setLanguageCode(language.name));
  }

  void cycleLanguage() {
    final all = AppLanguage.values;
    setLanguage(all[(state.language.index + 1) % all.length]);
  }

  void _apply(SettingsState s) {
    _audio.enabled = s.soundEnabled;
    _haptics.enabled = s.vibrationEnabled;
  }
}

extension Localize on BuildContext {
  /// The current language. Rebuilds the caller when it changes.
  AppLanguage get language =>
      select<SettingsCubit, AppLanguage>((c) => c.state.language);

  /// Resolves [text] in the current language (use inside build methods).
  String tr(LText text) => text.of(language);
}
