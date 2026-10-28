import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

class OfflineMapClearDialog {
  static Future<bool?> show(
    BuildContext context, {
    required int tileCount,
    required String sizeText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¿Eliminar Mapas sin Conexión?',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Text(
          'Se eliminarán los $tileCount fragmentos de mapa ($sizeText) almacenados.',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCELAR', style: GoogleFonts.plusJakartaSans(color: AppColors.textDim, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ELIMINAR TODO', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

