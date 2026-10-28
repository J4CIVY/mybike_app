import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

class OfflineMapSheetHeader extends StatelessWidget {
  const OfflineMapSheetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.downloading_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DESCARGAR MAPAS SIN CONEXIÓN',
                      style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                    Text(
                      '0 ms de latencia · Navegación sin señal 4G/LTE',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textDim),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.panelBorder, height: 1),
      ],
    );
  }
}

