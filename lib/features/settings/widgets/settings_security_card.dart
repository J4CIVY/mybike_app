import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class SettingsSecurityCard extends ConsumerWidget {
  final BleState ble;
  final bool connected;
  final void Function(String message) onShowResult;

  const SettingsSecurityCard({
    super.key,
    required this.ble,
    required this.connected,
    required this.onShowResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BLOQUEO DE SEGURIDAD (INMOVILIZADOR)', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      ble.isLocked
                          ? 'Bloqueada: Requiere TARJETA NFC para desbloquear · Alarma suena al mover la pata'
                          : 'La moto debe estar APAGADA para bloquearse. Sonará la alarma si se mueve la pata de apoyo o el chasis',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: ble.isLocked ? AppColors.error : AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: ble.isLocked,
                activeThumbColor: AppColors.error,
                onChanged: connected ? (v) async {
                  if (v) {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.bg,
                        title: Text('¿Bloquear moto con inmovilizador?', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
                        content: Text(
                          'Protocolo de bloqueo:\n• Si la moto está encendida → se apagará primero\n• La moto quedará inmovilizada — REQUIERE TARJETA NFC FÍSICA para volver a encender\n• La alarma sonará si se mueve la pata o el chasis\n\n¿Tiene su tarjeta NFC a la mano?',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('BLOQUEAR')),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    onShowResult(await ref.read(bleProvider.notifier).lockBike());
                  } else {
                    onShowResult(await ref.read(bleProvider.notifier).unlockBike());
                  }
                } : null,
              ),
            ],
          ),
          const Divider(color: AppColors.panelBorder, height: 24),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'PUERTO VESC PROGRAMMING (b0ca953d)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ble.vescProgActive ? AppColors.error : AppColors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(
                    label: ble.vescProgActive ? 'BLOQUEADO EN MODO DEV (0x01)' : 'NORMAL (0x00)',
                    color: ble.vescProgActive ? AppColors.error : AppColors.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'El interruptor de flasheo VESC interrumpe las tareas de sondeo si queda atascado en 0x01, impidiendo recibir telemetría.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDim),
              ),
              if (ble.vescProgActive) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: Text(
                      'RESTAURAR A MODO NORMAL (0x00)',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    onPressed: connected
                        ? () async {
                            try {
                              final res = await ref.read(bleProvider.notifier).recoverFromVescProgrammingMode();
                              onShowResult(res);
                            } catch (e) {
                              onShowResult('Error de restauración: $e');
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

