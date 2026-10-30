import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';
import 'panel.dart';

/// Barra de estado de batería y autonomía restante en formato cápsula.
class BatteryRangeCapsule extends StatelessWidget {
  final int percent;
  final double kmLeft;
  final bool isCharging;
  final VoidCallback? onTap;

  const BatteryRangeCapsule({
    super.key,
    required this.percent,
    required this.kmLeft,
    this.isCharging = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCharging
        ? AppColors.secondary
        : (percent < 20
              ? AppColors.error
              : (percent > 60 ? AppColors.tertiary : AppColors.primary));

    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 16,
      hasActiveHalo: isCharging,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCharging
                    ? Icons.bolt_rounded
                    : Icons.battery_charging_full_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCharging ? 'CARGA ACTIVA' : 'ESTADO DE BATERÍA & RANGO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05 * 11,
                  color: AppColors.textDim,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              height: 10,
              color: AppColors.panelSecondary,
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: (percent / 100.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Autonomía restante estimada',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textDim,
                ),
              ),
              Text(
                '${kmLeft.toStringAsFixed(1)} km',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (onTap != null) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.panelBorder, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Diagnóstico de Batería & OBD 24-Cell',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
