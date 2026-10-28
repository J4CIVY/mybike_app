import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../ui/app_theme.dart';

class ScanPermissionDialog extends StatelessWidget {
  const ScanPermissionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (c) => const ScanPermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Permisos de Bluetooth & Ubicación',
        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 18),
      ),
      content: Text(
        'Permiso denegado permanentemente. Abra Ajustes del sistema → Aplicaciones → Permisos para habilitarlo.',
        style: GoogleFonts.plusJakartaSans(color: AppColors.textDim, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
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
            Navigator.pop(context);
          },
          child: Text('ABRIR AJUSTES', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

