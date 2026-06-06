import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// "Night rail" 포커 룸 테마. 다크가 기본 정체성, 라이트는 보조 변형.
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final bg = isDark ? AppColors.bg : AppColors.lightBg;
  final surface = isDark ? AppColors.surface : AppColors.lightSurface;
  final surfaceHigh = isDark ? AppColors.surfaceHigh : Colors.white;
  final navBg = isDark ? AppColors.bgElevated : AppColors.lightSurface;
  final hairline = isDark ? AppColors.hairline : AppColors.lightHairline;
  final hairlineSoft = isDark
      ? AppColors.hairlineSoft
      : const Color(0xFFEDEBE2);
  final textHi = isDark ? AppColors.textHi : AppColors.inkHi;
  final textMid = isDark ? AppColors.textMid : AppColors.inkMid;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: AppColors.felt,
    onPrimary: AppColors.onAccent,
    primaryContainer: AppColors.feltDeep,
    onPrimaryContainer: Colors.white,
    secondary: AppColors.gold,
    onSecondary: const Color(0xFF2A1E05),
    secondaryContainer: AppColors.gold,
    onSecondaryContainer: const Color(0xFF2A1E05),
    tertiary: AppColors.gold,
    onTertiary: const Color(0xFF2A1E05),
    error: AppColors.danger,
    onError: Colors.white,
    surface: surface,
    onSurface: textHi,
    onSurfaceVariant: textMid,
    surfaceContainerHighest: surfaceHigh,
    outline: hairline,
    outlineVariant: hairlineSoft,
    shadow: Colors.black,
  );

  final textTheme = pokerTextTheme(textHi, textMid);

  OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.md),
    borderSide: BorderSide(color: c, width: w),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    textTheme: textTheme,
    splashColor: AppColors.felt.withValues(alpha: 0.10),
    highlightColor: AppColors.felt.withValues(alpha: 0.06),
    dividerTheme: DividerThemeData(color: hairlineSoft, thickness: 1, space: 1),

    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: textHi,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),

    // 카드: 그림자 대신 보더+톤으로 깊이. 큰 라운드.
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: hairline),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.felt,
        foregroundColor: AppColors.onAccent,
        disabledBackgroundColor: hairline,
        disabledForegroundColor: textMid,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.felt,
        side: BorderSide(color: AppColors.felt.withValues(alpha: 0.6)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.felt,
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: textHi),
    ),

    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.felt.withValues(alpha: 0.16)
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.felt : textMid,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
        textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        side: WidgetStatePropertyAll(BorderSide(color: hairline)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceHigh,
      enabledBorder: border(hairline),
      border: border(hairline),
      focusedBorder: border(AppColors.felt, 1.6),
      hintStyle: textTheme.bodyMedium?.copyWith(color: textMid),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.felt,
      thumbColor: AppColors.felt,
      inactiveTrackColor: hairline,
      overlayColor: AppColors.felt.withValues(alpha: 0.14),
      trackHeight: 4,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: navBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: AppColors.felt.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => textTheme.labelSmall?.copyWith(
          color: s.contains(WidgetState.selected) ? AppColors.felt : textMid,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? AppColors.felt : textMid,
        ),
      ),
      height: 66,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: surfaceHigh,
      contentTextStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: hairline),
      backgroundColor: surfaceHigh,
    ),
  );
}
