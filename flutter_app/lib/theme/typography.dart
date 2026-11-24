import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Cormorant SC for display, Source Serif 4 for all UI copy.
abstract final class InkText {
  static TextStyle display({
    double size = 22,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.goldHi,
    double? height = 1.15,
    double? letterSpacing = 0.4,
  }) =>
      GoogleFonts.getFont('Cormorant SC',
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing);

  static TextStyle body({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ivory,
    double? height = 1.45,
    double? letterSpacing,
  }) =>
      GoogleFonts.getFont('Source Serif 4',
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing);

  static TextStyle get hero => display(size: 52, color: AppColors.ivory, height: 1.05);
  static TextStyle get h1 => display(size: 30, height: 1.1);
  static TextStyle get h2 => display(size: 22);
  static TextStyle get topBar => display(size: 22);
  static TextStyle get section => display(size: 18);
  static TextStyle get bodyLg => body(size: 17);
  static TextStyle get small => body(size: 14, color: AppColors.ivory2);
  static TextStyle get caption => body(size: 13, color: AppColors.ivory2);
  static TextStyle get button => body(size: 17, weight: FontWeight.w600);
  static TextStyle get tab => body(size: 12, weight: FontWeight.w600, height: 1.2);
  static TextStyle get score => display(size: 34, color: AppColors.ivory, height: 1);

  static TextTheme textTheme() => TextTheme(
        displayLarge: hero,
        displayMedium: display(size: 40),
        headlineMedium: h1,
        titleLarge: h2,
        titleMedium: section,
        bodyLarge: bodyLg,
        bodyMedium: body(),
        bodySmall: small,
        labelLarge: button,
        labelMedium: body(size: 15, weight: FontWeight.w600),
        labelSmall: tab,
      );
}
