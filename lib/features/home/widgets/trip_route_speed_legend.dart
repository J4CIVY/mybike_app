import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

class TripRouteSpeedLegend extends StatelessWidget {
  const TripRouteSpeedLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panelSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.panelBorderBright),
      ),
      child: Column(
        children: [
          _speedLegendRow(const Color(0xFF06B6D4), '< 15 km/h', 'Detenido o marcha lenta'),
          const Divider(color: AppColors.panelBorder, height: 16),
          _speedLegendRow(const Color(0xFF10B981), '15 – 35 km/h', 'Velocidad urbana constante'),
          const Divider(color: AppColors.panelBorder, height: 16),
          _speedLegendRow(const Color(0xFFF59E0B), '35 – 55 km/h', 'Vía rápida / avenidas'),
          const Divider(color: AppColors.panelBorder, height: 16),
          _speedLegendRow(const Color(0xFFEF4444), '> 55 km/h', 'Carretera / alta velocidad'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'La ruta cambia de color según la velocidad real registrada.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _speedLegendRow(Color color, String range, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 85,
          child: Text(
            range,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textDim,
            ),
          ),
        ),
      ],
    );
  }
}

