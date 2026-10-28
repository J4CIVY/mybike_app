import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../trip_route_screen.dart';
import 'bike_trip_history_item.dart';
import 'bike_trip_weekly_summary.dart';

class BikeTripHistorySheet {
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
          final history = ble.tripHistory;

          final now = DateTime.now();
          final oneWeekAgo = now.subtract(const Duration(days: 7));
          final weekTrips = history.where((t) => t.startTime.isAfter(oneWeekAgo)).toList();

          final weekDist = weekTrips.fold<double>(0.0, (sum, t) => sum + t.distanceKm);
          final weekCount = weekTrips.length;
          final savedMoney = (weekDist * 180).round();
          final savedCo2 = (weekDist * 0.065);

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView(
                  controller: scrollController,
                  children: [
                    const SizedBox(height: 12),
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
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Historial de Rutas',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Telemetría, eficiencia y trayectos guardados',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (history.isNotEmpty)
                          IconButton(
                            tooltip: 'Eliminar historial',
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  title: Text('¿Eliminar Historial?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                                  content: Text(
                                    '¿Estás seguro de que deseas eliminar todas las rutas guardadas en este dispositivo?',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: Text('CANCELAR', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                      onPressed: () => Navigator.pop(c, true),
                                      child: Text('ELIMINAR TODO', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await sheetRef.read(bleProvider.notifier).clearTripHistory();
                              }
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    BikeTripWeeklySummary(
                      weekDist: weekDist,
                      weekCount: weekCount,
                      savedMoney: savedMoney,
                      savedCo2: savedCo2,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'RUTAS RECIENTES',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (history.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.route_outlined, size: 44, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text(
                              'Aún no hay rutas guardadas',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Los trayectos se registran automáticamente cuando la moto\nse desplaza más de 50 metros o al apagar el motor.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ...history.asMap().entries.map((entry) {
                        final index = entry.key;
                        final trip = entry.value;
                        final isRecent = index == 0;
                        final durMin = trip.durationSec ~/ 60;
                        final durSec = trip.durationSec % 60;
                        final durText = durMin > 0 ? '$durMin min $durSec s' : '$durSec s';
                        final timeStr = '${trip.startTime.day.toString().padLeft(2, '0')}/${trip.startTime.month.toString().padLeft(2, '0')} · ${trip.startTime.hour.toString().padLeft(2, '0')}:${trip.startTime.minute.toString().padLeft(2, '0')} ($durText)';
                        final co2 = (trip.distanceKm * 0.065).toStringAsFixed(1);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TripRouteScreen(
                                    trip: trip,
                                    tripIndex: history.length - index,
                                    allTrips: history,
                                  ),
                                ),
                              );
                            },
                            child: BikeTripHistoryItem(
                              title: 'Ruta #${history.length - index}',
                              time: timeStr,
                              distance: '${trip.distanceKm.toStringAsFixed(1)} km',
                              avgSpeed: '${trip.avgSpeedKmh.toStringAsFixed(0)} km/h',
                              batteryUsed: trip.usedPercent > 0 ? '-${trip.usedPercent}%' : '--',
                              co2Saved: '$co2 kg',
                              isRecent: isRecent,
                              hasGps: trip.route.isNotEmpty,
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
