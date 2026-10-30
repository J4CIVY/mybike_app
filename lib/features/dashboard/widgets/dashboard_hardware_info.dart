import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/proto/bike_log.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class DashboardHardwareInfo extends StatelessWidget {
  final BikeLogMsg msg;

  const DashboardHardwareInfo({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(vertical: 4),
      borderRadius: 20,
      child: Column(
        children: [
          _infoRow('Corriente de fase', '${msg.phase.toStringAsFixed(1)} A'),
          _divider(),
          _infoRow(
            'Pata lateral',
            msg.parking ? 'Abajo (Estacionado)' : 'Arriba (Listo para rodar)',
            valueColor: msg.parking ? AppColors.amber : AppColors.tertiary,
          ),
          _divider(),
          _infoRow(
            'Direccionales & Luces',
            '${msg.left ? "← Izquierda  " : ""}${msg.right ? "Derecha →  " : ""}${!msg.left && !msg.right ? "Apagadas" : ""}',
          ),
          _divider(),
          _infoRow(
            'Número de chasis (VIN)',
            msg.frame.isEmpty ? '—' : msg.frame,
          ),
          _divider(),
          _infoRow(
            'Versión de Firmware',
            msg.version.isEmpty ? '1.14.0' : msg.version,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textDim,
              fontSize: 13.5,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: AppColors.panelBorder,
  );
}
