import 'package:flutter/material.dart';

import 'text_styles.dart';
import 'tokens.dart';

/// Material is plumbing only: no ripples, no elevation, square shapes.
ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: HsColors.paper,
    canvasColor: HsColors.paper,
    colorScheme: const ColorScheme.light(
      primary: HsColors.ink,
      onPrimary: HsColors.label,
      secondary: HsColors.ink,
      onSecondary: HsColors.label,
      surface: HsColors.label,
      onSurface: HsColors.ink,
      error: HsColors.stamp,
      onError: HsColors.label,
      outline: HsColors.ink,
      outlineVariant: HsColors.rule,
    ),
    fontFamily: HsFonts.serif,
    textTheme: TextTheme(
      displaySmall: HsText.display,
      headlineLarge: HsText.h1,
      headlineMedium: HsText.h2,
      bodyLarge: HsText.body,
      bodyMedium: HsText.body,
      bodySmall: HsText.small,
      labelLarge: HsText.button,
      labelMedium: HsText.chip,
      labelSmall: HsText.eyebrow,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    focusColor: HsColors.rule,
    dividerTheme: const DividerThemeData(
      color: HsColors.rule,
      thickness: 1,
      space: 1,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: HsColors.ink,
      selectionColor: HsColors.rule,
      selectionHandleColor: HsColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: HsColors.label,
      hintStyle: HsText.caslon(16, italic: true, color: HsColors.ink),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: HsColors.ink, width: 1.5),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: HsColors.ink, width: 1.5),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: HsColors.ink, width: 2),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: HsColors.paper,
      elevation: 0,
      shape: Border(top: BorderSide(color: HsColors.ink, width: 2)),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: HsColors.label,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: HsColors.ink, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: HsColors.ink,
      contentTextStyle: HsText.caslon(15, italic: true, color: HsColors.label),
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      behavior: SnackBarBehavior.floating,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: _FadeTransitionsBuilder()},
    ),
  );
}

/// Plain 200 ms fade between screens (docs/design.md §10). No sliding.
class _FadeTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}
