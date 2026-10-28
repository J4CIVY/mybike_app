import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

export 'theme/app_colors.dart';
export 'theme/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => light();
  static ThemeData get darkTheme => dark();

  static ThemeData light() {
    final baseText = GoogleFonts.plusJakartaSansTextTheme();

    final scheme = const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      surface: AppColors.panel,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.onError,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: baseText.copyWith(
        displayLarge: AppTypography.displayLgMobile(),
        headlineLarge: AppTypography.headlineXlMobile(),
        headlineMedium: AppTypography.headlineMd(),
        headlineSmall: AppTypography.headlineSm(),
        bodyLarge: AppTypography.bodyLg(),
        bodyMedium: AppTypography.bodyMd(),
        bodySmall: AppTypography.bodySm(),
        labelLarge: AppTypography.labelLg(),
        labelMedium: AppTypography.labelMd(),
        labelSmall: AppTypography.labelSm(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 20),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.panelBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.panelBorder,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.panel,
        elevation: 0,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textDim,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textDim,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.panel,
          side: const BorderSide(color: AppColors.panelBorder, width: 1),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.onSurface,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.textDim,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.panelSecondary,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.transparent : AppColors.panelBorder,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.panelSecondary,
      ),
    );
  }

  static ThemeData dark() {
    final baseText = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

    final scheme = const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      surface: Color(0xFF1E293B),
      onSurface: Color(0xFFF1F5F9),
      error: AppColors.error,
      onError: AppColors.onError,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: baseText.copyWith(
        displayLarge: AppTypography.displayLgMobile(color: Colors.white),
        headlineLarge: AppTypography.headlineXlMobile(color: Colors.white),
        headlineMedium: AppTypography.headlineMd(color: Colors.white),
        headlineSmall: AppTypography.headlineSm(color: Colors.white),
        bodyLarge: AppTypography.bodyLg(color: const Color(0xFFF1F5F9)),
        bodyMedium: AppTypography.bodyMd(color: const Color(0xFFCBD5E1)),
        bodySmall: AppTypography.bodySm(color: const Color(0xFF94A3B8)),
        labelLarge: AppTypography.labelLg(color: Colors.white),
        labelMedium: AppTypography.labelMd(color: const Color(0xFFCBD5E1)),
        labelSmall: AppTypography.labelSm(color: const Color(0xFF94A3B8)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 20),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
