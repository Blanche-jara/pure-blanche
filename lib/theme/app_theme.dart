import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.abyss,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.abyss,
        primary: AppColors.signalGreen,
        secondary: AppColors.mint,
        onSurface: AppColors.snow,
      ),
      textTheme: _textTheme,
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          AppColors.warmCharcoal.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  static TextTheme get _textTheme {
    final bodyFont = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return bodyFont.copyWith(
      // Display / Hero — 60px system-ui
      displayLarge: const TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 60,
        fontWeight: FontWeight.w400,
        height: 1.0,
        letterSpacing: -0.65,
        color: AppColors.snow,
      ),
      // Section Heading — 36px
      displayMedium: const TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.11,
        letterSpacing: -0.9,
        color: AppColors.snow,
      ),
      // Sub-heading Bold — 24px
      headlineLarge: const TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.33,
        letterSpacing: -0.6,
        color: AppColors.snow,
      ),
      // Overline — 14px uppercase
      labelLarge: const TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        letterSpacing: 2.52,
        color: AppColors.signalGreen,
      ),
      // Body — 16px Inter
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.65,
        color: AppColors.parchment,
      ),
      // Body small — 14px Inter
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.steel,
      ),
    );
  }
}
