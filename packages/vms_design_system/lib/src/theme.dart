import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Material theme mapped onto VMS tokens. Widgets in this package style
/// themselves explicitly (inputs use [vmsInputDecoration]); the theme covers
/// framework widgets we don't wrap.
ThemeData buildVmsTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: VmsColors.nav,
    primary: VmsColors.primary,
    onPrimary: Colors.white,
    secondary: VmsColors.nav,
    error: VmsColors.danger,
    surface: VmsColors.surface,
    onSurface: VmsColors.text,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: VmsColors.page,
    dividerColor: VmsColors.divider,
    textTheme: const TextTheme(
      headlineMedium: VmsText.title,
      titleMedium: VmsText.h2,
      bodyLarge: VmsText.body,
      bodyMedium: VmsText.table,
      bodySmall: VmsText.meta,
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: VmsColors.text,
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      actionTextColor: VmsColors.primary,
    ),
    tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 400)),
    focusColor: VmsColors.focusRing,
  );
}
