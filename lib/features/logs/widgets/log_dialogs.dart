import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../ui/app_theme.dart';

class LogDialogs {
  LogDialogs._();

  static void showStorageSettingsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Permiso de almacenamiento', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
        content: Text(
          'El permiso fue denegado permanentemente. Abra Ajustes → Aplicaciones → Permisos para habilitarlo.',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('CANCELAR', style: GoogleFonts.plusJakartaSans(color: AppColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              openAppSettings();
              Navigator.pop(c);
            },
            child: Text('ABRIR AJUSTES', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showDeleteAllDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('¿Eliminar todos los registros?', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
        content: Text(
          'Se eliminarán todas las sesiones de log BLE almacenadas en el dispositivo.',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('CANCELAR', style: GoogleFonts.plusJakartaSans(color: AppColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.pop(c, true),
            child: Text('ELIMINAR TODO', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

