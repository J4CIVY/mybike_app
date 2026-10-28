import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class ScanEmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const ScanEmptyState({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(24),
      borderRadius: 20,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bluetooth_searching_rounded, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'No se encontraron motos cercanas',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '• Asegúrese de que la moto tenga la energía encendida\n'
            '• Manténgase a una distancia de 3 a 5 metros\n'
            '• Verifique que el Bluetooth del teléfono esté activo',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textDim,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.radar, size: 18),
            label: Text('Reintentar', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

