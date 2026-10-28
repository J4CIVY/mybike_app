import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/battery_diagnostics_service.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class ObdDiagnosticsCard extends StatelessWidget {
  final BatteryHealthReport report;

  const ObdDiagnosticsCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final activeErrors = report.obdItems.where((e) => !e.isHealthy).toList();

    return Panel(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (!report.hasLiveTelemetry
                          ? AppColors.textDim
                          : (activeErrors.isEmpty ? AppColors.tertiary : AppColors.error))
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  !report.hasLiveTelemetry
                      ? Icons.sensors_off_rounded
                      : (activeErrors.isEmpty ? Icons.check_circle_rounded : Icons.warning_rounded),
                  color: !report.hasLiveTelemetry
                      ? AppColors.textDim
                      : (activeErrors.isEmpty ? AppColors.tertiary : AppColors.error),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      !report.hasLiveTelemetry
                          ? 'Sin conexión — Esperando datos de telemetría'
                          : (activeErrors.isEmpty
                              ? 'Los 8 sistemas de hardware operan perfectamente'
                              : '¡Detectadas ${activeErrors.length} anomalías de hardware!'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: !report.hasLiveTelemetry
                            ? AppColors.textDim
                            : (activeErrors.isEmpty ? AppColors.tertiary : AppColors.error),
                      ),
                    ),
                    Text(
                      !report.hasLiveTelemetry
                          ? 'Conecte Bluetooth para escanear los 8 sistemas OBD'
                          : 'Monitoreo en tiempo real vía telemetría',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.panelSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.panelBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.memory_rounded, size: 16, color: AppColors.textDim),
                const SizedBox(width: 8),
                Text(
                  'VESC mc_fault_code:',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDim,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (!report.hasLiveTelemetry
                            ? AppColors.textDim
                            : (report.rawErrorCode == 0 ? AppColors.tertiary : AppColors.error))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    report.hasLiveTelemetry
                        ? '0x${report.rawErrorCode.toRadixString(16).padLeft(2, '0').toUpperCase()} (${report.rawErrorCode})'
                        : '--',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: !report.hasLiveTelemetry
                          ? AppColors.textDim
                          : (report.rawErrorCode == 0 ? AppColors.tertiary : AppColors.error),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  !report.hasLiveTelemetry
                      ? 'DESCONECTADO'
                      : (report.rawErrorCode == 0 ? 'SIN FALLAS' : 'ANOMALÍA DETECTADA'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: !report.hasLiveTelemetry
                        ? AppColors.textDim
                        : (report.rawErrorCode == 0 ? AppColors.tertiary : AppColors.error),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.panelBorder, height: 1),
          const SizedBox(height: 6),
          ...report.obdItems.map((item) => _buildObdItemTile(context, item, report.hasLiveTelemetry)),
        ],
      ),
    );
  }

  Widget _buildObdItemTile(BuildContext context, ObdDiagnosticItem item, bool hasLiveTelemetry) {
    final statusColor = !hasLiveTelemetry
        ? AppColors.textDim
        : (item.isHealthy ? AppColors.tertiary : AppColors.error);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        leading: Icon(
          !hasLiveTelemetry
              ? Icons.radio_button_unchecked_rounded
              : (item.isHealthy ? Icons.check_circle_outline_rounded : Icons.error_rounded),
          color: statusColor,
          size: 20,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: (hasLiveTelemetry && !item.isHealthy) ? FontWeight.w700 : FontWeight.w500,
                  color: (hasLiveTelemetry && !item.isHealthy) ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                !hasLiveTelemetry ? 'SIN CONEXIÓN' : item.code,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.panelSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalle técnico:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDim,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acción recomendada:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: !hasLiveTelemetry
                        ? AppColors.textDim
                        : (item.isHealthy ? AppColors.primary : AppColors.error),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.recommendation,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

