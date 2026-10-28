import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

class ChargingProfilePill extends StatelessWidget {
  final String label;
  final String sub;
  final bool selected;
  final bool connected;
  final VoidCallback onTap;

  const ChargingProfilePill({
    super.key,
    required this.label,
    required this.sub,
    required this.selected,
    required this.connected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: connected ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.panelSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.panelBorder,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

