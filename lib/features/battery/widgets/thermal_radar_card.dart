import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/battery_diagnostics_service.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class ThermalRadarCard extends StatelessWidget {
  final BatteryHealthReport report;

  const ThermalRadarCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        children: [
          _buildThermalRow(report.motorThermal, Icons.electric_meter_rounded, report.hasLiveTelemetry),
          const Divider(color: AppColors.panelBorder, height: 20),
          _buildThermalRow(report.ecuThermal, Icons.memory_rounded, report.hasLiveTelemetry),
          const Divider(color: AppColors.panelBorder, height: 20),
          _buildThermalRow(report.bmsThermal, Icons.battery_charging_full_rounded, report.hasLiveTelemetry),
        ],
      ),
    );
  }

  Widget _buildThermalRow(ThermalZone zone, IconData icon, bool hasLiveTelemetry) {
    final isOnline = hasLiveTelemetry && zone.temperature > 0;
    final statusColor = isOnline ? Color(zone.status.colorValue) : AppColors.textDim;
    final ratio = isOnline ? (zone.temperature / zone.criticalTemp).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: statusColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    zone.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isOnline ? '${zone.temperature.toStringAsFixed(1)} °C' : '-- °C',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: AppColors.panelBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    isOnline ? 'Estado: ${zone.status.label}' : 'Estado: Esperando datos',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: statusColor),
                  ),
                  const Spacer(),
                  Text(
                    'Alerta: ${zone.warningTemp.round()}°C',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textDim),
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

