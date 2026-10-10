import 'package:flutter/foundation.dart';

enum AppLanguage {
  en('ENGLISH'),
  uz('O‘ZBEKCHA');

  const AppLanguage(this.label);

  /// The language's own name, shown in settings.
  final String label;

  static AppLanguage? fromCode(String? code) =>
      AppLanguage.values.where((l) => l.name == code).firstOrNull;
}

/// A piece of player-facing text in every supported language.
///
/// Game data (notes, whispers, room names) is written with these, so the
/// logic layer never needs a BuildContext; widgets resolve them with
/// `context.tr(...)`.
@immutable
class LText {
  const LText(this.en, this.uz);

  final String en;
  final String uz;

  String of(AppLanguage language) => switch (language) {
    AppLanguage.en => en,
    AppLanguage.uz => uz,
  };

  /// Same text with an untranslated prefix, e.g. a clock reading.
  LText prefixed(String prefix) => LText('$prefix$en', '$prefix$uz');

  /// Same text with an untranslated ending, e.g. a carved name.
  LText suffixed(String suffix) => LText('$en$suffix', '$uz$suffix');
}
