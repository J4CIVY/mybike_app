import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class SettingsAdvancedCard extends ConsumerWidget {
  final BleState ble;
  final bool connected;
  final void Function(String message) onShowResult;

  const SettingsAdvancedCard({
    super.key,
    required this.ble,
    required this.connected,
    required this.onShowResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textDim.withValues(alpha: 0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            iconColor: AppColors.textDim,
            title: Text(
              'AVANZADO (COMANDOS CRÍTICOS)',
              style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDim),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                'Apagado profundo de BMS · Restablecimiento de fábrica BLE',
                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textDim),
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estas operaciones afectan directamente la alimentación de la batería y la conectividad. Ejecute solo si es necesario.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDim, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              Panel(
                padding: const EdgeInsets.all(18),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comandos de alto impacto — use únicamente si comprende las consecuencias:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDim),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.amber,
                          side: BorderSide(color: AppColors.amber.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.battery_alert_rounded, size: 18),
                        label: Text(
                          'APAGADO PROFUNDO BMS (LARGA ESTANCIA)',
                          style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                        ),
                        onPressed: connected ? () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.panel,
                              title: Text('¿Apagar BMS por completo?', style: GoogleFonts.spaceGrotesk(fontSize: 16)),
                              content: Text(
                                'La batería se desconectará totalmente — la moto NO responderá por Bluetooth hasta que se encienda físicamente con la llave/botón. Úselo solo al guardar la moto por meses.',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.4),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Apagar BMS'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            onShowResult(await ref.read(bleProvider.notifier).turnOffBms());
                          }
                        } : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: Text(
                          'RESTABLECIMIENTO DE FÁBRICA BLE',
                          style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                        ),
                        onPressed: connected ? () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.panel,
                              title: Text('¿Restablecer configuración BLE?', style: GoogleFonts.spaceGrotesk(fontSize: 16)),
                              content: Text(
                                'Borra los emparejamientos y claves Bluetooth guardados en la moto. Deberá vincular de nuevo. Esta acción no se puede deshacer.',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.4),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Restablecer'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            onShowResult(await ref.read(bleProvider.notifier).factoryResetBle());
                          }
                        } : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

