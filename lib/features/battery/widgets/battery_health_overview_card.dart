import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/battery_diagnostics_service.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class BatteryHealthOverviewCard extends StatelessWidget {
  final BatteryHealthReport report;
  final int socPercent;

  const BatteryHealthOverviewCard({
    super.key,
    required this.report,
    required this.socPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: CircularProgressIndicator(
                      value: report.hasLiveTelemetry
                          ? (report.safetyScore / 100.0)
                          : 0.0,
                      strokeWidth: 6,
                      backgroundColor: AppColors.panelBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        !report.hasLiveTelemetry
                            ? AppColors.textDim
                            : (report.safetyScore >= 90
                                  ? AppColors.tertiary
                                  : (report.safetyScore >= 70
                                        ? AppColors.amber
                                        : AppColors.error)),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        report.hasLiveTelemetry
                            ? '${report.safetyScore}'
                            : '--',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: report.hasLiveTelemetry
                              ? AppColors.textPrimary
                              : AppColors.textDim,
                        ),
                      ),
                      Text(
                        'PUNTOS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Salud de Batería (SoH)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          report.hasLiveTelemetry
                              ? '${report.healthPercentage}%'
                              : '--',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: report.hasLiveTelemetry
                                ? AppColors.primary
                                : AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      !report.hasLiveTelemetry
                          ? 'Sin conexión — Esperando datos de telemetría.'
                          : (report.safetyScore >= 90
                                ? 'Todas las celdas y sistemas eléctricos operan en óptimo estado.'
                                : 'Alerta en el sistema detectada. Revise los códigos OBD abajo.'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.panelBorder, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMiniMetric(
                label: 'VOLTAJE PACK',
                value: report.hasLiveTelemetry && report.packVoltage > 0
                    ? '${report.packVoltage.toStringAsFixed(1)} V'
                    : '-- V',
              ),
              _buildMiniMetric(
                label: 'CORRIENTE',
                value: report.hasLiveTelemetry
                    ? '${report.currentAmp >= 0 ? "+" : ""}${report.currentAmp.toStringAsFixed(1)} A'
                    : '-- A',
                valueColor: report.hasLiveTelemetry
                    ? (report.currentAmp < -0.5
                          ? AppColors.tertiary
                          : (report.currentAmp > 0.5
                                ? AppColors.secondary
                                : AppColors.textDim))
                    : AppColors.textDim,
              ),
              _buildMiniMetric(
                label: 'CICLOS CARGA',
                value: report.hasLiveTelemetry
                    ? '${report.chargeCycles} c.'
                    : '--',
              ),
              _buildMiniMetric(
                label: 'RESISTENCIA',
                value:
                    report.hasLiveTelemetry && report.internalResistanceMo > 0
                    ? '${report.internalResistanceMo.toStringAsFixed(1)} mΩ'
                    : '-- mΩ',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05 * 10,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
