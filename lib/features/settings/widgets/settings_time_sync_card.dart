import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class SettingsTimeSyncCard extends StatelessWidget {
  final BleState ble;
  final bool connected;
  final bool isSyncingTime;
  final VoidCallback onSyncTime;

  const SettingsTimeSyncCard({
    super.key,
    required this.ble,
    required this.connected,
    required this.isSyncingTime,
    required this.onSyncTime,
  });

  @override
  Widget build(BuildContext context) {
    final lastSync = ble.lastTimeSynced;
    final lastSyncStr = lastSync != null
        ? '${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}:${lastSync.second.toString().padLeft(2, '0')} (${lastSync.day}/${lastSync.month})'
        : 'Sin sincronizar en esta sesión';

    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reloj del Panel Digital',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Última sinc: $lastSyncStr',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: lastSync != null ? AppColors.tertiary : AppColors.textDim,
                        fontWeight: lastSync != null ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: connected ? AppColors.primary : AppColors.surface,
                  foregroundColor: connected ? Colors.white : AppColors.textDim,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: isSyncingTime
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync_rounded, size: 16),
                label: Text(
                  isSyncingTime ? 'Enviando...' : 'Sincronizar',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: (connected && !isSyncingTime) ? onSyncTime : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Envía la hora local actual vía canal protegido (0x44E2BDE6) al reloj RTC interno de la moto para corregir la hora del tablero tras desconectar la batería.',
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textDim, height: 1.4),
          ),
        ],
      ),
    );
  }
}

