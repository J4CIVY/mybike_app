import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../core/services/bskmt_provider.dart';
import '../../../ui/app_theme.dart';
import '../../scan/scan_screen.dart';

class BikeSwitcherSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, sheetRef, _) {
          final ble = sheetRef.watch(bleProvider);
          final bskmt = sheetRef.watch(bskmtProvider);
          final activeMotorcycle = bskmt.activeMotorcycle;

          final serial = (ble.frameSerial != null && ble.frameSerial!.trim().isNotEmpty)
              ? ble.frameSerial!.trim()
              : (ble.lastTelemetry != null && ble.lastTelemetry!.frame.trim().isNotEmpty
                  ? ble.lastTelemetry!.frame.trim()
                  : (activeMotorcycle?['vin'] ?? activeMotorcycle?['plate'] ?? 'Chasis no identificado'));
          final connected = ble.phase == BlePhase.connected;
          final percent = ble.lastTelemetry?.percent;
          final kmLeft = (ble.lastTelemetry != null && ble.lastTelemetry!.kmLeft > 0)
              ? ble.lastTelemetry!.kmLeft.round()
              : null;
          final infoStr = (connected && percent != null)
              ? '$serial · $percent% Batería${kmLeft != null ? " ($kmLeft km)" : ""}'
              : (connected ? '$serial · Conectada BLE' : '$serial · Desconectada');

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tus Motos Registradas',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Garaje Virtual BSKMT & Dispositivos BLE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Color(0x100F172A), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/bike_logo_3d.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.two_wheeler_rounded, color: BskmtColors.crimson, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    activeMotorcycle != null
                                        ? '${activeMotorcycle['brand'] ?? 'Moto'} ${activeMotorcycle['model'] ?? ''}'
                                        : (ble.bikeName ?? 'BSKMT Smart EV'),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: BskmtColors.crimson,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'ACTIVA',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              infoStr,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded, color: BskmtColors.crimson, size: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bluetooth_searching_rounded, size: 18, color: BskmtColors.crimson),
                        const SizedBox(width: 8),
                        Text(
                          'BUSCAR Y EMPAREJAR MOTO (BLUETOOTH BLE)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: BskmtColors.crimson,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

