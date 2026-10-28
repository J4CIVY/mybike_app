import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart' show TripRecord;
import '../../../ui/app_theme.dart';
import 'trip_route_speed_legend.dart';

class TripRouteInfoSheet {
  static void show({
    required BuildContext context,
    required TripRecord trip,
    required int routePointsCount,
    required bool isSimulated,
  }) {
    final durMin = trip.durationSec ~/ 60;
    final durSec = trip.durationSec % 60;
    final durText = durMin > 0 ? '$durMin min $durSec s' : '$durSec s';
    final co2Kg = (trip.distanceKm * 0.065).toStringAsFixed(2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.80,
          ),
          decoration: const BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.panelBorderBright)),
            boxShadow: AppColors.modalShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.info_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Detalles del viaje',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textDim),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.panelBorder, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    Text(
                      'RANGOS DE VELOCIDAD',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const TripRouteSpeedLegend(),
                    const SizedBox(height: 18),
                    Text(
                      'ESTADÍSTICAS DEL VIAJE',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.panelSecondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.panelBorderBright),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _metricTile('DISTANCIA', '${trip.distanceKm.toStringAsFixed(1)} km', Icons.straighten_rounded)),
                              Expanded(child: _metricTile('DURACIÓN', durText, Icons.timer_outlined)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _metricTile('VELOCIDAD MÁXIMA', '${trip.maxSpeedKmh.toStringAsFixed(0)} km/h', Icons.speed_rounded)),
                              Expanded(child: _metricTile('VELOCIDAD PROMEDIO', '${trip.avgSpeedKmh.toStringAsFixed(0)} km/h', Icons.moving_rounded)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _metricTile('CO2 AHORRADO', '$co2Kg kg', Icons.eco_rounded)),
                              Expanded(child: _metricTile('CONSUMO BATERÍA', trip.usedPercent > 0 ? '-${trip.usedPercent}%' : '--', Icons.battery_charging_full_rounded)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _metricTile('PUNTOS GPS', '$routePointsCount puntos capturados', Icons.gps_fixed_rounded)),
                              Expanded(child: _metricTile('ORIGEN DATOS', isSimulated ? 'Simulación GPS' : 'GPS Real', Icons.sensors_rounded)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _metricTile(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDim,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
