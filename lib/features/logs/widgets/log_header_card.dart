import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class LogHeaderCard extends StatelessWidget {
  final int fileCount;
  final String? dirPath;
  final bool isExporting;
  final VoidCallback onExportAll;

  const LogHeaderCard({
    super.key,
    required this.fileCount,
    required this.dirPath,
    required this.isExporting,
    required this.onExportAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Panel(
        padding: const EdgeInsets.all(16),
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_rounded, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'DATOS DE TELEMETRÍA Y GATT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05 * 11,
                    color: AppColors.textDim,
                  ),
                ),
                const Spacer(),
                StatusPill(
                  label: '$fileCount ARCHIVOS',
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Cada conexión genera un archivo JSONL con la tabla GATT, telemetría hexadecimal '
              'y estado del enlace para diagnóstico técnico de la moto.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDim, height: 1.4),
            ),
            if (dirPath != null) ...[
              const SizedBox(height: 6),
              Text(
                'Directorio: $dirPath',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(
                'Exportar todo → Downloads/BskmtLogs',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              onPressed: fileCount == 0 || isExporting ? null : onExportAll,
            ),
          ],
        ),
      ),
    );
  }
}

