import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';

class BikeRemoteControlsAlarms extends StatelessWidget {
  final BleState ble;
  final WidgetRef ref;
  final VoidCallback onStateChanged;
  final void Function(String message) onHeroSnack;

  const BikeRemoteControlsAlarms({
    super.key,
    required this.ble,
    required this.ref,
    required this.onStateChanged,
    required this.onHeroSnack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.security_rounded, color: Color(0xFFEF4444), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alarma antirrobo reforzada', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text('Bloqueo severo si la moto se mueve sin señal', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              Switch.adaptive(
                value: ble.antiTheft5m,
                activeTrackColor: const Color(0xFFEF4444),
                onChanged: (v) {
                  ref.read(bleProvider.notifier).setAntiTheft5m(v);
                  onStateChanged();
                  onHeroSnack(v ? 'Alarma antirrobo activada' : 'Alarma antirrobo desactivada');
                },
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1, indent: 56, endIndent: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ble.isFindingBike ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  ble.isFindingBike ? Icons.volume_off_rounded : Icons.campaign_rounded,
                  color: ble.isFindingBike ? const Color(0xFFEF4444) : BskmtColors.crimson,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alarma localizadora', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(
                      ble.isFindingBike ? 'Sonando pito y destellando luces…' : 'Hacer sonar pito y encender luces',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: ble.isFindingBike ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                        fontWeight: ble.isFindingBike ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ble.isFindingBike ? const Color(0xFFEF4444) : BskmtColors.crimson,
                  side: BorderSide(color: ble.isFindingBike ? const Color(0xFFEF4444) : const Color(0xFFFECACA)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (ble.isFindingBike) {
                    final msg = await ref.read(bleProvider.notifier).stopFindBike();
                    onHeroSnack(msg);
                  } else {
                    final msg = await ref.read(bleProvider.notifier).findBike();
                    onHeroSnack(msg);
                  }
                  onStateChanged();
                },
                child: Text(ble.isFindingBike ? 'SILENCIAR' : 'LOCALIZAR', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

