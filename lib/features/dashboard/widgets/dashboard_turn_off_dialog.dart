import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

Future<bool?> showTurnOffBikeDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 26),
          const SizedBox(width: 10),
          Text(
            'Confirmar apagado',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Text(
        '¿Estás seguro de que deseas APAGAR el sistema de la moto?\nEl motor se desconectará y el vehículo entrará en modo seguro.',
        style: GoogleFonts.plusJakartaSans(color: AppColors.textDim, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('CANCELAR', style: GoogleFonts.plusJakartaSans(color: AppColors.textDim, fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('APAGAR MOTO', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

