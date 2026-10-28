import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';
import '../lab_catalog.dart';

class LabStatusCard extends StatelessWidget {
  final BleState ble;
  final bool connected;
  final Map<String, int> verdictCounts;
  final bool autoReadBack;
  final ValueChanged<bool> onToggleAutoReadBack;
  final VoidCallback onSniffAll;

  const LabStatusCard({
    super.key,
    required this.ble,
    required this.connected,
    required this.verdictCounts,
    required this.autoReadBack,
    required this.onToggleAutoReadBack,
    required this.onSniffAll,
  });

  @override
  Widget build(BuildContext context) {
    final tested = verdictCounts['pass']! + verdictCounts['fail']! + verdictCounts['skip']!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                size: 16,
                color: connected ? AppColors.tertiary : AppColors.amber,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  connected
                      ? 'Conectado a ${ble.bikeName ?? ''} · ${ble.isAuthorized ? "Autenticado ✓" : "NO autenticado"} · Clave de sesión ${ble.sessionKey != null ? "✓" : "✗"}'
                      : 'Vehículo no conectado — solo modo inspección/lectura.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Uso: abre una característica → revisa la PREDICCIÓN → envía payload → observa el vehículo + datos de retorno → califica ✅CORRECTO o ❌ERROR (con notas de campo). Resultados: $tested/${labCatalog.length} verificadas · ✅${verdictCounts['pass']} ❌${verdictCounts['fail']} ⏭${verdictCounts['skip']}',
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textDim),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.4)),
                  ),
                  onPressed: connected ? onSniffAll : null,
                  icon: const Icon(Icons.radar_rounded, size: 16),
                  label: Text('ESCANEAR CARACTERÍSTICAS', style: GoogleFonts.spaceGrotesk(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => onToggleAutoReadBack(!autoReadBack),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.textDim.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: Checkbox(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            value: autoReadBack,
                            onChanged: (v) => onToggleAutoReadBack(v ?? true),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text('Leer tras escribir', style: GoogleFonts.plusJakartaSans(fontSize: 10.5))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

