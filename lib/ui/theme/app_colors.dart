import 'package:flutter/material.dart';

/// Paleta oficial de colores para BSKMT Cockpit
class AppColors {
  AppColors._();

  // Superficies BSKMT
  static const surface = Color(0xFFF8FAFC);
  static const surfaceDim = Color(0xFFE2E8F0);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF8FAFC);
  static const surfaceContainer = Color(0xFFF1F5F9);
  static const surfaceContainerHigh = Color(0xFFE2E8F0);
  static const surfaceContainerHighest = Color(0xFFCBD5E1);
  static const surfaceVariant = Color(0xFFF1F5F9);

  // Fondos y Paneles
  static const bg = Color(0xFFF8FAFC);
  static const darkBg = Color(0xFF0B0F17);
  static const panel = Color(0xFFFFFFFF);
  static const panelDark = Color(0xFF1E293B);
  static const panelSecondary = Color(0xFFF8FAFC);
  static const panelBorder = Color(0xFFF1F5F9);
  static const panelBorderBright = Color(0xFFE2E8F0);
  static const borderSubtle = Color(0xFFF1F5F9);

  // Colores Principales de Marca BSKMT
  static const primary = Color(0xFFDC2626); // Rojo BSKMT (Red 600)
  static const crimson = Color(0xFFDC2626);
  static const primaryRose = Color(0xFFE11D48); // Rose 600 BSKMT
  static const primaryContainer = Color(0xFF991B1B); // Red 800
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFFEF2F2);

  // Acentos y Membresía Legend
  static const secondary = Color(0xFFF59E0B); // Amber 500
  static const secondaryContainer = Color(0xFFFEF3C7);
  static const onSecondary = Color(0xFF0F172A);
  static const onSecondaryContainer = Color(0xFF78350F);

  // Eco, Batería Saludable & Documentos al Día
  static const tertiary = Color(0xFF10B981); // Emerald 500
  static const tertiaryContainer = Color(0xFFD1FAE5);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF064E3B);

  // Tipografía y Contrastes
  static const onSurface = Color(0xFF0F172A);
  static const onSurfaceVariant = Color(0xFF475569);
  static const textPrimary = Color(0xFF0F172A); // Slate 900
  static const textDim = Color(0xFF475569);     // Slate 600
  static const textMuted = Color(0xFF94A3B8);   // Slate 400

  // Acentos funcionales
  static const accent = Color(0xFFDC2626);
  static const accentDim = Color(0xFFB91C1C);
  static const cyan = Color(0xFF0EA5E9);
  static const mint = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);

  // Estados de error
  static const error = Color(0xFFDC2626);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFEE2E2);
  static const onErrorContainer = Color(0xFF7F1D1D);

  // Sombras y halos sutiles
  static const cardShadow = [
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const modalShadow = [
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const activeHalo = BoxShadow(
    color: Color(0x28DC2626),
    spreadRadius: 3,
    blurRadius: 0,
  );
}

/// Alias para compatibilidad con widgets del tema BSKMT
class BskmtColors {
  BskmtColors._();
  static const crimson = Color(0xFFDC2626);
}
