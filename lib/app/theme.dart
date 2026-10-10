import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Typography and Material theme. The game should not look like a
/// regular Flutter app: no ripples, no bright colours, serif type.
abstract final class AppText {
  static const serif = 'Georgia';
  static const serifFallback = ['serif', 'Noto Serif', 'Times New Roman'];
  static const monoFamily = 'Courier';
  static const monoFallback = ['monospace', 'Courier New', 'Menlo'];

  static const title = TextStyle(
    fontFamily: serif,
    fontFamilyFallback: serifFallback,
    fontSize: 46,
    fontWeight: FontWeight.w400,
    letterSpacing: 10,
    color: AppColors.bone,
  );

  static const tagline = TextStyle(
    fontFamily: serif,
    fontFamilyFallback: serifFallback,
    fontSize: 15,
    fontStyle: FontStyle.italic,
    letterSpacing: .6,
    color: AppColors.ash,
  );

  /// Small, widely spaced capitals: ROOM 01, buttons, labels.
  static const label = TextStyle(
    fontFamily: serif,
    fontFamilyFallback: serifFallback,
    fontSize: 13,
    letterSpacing: 5,
    color: AppColors.ash,
  );

  static const menuButton = TextStyle(
    fontFamily: serif,
    fontFamilyFallback: serifFallback,
    fontSize: 17,
    letterSpacing: 7,
    color: AppColors.bone,
  );

  static const whisper = TextStyle(
    fontFamily: serif,
    fontFamilyFallback: serifFallback,
    fontSize: 15,
    height: 1.45,
    fontStyle: FontStyle.italic,
    color: AppColors.bone,
  );

  static const ink = TextStyle(
    fontFamily: serif,
    fontFamilyFallback: serifFallback,
    fontSize: 22,
    height: 1.35,
    letterSpacing: 2,
    color: AppColors.ink,
  );

  static const mono = TextStyle(
    fontFamily: monoFamily,
    fontFamilyFallback: monoFallback,
    fontSize: 16,
    letterSpacing: 1.5,
    color: AppColors.bone,
  );
}

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.bone,
      onPrimary: AppColors.black,
      secondary: AppColors.blood,
      onSecondary: AppColors.bone,
      surface: AppColors.night,
      onSurface: AppColors.bone,
      error: AppColors.blood,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.black,
      canvasColor: AppColors.black,
      fontFamily: AppText.serif,
      fontFamilyFallback: AppText.serifFallback,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.blood,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(
            backgroundColor: AppColors.black,
          ),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(
            backgroundColor: AppColors.black,
          ),
        },
      ),
    );
  }
}
