import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

class OfflineMapCacheCard extends StatelessWidget {
  final ({int tileCount, int totalBytes, String sizeText}) cacheStats;
  final bool isLoadingStats;
  final bool isDownloading;
  final VoidCallback onClearCache;

  const OfflineMapCacheCard({
    super.key,
    required this.cacheStats,
    required this.isLoadingStats,
    required this.isDownloading,
    required this.onClearCache,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panelSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.panelBorderBright),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage_rounded, color: AppColors.tertiary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALMACENAMIENTO DE MAPAS EN DISPOSITIVO',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDim,
                  ),
                ),
                Text(
                  isLoadingStats
                      ? 'Verificando…'
                      : '${cacheStats.sizeText} (${cacheStats.tileCount} fragmentos)',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (cacheStats.tileCount > 0 && !isDownloading)
            TextButton.icon(
              onPressed: onClearCache,
              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red),
              label: Text(
                'BORRAR',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

