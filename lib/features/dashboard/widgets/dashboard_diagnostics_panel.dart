import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/proto/bike_log.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class DashboardDiagnosticsPanel extends StatelessWidget {
  final BikeLogMsg msg;
  final VoidCallback onOpenBatteryDiagnostics;

  const DashboardDiagnosticsPanel({
    super.key,
    required this.msg,
    required this.onOpenBatteryDiagnostics,
  });

  List<String> _decodeErrors(int errorCode) {
    if (errorCode == 0) return ['✅ Todos los sistemas operando normalmente'];
    final errors = <String>[];
    if ((errorCode & (1 << 0)) != 0) errors.add('⚠️ Falla en sensor acelerador (Throttle Fault)');
    if ((errorCode & (1 << 1)) != 0) errors.add('⚠️ Falla en sensor Hall motor (Motor Hall)');
    if ((errorCode & (1 << 2)) != 0) errors.add('⚠️ Sobrecorriente en motor (Over-Current)');
    if ((errorCode & (1 << 3)) != 0) errors.add('⚠️ Sobrecalentamiento ECU (ECU Overheat)');
    if ((errorCode & (1 << 4)) != 0) errors.add('⚠️ Falla de comunicación BMS (BMS Comm)');
    if ((errorCode & (1 << 5)) != 0) errors.add('⚠️ Sobrecalentamiento Batería (Battery Overheat)');
    if ((errorCode & (1 << 6)) != 0) errors.add('⚠️ Alerta voltaje bajo batería (Low Voltage)');
    if ((errorCode & (1 << 7)) != 0) errors.add('⚠️ Falla en interruptor de freno (Brake Cutoff)');
    if (errors.isEmpty) errors.add('⚠️ Código de falla del sistema: 0x${errorCode.toRadixString(16).toUpperCase()}');
    return errors;
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(14),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('MONITOREO TÉRMICO (3 PUNTOS)'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.thermostat_rounded,
                  label: 'TEMP ECU',
                  value: '${msg.ecu.toStringAsFixed(0)}°',
                  valueColor: msg.ecu > 65 ? AppColors.error : (msg.ecu > 55 ? AppColors.amber : AppColors.textPrimary),
                  accentColor: msg.ecu > 65 ? AppColors.error : AppColors.secondary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: MetricTile(
                  icon: Icons.device_thermostat_rounded,
                  label: 'TEMP MOTOR',
                  value: '${msg.motor.toStringAsFixed(0)}°',
                  valueColor: msg.motor > 75 ? AppColors.error : (msg.motor > 60 ? AppColors.amber : AppColors.textPrimary),
                  accentColor: msg.motor > 75 ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: MetricTile(
                  icon: Icons.battery_std_rounded,
                  label: 'TEMP BMS',
                  value: '${msg.bmsTemp.toStringAsFixed(0)}°',
                  valueColor: msg.bmsTemp > 50 ? AppColors.error : (msg.bmsTemp > 45 ? AppColors.amber : AppColors.textPrimary),
                  accentColor: msg.bmsTemp > 50 ? AppColors.error : AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.panelBorder),
          const SizedBox(height: 12),

          const SectionTitle('DIAGNÓSTICO OBD & CÓDIGOS DE ERROR'),
          const SizedBox(height: 8),
          for (final errLine in _decodeErrors(msg.error))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    msg.error == 0 ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    size: 18,
                    color: msg.error == 0 ? AppColors.tertiary : AppColors.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errLine,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: msg.error == 0 ? AppColors.tertiary : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.battery_charging_full_rounded, size: 18),
              label: Text(
                'VER DIAGNÓSTICO DETALLADO DE BATERÍA',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              onPressed: onOpenBatteryDiagnostics,
            ),
          ),
        ],
      ),
    );
  }
}

