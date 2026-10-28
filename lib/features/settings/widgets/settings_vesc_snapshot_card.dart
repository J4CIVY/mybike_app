import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';

class SettingsVescSnapshotCard extends StatelessWidget {
  final BleState ble;
  final bool connected;
  final bool isRefreshingDiagnostics;
  final VoidCallback onRefreshDiagnostics;

  const SettingsVescSnapshotCard({
    super.key,
    required this.ble,
    required this.connected,
    required this.isRefreshingDiagnostics,
    required this.onRefreshDiagnostics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panelSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.panelBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.memory_rounded, size: 14, color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'IDENTIFICACIÓN HARDWARE & SNAPSHOT VESC',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textDim,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: connected && !isRefreshingDiagnostics ? onRefreshDiagnostics : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: connected ? const Color(0xFF8B5CF6).withValues(alpha: 0.12) : AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: connected ? const Color(0xFF8B5CF6).withValues(alpha: 0.3) : AppColors.panelBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRefreshingDiagnostics)
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF8B5CF6)),
                        )
                      else
                        const Icon(Icons.refresh_rounded, size: 12, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 4),
                      Text(
                        isRefreshingDiagnostics ? 'Leyendo...' : 'Actualizar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: connected ? const Color(0xFF8B5CF6) : AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Modelo: ', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDim)),
                  Text(
                    ble.bikeModelCode ?? 'QT_S1',
                    style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text('Manifest: ', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDim)),
                  Expanded(
                    child: Text(
                      ble.boardManifest ?? '—',
                      style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.panelBorder, width: 0.8),
            ),
            child: Row(
              children: [
                _vescMetric('Corriente VESC', '${(ble.vescCurrent ?? 0.0).toStringAsFixed(2)} A'),
                Container(width: 1, height: 20, color: AppColors.panelBorder),
                _vescMetric('Voltaje VESC', '${(ble.vescVoltage ?? 0.0).toStringAsFixed(1)} V'),
                Container(width: 1, height: 20, color: AppColors.panelBorder),
                _vescMetric('Duty Cycle', '${((ble.vescDutyCycle ?? 0.0) * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vescMetric(String label, String value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.textDim)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

