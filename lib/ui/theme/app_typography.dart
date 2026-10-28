import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografía estandarizada Space Grotesk y Plus Jakarta Sans para BSKMT Cockpit
class AppTypography {
  AppTypography._();

  static TextStyle evWide({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing ?? -0.5,
        height: height,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle displayLg({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 56,
        fontWeight: FontWeight.w600,
        height: 64 / 56,
        letterSpacing: -0.03 * 56,
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle displayLgMobile({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        height: 48 / 40,
        letterSpacing: -0.02 * 40,
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle headlineXl({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 44 / 36,
        letterSpacing: -0.02 * 36,
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle headlineXlMobile({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 36 / 28,
        letterSpacing: -0.01 * 28,
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle headlineMd({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 32 / 24,
        letterSpacing: -0.01 * 24,
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle headlineSm({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 28 / 20,
        letterSpacing: 0,
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle bodyLg({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodyMd({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 22 / 15,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodySm({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        color: color ?? AppColors.textDim,
      );

  static TextStyle labelLg({Color? color, FontWeight? fontWeight}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.01 * 14,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle labelMd({Color? color, FontWeight? fontWeight}) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.04 * 12,
        color: color ?? AppColors.textDim,
      );

  static TextStyle labelSm({Color? color, FontWeight? fontWeight}) => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: fontWeight ?? FontWeight.w500,
        height: 14 / 11,
        letterSpacing: 0.06 * 11,
        color: color ?? AppColors.textDim,
      );
}

