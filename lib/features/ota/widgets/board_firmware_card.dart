import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ota/ota_service.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class BoardFirmwareCard extends StatelessWidget {
  final BoardFirmware board;
  final bool isDone;
  final double? progress;
  final VoidCallback onDownload;

  const BoardFirmwareCard({
    super.key,
    required this.board,
    required this.isDone,
    this.progress,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDone ? Icons.check_circle_rounded : Icons.memory_rounded,
                  color: isDone ? AppColors.tertiary : AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        board.board,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Revisión: ${board.revision ?? "Estándar"}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
                isDone
                    ? const StatusPill(label: 'DESCARGADO', color: AppColors.tertiary)
                    : IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.panelSecondary,
                          foregroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        tooltip: 'Descargar archivo',
                        onPressed: onDownload,
                      ),
              ],
            ),
            if (progress != null && !isDone) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  color: AppColors.primary,
                  backgroundColor: AppColors.panelSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

