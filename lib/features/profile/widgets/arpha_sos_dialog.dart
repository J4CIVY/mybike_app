import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/bskmt_provider.dart';
import '../../../core/services/trip_gps_tracker.dart';
import '../../../ui/app_theme.dart';

class ArphaSosDialog {
  static void show(BuildContext context, WidgetRef ref) {
    String selectedType = 'mecanica';
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.emergency_rounded, color: AppColors.error, size: 26),
              const SizedBox(width: 10),
              Text(
                'Solicitar Asistencia ARPHA',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El equipo de auxilio en carretera recibirá tus coordenadas GPS y placa para despachar apoyo inmediato.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDim),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tipo de emergencia:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'mecanica', child: Text('Falla Mecánica / Motor')),
                    DropdownMenuItem(value: 'electrica', child: Text('Falla Eléctrica / Batería')),
                    DropdownMenuItem(value: 'remolque', child: Text('Grúa / Pinchazo')),
                    DropdownMenuItem(value: 'medica', child: Text('Asistencia Médica')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  'Detalle de la situación (opcional):',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Ej: Se apagó en la vía a La Calera',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'CANCELAR',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textDim),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final loc = await TripGpsTracker.instance.getCurrentLocation();
                final lat = loc?.latitude ?? 4.7110;
                final lng = loc?.longitude ?? -74.0721;

                final ok = await ref.read(bskmtProvider.notifier).requestArphaHelp(
                      lat: lat,
                      lng: lng,
                      requestType: selectedType,
                      description: descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : 'Solicitud enviada desde Cockpit App',
                    );

                if (context.mounted) {
                  final state = ref.read(bskmtProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? state.successMessage ?? 'Solicitud enviada' : state.errorMessage ?? 'Error al solicitar ARPHA'),
                      backgroundColor: ok ? AppColors.tertiary : AppColors.error,
                    ),
                  );
                }
              },
              child: Text(
                'DESPACHAR AUXILIO',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

