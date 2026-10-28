import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

class LogPreviewPanel extends StatelessWidget {
  final String previewText;
  final VoidCallback onShare;
  final VoidCallback onClose;

  const LogPreviewPanel({
    super.key,
    required this.previewText,
    required this.onShare,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.panelBorder, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.panelSecondary,
              border: Border(bottom: BorderSide(color: AppColors.panelBorder, width: 1)),
            ),
            child: Row(
              children: [
                Text(
                  'DETALLE DEL REGISTRO',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.05 * 11,
                    color: AppColors.textDim,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copiar todo',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: previewText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Registro copiado al portapapeles!')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 18),
                  tooltip: 'Compartir archivo',
                  onPressed: onShare,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Cerrar vista',
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                previewText,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

