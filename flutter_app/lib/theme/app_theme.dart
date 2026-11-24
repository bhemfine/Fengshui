import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// Dark-only theme. Scaffolds are transparent so the starfield shows.
ThemeData buildInkTheme() {
  const scheme = ColorScheme.dark(
    surface: AppColors.panel,
    onSurface: AppColors.ivory,
    primary: AppColors.primaryTop,
    onPrimary: AppColors.ivory,
    secondary: AppColors.gold,
    onSecondary: AppColors.ink,
    error: AppColors.ox,
    onError: AppColors.ivory,
    outline: AppColors.goldDim,
  );
  final text = InkText.textTheme();
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: AppColors.ink,
    textTheme: text,
    dividerColor: AppColors.hairline,
    splashFactory: InkRipple.splashFactory,
    iconTheme: const IconThemeData(color: AppColors.ivory),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.gold2,
      selectionColor: Color(0x66E3D6B8),
      selectionHandleColor: AppColors.gold2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: InkText.body(size: 15, color: const Color(0xFFA39D90)),
      labelStyle: InkText.body(size: 15, color: AppColors.ivory2),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.goldDim),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.goldHi,
      contentTextStyle: InkText.body(size: 15, weight: FontWeight.w600, color: AppColors.ink),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.ink2,
      modalBarrierColor: AppColors.scrim,
      showDragHandle: true,
      dragHandleColor: AppColors.goldDim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: AppColors.gold),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: AppColors.gold),
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.gold : Colors.transparent),
      checkColor: const WidgetStatePropertyAll(AppColors.ink),
    ),
  );
}
