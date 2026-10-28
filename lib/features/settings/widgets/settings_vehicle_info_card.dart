import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';
import 'settings_vesc_snapshot_card.dart';

class SettingsVehicleInfoCard extends StatelessWidget {
  final BleState ble;
  final bool connected;
  final String fwVersion;
  final bool isReadingSerial;
  final bool isRefreshingDiagnostics;
  final VoidCallback onReadSerial;
  final VoidCallback onRefreshDiagnostics;

  const SettingsVehicleInfoCard({
    super.key,
    required this.ble,
    required this.connected,
    required this.fwVersion,
    required this.isReadingSerial,
    required this.isRefreshingDiagnostics,
    required this.onReadSerial,
    required this.onRefreshDiagnostics,
  });

  @override
  Widget build(BuildContext context) {
    final telemetry = ble.lastTelemetry;
    final displaySerial = (ble.frameSerial != null && ble.frameSerial!.trim().isNotEmpty)
        ? ble.frameSerial!.trim()
        : (telemetry != null && telemetry.frame.trim().isNotEmpty ? telemetry.frame.trim() : null);

    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/bike_logo_3d.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ble.bikeName ?? 'BSKMT Biker EV',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Firmware: $fwVersion · ${connected ? "Conectado" : "Desconectado"}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: connected ? AppColors.tertiary : AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: connected ? 'ONLINE' : 'OFFLINE',
                color: connected ? AppColors.tertiary : AppColors.textDim,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.panelBorder, height: 1),
          const SizedBox(height: 12),

          Container(
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
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.numbers_rounded, size: 14, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SERIAL DE CHASIS (VIN / FRAME)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.textDim,
                        ),
                      ),
                    ),
                    if (displaySerial != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.tertiary.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'SINCRONIZADO',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.tertiary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          displaySerial ?? 'Sin leer del firmware',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: displaySerial != null ? 1.0 : 0.2,
                            color: displaySerial != null ? AppColors.textPrimary : AppColors.textDim,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (displaySerial != null)
                      IconButton(
                        tooltip: 'Copiar número serial',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textDim),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: displaySerial));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Serial copiado: $displaySerial'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.panel,
                            ),
                          );
                        },
                      ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: connected && !isReadingSerial ? onReadSerial : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: connected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: connected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.panelBorder,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isReadingSerial)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.primary),
                              )
                            else
                              Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: connected ? AppColors.primary : AppColors.textDim,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              isReadingSerial ? 'Leyendo...' : 'Releer',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: connected ? AppColors.primary : AppColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          SettingsVescSnapshotCard(
            ble: ble,
            connected: connected,
            isRefreshingDiagnostics: isRefreshingDiagnostics,
            onRefreshDiagnostics: onRefreshDiagnostics,
          ),
        ],
      ),
    );
  }
}
