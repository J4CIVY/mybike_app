import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';
import 'bike_remote_controls_helpers.dart';

class BikeRemoteControlsWalkAway extends StatelessWidget {
  final BleState ble;
  final WidgetRef ref;
  final VoidCallback onStateChanged;
  final void Function(String message) onHeroSnack;

  const BikeRemoteControlsWalkAway({
    super.key,
    required this.ble,
    required this.ref,
    required this.onStateChanged,
    required this.onHeroSnack,
  });

  String _lockDistLabel(double rssi) {
    if (rssi >= -76.0) return '3m';
    if (rssi >= -84.0) return '5m';
    if (rssi >= -90.0) return '8m';
    return '10m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetToggleRow(
          icon: Icons.lock_clock_rounded,
          iconColor: BskmtColors.crimson,
          iconBg: const Color(0xFFFEF2F2),
          title: 'Bloqueo al alejarse (Walk-Away)',
          subtitle: 'Bloquea el seguro al salir del radio Bluetooth',
          value: ble.autoLockWalkAway,
          onChanged: (v) {
            ref.read(bleProvider.notifier).setAutoLockWalkAway(v);
            onStateChanged();
            onHeroSnack(v ? 'Bloqueo por alejamiento activado' : 'Bloqueo por alejamiento desactivado');
          },
        ),
        if (ble.autoLockWalkAway)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Distancia de bloqueo por alejamiento:', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${(ble.autoLockRssiThreshold ?? [-75.0, -83.0, -90.0][ble.autoLockDistance.clamp(0, 2)]).round()} dBm · ~${_lockDistLabel(ble.autoLockRssiThreshold ?? [-75.0, -83.0, -90.0][ble.autoLockDistance.clamp(0, 2)])}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: BskmtColors.crimson),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SheetSegmentPill(
                      label: 'Cerca',
                      sub: '~3m (-75dBm)',
                      selected: (ble.autoLockRssiThreshold ?? -83.0) >= -78.0,
                      onTap: () {
                        ref.read(bleProvider.notifier).setAutoLockRssiThreshold(-75.0);
                        onStateChanged();
                        onHeroSnack('Umbral de bloqueo: Cerca (~3m · -75 dBm)');
                      },
                    ),
                    const SizedBox(width: 8),
                    SheetSegmentPill(
                      label: 'Medio',
                      sub: '~5m (-83dBm)',
                      selected: (ble.autoLockRssiThreshold ?? -83.0) < -78.0 && (ble.autoLockRssiThreshold ?? -83.0) > -88.0,
                      onTap: () {
                        ref.read(bleProvider.notifier).setAutoLockRssiThreshold(-83.0);
                        onStateChanged();
                        onHeroSnack('Umbral de bloqueo: Medio (~5m · -83 dBm)');
                      },
                    ),
                    const SizedBox(width: 8),
                    SheetSegmentPill(
                      label: 'Lejos',
                      sub: '~8m (-90dBm)',
                      selected: (ble.autoLockRssiThreshold ?? -83.0) <= -88.0,
                      onTap: () {
                        ref.read(bleProvider.notifier).setAutoLockRssiThreshold(-90.0);
                        onStateChanged();
                        onHeroSnack('Umbral de bloqueo: Lejos (~8m · -90 dBm)');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: BskmtColors.crimson,
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                    thumbColor: BskmtColors.crimson,
                    overlayColor: BskmtColors.crimson.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: (ble.autoLockRssiThreshold ?? -83.0).clamp(-95.0, -68.0),
                    min: -95.0,
                    max: -68.0,
                    divisions: 27,
                    onChanged: (val) {
                      ref.read(bleProvider.notifier).setAutoLockRssiThreshold(val);
                      onStateChanged();
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

