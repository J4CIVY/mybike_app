import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/offline_map_service.dart';
import '../../../ui/app_theme.dart';

class OfflineMapProgressCard extends StatelessWidget {
  final DownloadProgress progress;

  const OfflineMapProgressCard({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = progress.isRunning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: progress.isCompleted
            ? const Color(0xFFECFDF5)
            : (progress.isPaused ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: progress.isCompleted
              ? AppColors.tertiary
              : (progress.isPaused ? AppColors.amber : AppColors.primary),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (isDownloading) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        progress.isCompleted
                            ? '✅ DESCARGA COMPLETADA'
                            : (progress.isPaused ? '⏸️ DESCARGA PAUSADA' : 'DESCARGANDO MAPAS…'),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: progress.isCompleted
                              ? AppColors.tertiary
                              : (progress.isPaused ? AppColors.amber : AppColors.primary),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${progress.percentInt}%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: progress.percent,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: AlwaysStoppedAnimation(
                progress.isCompleted
                    ? AppColors.tertiary
                    : (progress.isPaused ? AppColors.amber : AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Descargados ${progress.current}/${progress.total} fragmentos (${progress.sizeMbText})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textDim,
                ),
              ),
              if (isDownloading)
                Text(
                  'Puedes cerrar esta ventana',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

