import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';
import 'bike_trip_eco_banner.dart';
import 'bike_trip_history_sheet.dart';
import 'bike_trip_metric_item.dart';

class BikeTripCard extends StatelessWidget {
  final TripData trip;

  const BikeTripCard({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final mins = trip.duration.inMinutes;
    final secs = trip.duration.inSeconds % 60;
    final durationText = mins > 0
        ? '$mins min ${secs > 0 ? "$secs s" : ""} · En curso'
        : (secs > 0 ? '$secs seg · En curso' : 'Listo para registrar');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  color: BskmtColors.crimson,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trayecto y Telemetría Actual',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      durationText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => BikeTripHistorySheet.show(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Historial',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BskmtColors.crimson,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: BskmtColors.crimson,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BikeTripMetricItem(
                  icon: Icons.straighten_rounded,
                  iconColor: BskmtColors.crimson,
                  label: 'Distancia',
                  value: trip.distanceKm.toStringAsFixed(1),
                  unit: 'km',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BikeTripMetricItem(
                  icon: Icons.speed_rounded,
                  iconColor: const Color(0xFF0D9488),
                  label: 'Vel. Promedio',
                  value: trip.avgSpeedKmh.toStringAsFixed(1),
                  unit: 'km/h',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: BikeTripMetricItem(
                  icon: Icons.electric_bolt_rounded,
                  iconColor: const Color(0xFFD97706),
                  label: 'Vel. Máxima',
                  value: trip.maxSpeedKmh.toStringAsFixed(0),
                  unit: 'km/h',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BikeTripMetricItem(
                  icon: Icons.battery_charging_full_rounded,
                  iconColor: const Color(0xFF059669),
                  label: 'Consumo Batería',
                  value: '-${trip.usedPercent}',
                  unit: '%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BikeTripEcoBanner(trip: trip),
        ],
      ),
    );
  }
}
