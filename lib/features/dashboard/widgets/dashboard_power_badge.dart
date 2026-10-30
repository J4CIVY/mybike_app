import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

class DashboardPowerBadge extends StatelessWidget {
  final double powerKw;
  final bool isRecup;
  final bool isDraw;

  const DashboardPowerBadge({
    super.key,
    required this.powerKw,
    required this.isRecup,
    required this.isDraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isRecup
            ? AppColors.tertiary.withValues(alpha: 0.12)
            : isDraw
            ? AppColors.secondary.withValues(alpha: 0.12)
            : AppColors.panelSecondary,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: isRecup
              ? AppColors.tertiary
              : isDraw
              ? AppColors.secondary
              : AppColors.panelBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRecup
                ? Icons.recycling_rounded
                : isDraw
                ? Icons.electric_bolt_rounded
                : Icons.remove_rounded,
            size: 14,
            color: isRecup
                ? AppColors.tertiary
                : isDraw
                ? AppColors.secondary
                : AppColors.textDim,
          ),
          const SizedBox(width: 5),
          Text(
            isRecup
                ? '+${powerKw.toStringAsFixed(2)} kW RECUP'
                : isDraw
                ? '${powerKw.abs().toStringAsFixed(2)} kW'
                : '0.00 kW',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isRecup
                  ? AppColors.tertiary
                  : isDraw
                  ? AppColors.secondary
                  : AppColors.textDim,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
