import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';

class BikeRemoteControlsPerformance extends StatelessWidget {
  final BleState ble;
  final WidgetRef ref;
  final VoidCallback onStateChanged;
  final void Function(String message) onHeroSnack;

  const BikeRemoteControlsPerformance({
    super.key,
    required this.ble,
    required this.ref,
    required this.onStateChanged,
    required this.onHeroSnack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RENDIMIENTO Y VELOCIDAD',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [BoxShadow(color: Color(0x040F172A), blurRadius: 10, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Límite de velocidad seguro 60 km/h',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Conducción urbana segura y +15% de autonomía',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: ble.speedLimitMode == 1,
                    activeTrackColor: BskmtColors.crimson,
                    onChanged: (v) async {
                      final res = await ref.read(bleProvider.notifier).setSafeSpeedLimit60(v);
                      onHeroSnack(res);
                      onStateChanged();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modo Ciudad (Entrega suave)',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Acelerador progresivo, ideal para tráfico y acompañante',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: ble.grabMode == 1,
                    activeTrackColor: const Color(0xFF10B981),
                    onChanged: (v) async {
                      ref.read(bleProvider.notifier).setGrabMode(v ? 1 : 0);
                      final res = await ref.read(bleProvider.notifier).setFwGrabMode(v);
                      onHeroSnack(res);
                      onStateChanged();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

