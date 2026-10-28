import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

class ChargingVisualCard extends StatelessWidget {
  final bool isCharging;
  final String percentStr;

  const ChargingVisualCard({
    super.key,
    required this.isCharging,
    required this.percentStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 235,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.panel,
        border: Border.all(color: AppColors.panelBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/bike_xray.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.bolt_rounded, size: 80, color: AppColors.tertiary),
            ),
          ),
          Positioned(
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isCharging ? AppColors.tertiary.withValues(alpha: 0.9) : const Color(0xE60F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCharging ? const Color(0xFF86EFAC) : AppColors.panelBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCharging ? const Color(0x6622C55E) : const Color(0x33000000),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCharging ? Icons.bolt_rounded : Icons.battery_charging_full_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$percentStr%',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

