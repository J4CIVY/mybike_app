import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../core/services/trip_gps_tracker.dart';
import '../../../ui/app_theme.dart';
import '../trip_route_screen.dart';

class BikeTripEcoBanner extends ConsumerWidget {
  final TripData trip;

  const BikeTripEcoBanner({
    super.key,
    required this.trip,
  });

  Future<void> _confirmResetTrip(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Reiniciar Odómetro Parcial?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Se restablecerá a cero la distancia, tiempo de manejo y velocidad promedio del trayecto actual.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCELAR', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: BskmtColors.crimson,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('REINICIAR', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      ref.read(bleProvider.notifier).resetTrip();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odómetro parcial (Trip) reiniciado a 0 km')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, size: 16, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ahorro de ${(trip.distanceKm * 0.16).toStringAsFixed(1)} kg de CO₂ frente a gasolina',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF166534),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              final curTrip = TripRecord(
                startTime: trip.duration.inSeconds > 0
                    ? DateTime.now().subtract(trip.duration)
                    : DateTime.now(),
                endTime: DateTime.now(),
                distanceKm: trip.distanceKm,
                durationSec: trip.duration.inSeconds,
                avgSpeedKmh: trip.avgSpeedKmh,
                maxSpeedKmh: trip.maxSpeedKmh,
                usedPercent: trip.usedPercent,
                route: TripGpsTracker.instance.getCurrentRoute(),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripRouteScreen(
                    trip: curTrip,
                    tripIndex: 0,
                    allTrips: ref.read(bleProvider).tripHistory,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.map_rounded, size: 14, color: BskmtColors.crimson),
                  const SizedBox(width: 4),
                  Text(
                    'Mapa',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: BskmtColors.crimson,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _confirmResetTrip(context, ref),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF166534)),
                  const SizedBox(width: 4),
                  Text(
                    'Reiniciar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
