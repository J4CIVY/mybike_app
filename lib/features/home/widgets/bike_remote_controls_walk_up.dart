import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import 'bike_remote_controls_helpers.dart';

class BikeRemoteControlsWalkUp extends StatelessWidget {
  final BleState ble;
  final WidgetRef ref;
  final VoidCallback onStateChanged;
  final void Function(String message) onHeroSnack;

  const BikeRemoteControlsWalkUp({
    super.key,
    required this.ble,
    required this.ref,
    required this.onStateChanged,
    required this.onHeroSnack,
  });

  String _nearDistLabel(double rssi) {
    if (rssi >= -48.0) return '0.5m';
    if (rssi >= -52.0) return '0.8m';
    if (rssi >= -58.0) return '1.5m';
    if (rssi >= -65.0) return '2.5m';
    return '3.5m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetToggleRow(
          icon: Icons.key_rounded,
          iconColor: const Color(0xFF10B981),
          iconBg: const Color(0xFFF0FDF4),
          title: 'Apertura al acercarte (Walk-Up)',
          subtitle: 'Desbloquea automáticamente al aproximarte',
          value: ble.walkUpUnlock,
          onChanged: (v) {
            ref.read(bleProvider.notifier).setWalkUpUnlock(v);
            onStateChanged();
            onHeroSnack(v ? 'Apertura automática activada' : 'Apertura automática desactivada');
          },
        ),
        if (ble.walkUpUnlock) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: ble.walkUpAutoPowerOn ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ble.walkUpAutoPowerOn ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: ble.walkUpAutoPowerOn ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1), shape: BoxShape.circle),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Encendido inmediato al lado', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                      Text('Desbloquea y enciende el sistema Ready al estar junto a la moto', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: ble.walkUpAutoPowerOn,
                  activeTrackColor: const Color(0xFFF59E0B),
                  onChanged: (v) {
                    ref.read(bleProvider.notifier).setWalkUpAutoPowerOn(v);
                    onStateChanged();
                    onHeroSnack(v ? 'Encendido automático listo al aproximarte' : 'Encendido automático desactivado');
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sensibilidad de detección cercana:', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${(ble.walkUpRssiThreshold ?? -55.0).round()} dBm · ~${_nearDistLabel(ble.walkUpRssiThreshold ?? -55.0)}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SheetSegmentPill(
                      label: 'Muy cerca',
                      sub: '~0.8m (-50dBm)',
                      selected: (ble.walkUpRssiThreshold ?? -55.0) >= -52.0,
                      onTap: () {
                        ref.read(bleProvider.notifier).setWalkUpRssiThreshold(-50.0);
                        onStateChanged();
                        onHeroSnack('Sensibilidad: Muy cerca (~0.8m · -50 dBm)');
                      },
                    ),
                    const SizedBox(width: 8),
                    SheetSegmentPill(
                      label: 'Cerca',
                      sub: '~1.5m (-55dBm)',
                      selected: (ble.walkUpRssiThreshold ?? -55.0) < -52.0 && (ble.walkUpRssiThreshold ?? -55.0) > -58.0,
                      onTap: () {
                        ref.read(bleProvider.notifier).setWalkUpRssiThreshold(-55.0);
                        onStateChanged();
                        onHeroSnack('Sensibilidad: Cerca (~1.5m · -55 dBm)');
                      },
                    ),
                    const SizedBox(width: 8),
                    SheetSegmentPill(
                      label: 'Media dist.',
                      sub: '~2.5m (-62dBm)',
                      selected: (ble.walkUpRssiThreshold ?? -55.0) <= -58.0,
                      onTap: () {
                        ref.read(bleProvider.notifier).setWalkUpRssiThreshold(-62.0);
                        onStateChanged();
                        onHeroSnack('Sensibilidad: Media distancia (~2.5m · -62 dBm)');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: const Color(0xFF10B981),
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                    thumbColor: const Color(0xFF10B981),
                    overlayColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: (ble.walkUpRssiThreshold ?? -55.0).clamp(-70.0, -45.0),
                    min: -70.0,
                    max: -45.0,
                    divisions: 25,
                    onChanged: (val) {
                      ref.read(bleProvider.notifier).setWalkUpRssiThreshold(val);
                      onStateChanged();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

