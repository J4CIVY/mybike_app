import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/offline_map_service.dart';
import '../../../ui/app_theme.dart';

class OfflineMapActionButtons extends StatelessWidget {
  final DownloadProgress progress;
  final String estimatedSizeText;
  final VoidCallback onStartDownload;
  final VoidCallback onResumeDownload;
  final VoidCallback onPauseDownload;
  final VoidCallback onCancelDownload;

  const OfflineMapActionButtons({
    super.key,
    required this.progress,
    required this.estimatedSizeText,
    required this.onStartDownload,
    required this.onResumeDownload,
    required this.onPauseDownload,
    required this.onCancelDownload,
  });

  @override
  Widget build(BuildContext context) {
    if (progress.isRunning) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amber,
                side: const BorderSide(color: AppColors.amber),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onPauseDownload,
              icon: const Icon(Icons.pause_circle_outline_rounded, size: 20),
              label: Text('PAUSAR', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onCancelDownload,
              icon: const Icon(Icons.stop_circle_outlined, size: 20),
              label: Text('CANCELAR', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ],
      );
    }

    if (progress.isPaused) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onResumeDownload,
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: Text('CONTINUAR DESCARGA', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3)),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: onStartDownload,
      icon: const Icon(Icons.download_rounded, size: 20),
      label: Text('DESCARGAR ZONA SELECCIONADA (~$estimatedSizeText)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3)),
    );
  }
}

