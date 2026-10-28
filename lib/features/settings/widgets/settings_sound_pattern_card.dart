import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class SettingsSoundPatternCard extends ConsumerWidget {
  final BleState ble;
  final bool connected;

  const SettingsSoundPatternCard({
    super.key,
    required this.ble,
    required this.connected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Especificación BLE: Con la moto apagada, escribir Plain \'1\' en 0x350D9A82 activa un toque de pito para despertar el MCU sin cerrar el relé de potencia.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Elija el patrón de sonido al presionar "Localizar moto" en el parqueadero:',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDim),
          ),
          const SizedBox(height: 14),

          _buildPatternRadioTile(
            patternId: 0,
            title: 'Patrón Estándar (Single Beep)',
            subtitle: 'Bip simple cada 1.1s — claro y de buen alcance',
            isSelected: ble.findBikePattern == 0,
            onTap: () => ref.read(bleProvider.notifier).setFindBikePattern(0),
          ),
          const SizedBox(height: 8),
          _buildPatternRadioTile(
            patternId: 1,
            title: 'Patrón Doble Deportivo (Double Staccato)',
            subtitle: 'Doble bip (bip-bip... bip-bip) — ideal para parqueaderos concurridos',
            isSelected: ble.findBikePattern == 1,
            onTap: () => ref.read(bleProvider.notifier).setFindBikePattern(1),
          ),
          const SizedBox(height: 8),
          _buildPatternRadioTile(
            patternId: 2,
            title: 'Alarma de Emergencia (Urgent SOS)',
            subtitle: 'Pitidos rápidos cada 450ms — localización inmediata',
            isSelected: ble.findBikePattern == 2,
            onTap: () => ref.read(bleProvider.notifier).setFindBikePattern(2),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ble.isFindingBike ? AppColors.amber : AppColors.secondary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(
                ble.isFindingBike ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                size: 20,
              ),
              label: Text(
                ble.isFindingBike ? 'DETENER PITO' : 'PROBAR TONO (3 SEGUNDOS)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              onPressed: connected
                  ? () async {
                      if (ble.isFindingBike) {
                        await ref.read(bleProvider.notifier).stopFindBike();
                      } else {
                        await ref.read(bleProvider.notifier).findBike(timeout: const Duration(seconds: 3));
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternRadioTile({
    required int patternId,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.panelSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.panelBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textDim,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textDim),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

