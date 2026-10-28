import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';
import 'settings_segment_option.dart';

class SettingsUtilityCard extends ConsumerWidget {
  final BleState ble;
  final bool connected;
  final void Function(String message) onShowResult;

  const SettingsUtilityCard({
    super.key,
    required this.ble,
    required this.connected,
    required this.onShowResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distLabel = ble.distanceRawU16 != null ? '${ble.distanceRawU16}' : 'Estándar (8)';

    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Configuración de utilidades automáticas del ECU:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDim),
                ),
              ),
              if (connected)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Leer valores reales de la moto',
                  icon: const Icon(Icons.sync_rounded, size: 18, color: AppColors.textDim),
                  onPressed: () async {
                    await ref.read(bleProvider.notifier).refreshFwSettings();
                    onShowResult('Ajustes sincronizados desde la moto.');
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AUTO-APAGADO POR INACTIVIDAD', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('La moto se apaga sola tras permanecer estacionada prolongadamente',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDim)),
                  ],
                ),
              ),
              Switch(
                value: ble.idlingTurnOff,
                activeThumbColor: AppColors.primary,
                onChanged: connected ? (v) async {
                  ref.read(bleProvider.notifier).setIdlingTurnOff(v);
                  onShowResult(await ref.read(bleProvider.notifier).setFwIdlingTurnOff(v));
                } : null,
              ),
            ],
          ),
          const Divider(color: AppColors.panelBorder, height: 24),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PROXIMIDAD AUTOMÁTICA (ECU 5d681587)',
                        style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'El ECU se desbloquea al acercarse y se bloquea al alejarse · Umbral: $distLabel',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: ble.distanceMode > 0 ? 'ACTIVO (NVS: $distLabel)' : 'INACTIVO',
                color: ble.distanceMode > 0 ? AppColors.tertiary : AppColors.textDim,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SettingsSegmentOption(
                label: 'Desactivado',
                desc: 'Manual',
                isSelected: ble.distanceMode == 0,
                onTap: connected ? () async {
                  ref.read(bleProvider.notifier).setDistanceMode(0);
                  onShowResult(await ref.read(bleProvider.notifier).setFwDistanceMode(false));
                } : null,
              ),
              const SizedBox(width: 8),
              SettingsSegmentOption(
                label: 'Activado',
                desc: 'NVS $distLabel',
                isSelected: ble.distanceMode > 0,
                onTap: connected ? () async {
                  ref.read(bleProvider.notifier).setDistanceMode(1);
                  onShowResult(await ref.read(bleProvider.notifier).setFwDistanceMode(true));
                } : null,
              ),
            ],
          ),
          const Divider(color: AppColors.panelBorder, height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.drive_file_rename_outline_rounded, size: 18),
              label: Text(
                'RENOMBRAR MOTO (Memoria Flash)',
                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3),
              ),
              onPressed: connected ? () async {
                final current = await ref.read(bleProvider.notifier).readFwBikeName();
                if (!context.mounted) return;
                final ctrl = TextEditingController(
                    text: current ?? ref.read(bleProvider).bikeName ?? '');
                final name = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.panel,
                    title: Text('Renombrar vehículo', style: GoogleFonts.spaceGrotesk(fontSize: 16)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: ctrl,
                          maxLength: 20,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Ej: BSKMT Quantum',
                            counterStyle: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'El nombre se guardará en la memoria flash de la moto (máx. 20 caracteres). '
                          'Se verificará automáticamente tras el guardado.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textDim),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancelar')),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                );
                if (name != null && name.isNotEmpty) {
                  onShowResult(await ref.read(bleProvider.notifier).setFwBikeName(name));
                }
              } : null,
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.credit_card_rounded, size: 18),
              label: Text(
                'VINCULAR NUEVA TARJETA NFC',
                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3),
              ),
              onPressed: connected ? () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.panel,
                    title: Text('¿Vincular tarjeta NFC?', style: GoogleFonts.spaceGrotesk(fontSize: 16)),
                    content: Text(
                      'La app enviará la orden de registro a la moto → pase la NUEVA TARJETA por el lector del vehículo en los siguientes 10 segundos para autorizarla en el firmware.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.4),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Iniciar')),
                    ],
                  ),
                );
                if (ok == true) {
                  onShowResult(await ref.read(bleProvider.notifier).startAddNfcCard());
                }
              } : null,
            ),
          ),
        ],
      ),
    );
  }
}

