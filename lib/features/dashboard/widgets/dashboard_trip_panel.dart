import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../core/proto/bike_log.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';
import 'cockpit_live_map.dart';

class DashboardTripPanel extends StatelessWidget {
  final TripData trip;
  final BikeLogMsg msg;
  final VoidCallback onExpandFullScreen;

  const DashboardTripPanel({
    super.key,
    required this.trip,
    required this.msg,
    required this.onExpandFullScreen,
  });

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CockpitLiveMap(
          currentSpeedKmh: msg.speed,
          onExpandFullScreen: onExpandFullScreen,
        ),
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.all(14),
          borderRadius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ESTADÍSTICAS DEL VIAJE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.05 * 12,
                        color: AppColors.textDim,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(trip.duration),
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      icon: Icons.navigation_rounded,
                      label: 'DISTANCIA RECORRIDA',
                      value: trip.distanceKm.toStringAsFixed(2),
                      unit: 'km',
                      valueColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: MetricTile(
                      icon: Icons.speed_rounded,
                      label: 'VEL. MÁXIMA',
                      value: trip.maxSpeedKmh.toStringAsFixed(1),
                      unit: 'km/h',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      icon: Icons.timeline_rounded,
                      label: 'VEL. PROMEDIO',
                      value: trip.avgSpeedKmh.toStringAsFixed(1),
                      unit: 'km/h',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: MetricTile(
                      icon: Icons.battery_alert_rounded,
                      label: 'CONSUMO BATERÍA',
                      value: '-${trip.usedPercent}',
                      unit: '% bat',
                      valueColor: AppColors.amber,
                    ),
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
