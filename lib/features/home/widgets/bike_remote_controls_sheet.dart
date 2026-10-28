import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';
import '../../settings/vehicle_settings_screen.dart';
import 'bike_remote_controls_alarms.dart';
import 'bike_remote_controls_performance.dart';
import 'bike_remote_controls_security.dart';

class BikeRemoteControlsSheet {
  static void show({
    required BuildContext context,
    required void Function(String message) onHeroSnack,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, sheetRef, _) => StatefulBuilder(
          builder: (context, setSheetState) {
            final ble = sheetRef.watch(bleProvider);

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: const Icon(Icons.tune_rounded, color: BskmtColors.crimson, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Control Remoto y Seguridad',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Configuración de proximidad, alarma y potencia',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'SEGURIDAD Y BLOQUEO INTELIGENTE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x040F172A), blurRadius: 10, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          BikeRemoteControlsSecurity(
                            ble: ble,
                            ref: sheetRef,
                            onStateChanged: () => setSheetState(() {}),
                            onHeroSnack: onHeroSnack,
                          ),
                          const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1, indent: 56, endIndent: 16),
                          BikeRemoteControlsAlarms(
                            ble: ble,
                            ref: sheetRef,
                            onStateChanged: () => setSheetState(() {}),
                            onHeroSnack: onHeroSnack,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    BikeRemoteControlsPerformance(
                      ble: ble,
                      ref: sheetRef,
                      onStateChanged: () => setSheetState(() {}),
                      onHeroSnack: onHeroSnack,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VehicleSettingsScreen()));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.settings_outlined, size: 18, color: BskmtColors.crimson),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'TODOS LOS AJUSTES DE LA MOTO',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: BskmtColors.crimson),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 15, color: BskmtColors.crimson),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
