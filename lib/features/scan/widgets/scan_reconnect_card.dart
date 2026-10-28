import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class ScanReconnectCard extends StatelessWidget {
  final String? bikeName;
  final bool connecting;
  final VoidCallback onTap;

  const ScanReconnectCard({
    super.key,
    required this.bikeName,
    required this.connecting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: connecting ? null : onTap,
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      hasActiveHalo: true,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bikeName ?? 'Última moto vinculada',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Toque para conectar directamente sin esperar escaneo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          connecting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }
}

