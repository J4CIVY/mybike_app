import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';
import '../lab_catalog.dart';

class LabRiskDialog {
  static Future<bool> confirm(BuildContext context, LabCharTest t, String op) async {
    if (t.risk == LabRisk.safe || op == 'read') return true;
    final danger = t.risk == LabRisk.danger;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text(
          danger ? '⚠️ OPERACIÓN DE ALTO RIESGO' : 'Precaución',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            color: danger ? Colors.redAccent : AppColors.amber,
          ),
        ),
        content: Text(
          '${t.name}\n\nCaracterística ${t.shortId} · $op\n\n'
          '${danger ? 'Esta acción puede apagar el vehículo o alterar configuraciones críticas. Continúa únicamente preparado junto a la moto.' : 'La operación modifica ajustes del vehículo con la moto detenida.'}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: danger ? Colors.redAccent : AppColors.amber),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONTINUAR DE TODOS MODOS'),
          ),
        ],
      ),
    );
    return ok == true;
  }
}

