import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';
import 'settings_segment_option.dart';

class SettingsSpeedLimiterCard extends ConsumerWidget {
  final BleState ble;
  final void Function(String message) onShowResult;

  const SettingsSpeedLimiterCard({
    super.key,
    required this.ble,
    required this.onShowResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ble.phase == BlePhase.connected;
    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.tertiary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Límite seguro: El modo ECE habilita el límite de velocidad a 60 km/h en el controlador VESC para conducción urbana segura.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tertiary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            connected ? 'Opciones de velocidad (se aplican de inmediato en la moto):' : 'Conecte la moto para aplicar límites de velocidad:',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDim),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              StatusPill(
                label: 'ECE: ${ble.eceMode}',
                color: ble.eceMode == 1 ? AppColors.tertiary : AppColors.textDim,
              ),
              StatusPill(
                label: 'VELOCIDAD: ${ble.speedLimitMode}',
                color: ble.speedLimitMode == 1 ? AppColors.primary : AppColors.textDim,
              ),
              if (ble.fwSpeedLimitRaw != null)
                StatusPill(
                  label: 'RAW: ${ble.fwSpeedLimitRaw}',
                  color: AppColors.secondary,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SettingsSegmentOption(
                label: 'Sin límite',
                desc: 'Potencia Total',
                isSelected: ble.speedLimitMode == 0,
                onTap: () async {
                  if (ble.speedLimitMode == 0) return;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.panel,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '¿Desactivar Límite?',
                              style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        'Al desactivar el límite a Potencia Total, se recomienda apagar y encender la moto para reiniciar la memoria RAM del controlador VESC.\n\n'
                        'La app enviará la instrucción de desactivar el modo seguro de inmediato. Una vez desactivado, podrá cambiar libremente entre modos de manejo.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45, color: AppColors.textPrimary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('CANCELAR', style: GoogleFonts.spaceGrotesk(color: AppColors.textDim)),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('CONFIRMAR DESACTIVACIÓN', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  final res = await ref.read(bleProvider.notifier).setSafeSpeedLimit60(false);
                  onShowResult(res);
                },
              ),
              const SizedBox(width: 8),
              SettingsSegmentOption(
                label: 'Límite 60 km/h',
                desc: 'Modo Seguro Urbano',
                isSelected: ble.speedLimitMode == 1,
                onTap: () async {
                  if (ble.speedLimitMode == 1) return;
                  final res = await ref.read(bleProvider.notifier).setSafeSpeedLimit60(true);
                  onShowResult(res);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Al activar el límite a 60 km/h se bloquea el cambio involuntario de modos de manejo en marcha para mayor seguridad en la ciudad.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amber,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.panelBorder, height: 1),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MODO CIUDAD / CARGA PESADA (GRAB)',
                        style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'Curva de aceleración ultra suave para transporte de acompañante o carga sin tirones',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: ble.grabMode == 1 ? 'MODO CIUDAD: ACTIVO' : 'MODO CIUDAD: INACTIVO',
                color: ble.grabMode == 1 ? AppColors.tertiary : AppColors.textDim,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SettingsSegmentOption(
                label: 'Individual',
                desc: 'Respuesta deportiva',
                isSelected: ble.grabMode == 0,
                onTap: connected ? () async {
                  ref.read(bleProvider.notifier).setGrabMode(0);
                  onShowResult(await ref.read(bleProvider.notifier).setFwGrabMode(false));
                } : null,
              ),
              const SizedBox(width: 8),
              SettingsSegmentOption(
                label: 'Ciudad / Carga',
                desc: 'Aceleración suave',
                isSelected: ble.grabMode == 1,
                onTap: connected ? () async {
                  ref.read(bleProvider.notifier).setGrabMode(1);
                  onShowResult(await ref.read(bleProvider.notifier).setFwGrabMode(true));
                } : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

