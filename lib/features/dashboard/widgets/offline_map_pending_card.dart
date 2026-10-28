import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

class OfflineMapPendingCard extends StatelessWidget {
  final Map<String, dynamic> pendingTask;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const OfflineMapPendingCard({
    super.key,
    required this.pendingTask,
    required this.onResume,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: AppColors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DESCARGA PENDIENTE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Se detectó una descarga incompleta: "${pendingTask['regionName']}". Puedes reanudar la descarga de los fragmentos restantes.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: const Color(0xFF78350F),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    'CONTINUAR DESCARGA',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onDiscard,
                child: Text(
                  'DESCARTAR',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF92400E), fontWeight: FontWeight.w700, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

