import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';
import '../battery/battery_diagnostics_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../firmware_lab/firmware_lab_screen.dart';
import '../logs/logs_screen.dart';
import '../ota/ota_screen.dart';
import '../settings/vehicle_settings_screen.dart';

class ProfileMenuSection extends StatelessWidget {
  final bool isAuthenticated;
  final VoidCallback onLogout;

  const ProfileMenuSection({
    super.key,
    required this.isAuthenticated,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          _menuItem(
            context,
            icon: const Icon(Icons.speed_rounded, size: 22, color: AppColors.primary),
            title: 'Cockpit HUD & Navegación GPS',
            subtitle: 'Tablero digital en tiempo real con acelerómetro y mapa',
            destination: const DashboardScreen(),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 56, endIndent: 20),
          _menuItem(
            context,
            icon: const Icon(Icons.tune_rounded, size: 22, color: Color(0xFF0F172A)),
            title: 'Ajustes de Conducción & Frenado',
            subtitle: 'Freno regenerativo, límite de velocidad y modo seguro',
            destination: const VehicleSettingsScreen(),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 56, endIndent: 20),
          _menuItem(
            context,
            icon: const Icon(Icons.medical_services_outlined, size: 22, color: Color(0xFF10B981)),
            title: 'Diagnóstico de Batería & OBD',
            subtitle: 'Salud de celdas BMS, temperaturas y códigos VESC',
            destination: const BatteryDiagnosticsScreen(),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 56, endIndent: 20),
          _menuItem(
            context,
            icon: const Icon(Icons.system_update_rounded, size: 22, color: Color(0xFF2563EB)),
            title: 'Actualización de Firmware (OTA)',
            subtitle: 'Descarga y sincronización de versiones oficiales',
            destination: const OtaScreen(),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 56, endIndent: 20),
          _menuItem(
            context,
            icon: const Icon(Icons.receipt_long_rounded, size: 22, color: Color(0xFF6366F1)),
            title: 'Registro de Telemetría (Logs)',
            subtitle: 'Exportación de telemetría de rodadas y sesiones',
            destination: const LogsScreen(),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 56, endIndent: 20),
          _menuItem(
            context,
            icon: const Icon(Icons.science_rounded, size: 22, color: Color(0xFF8B5CF6)),
            title: 'Laboratorio de Pruebas BLE',
            subtitle: 'Inspección de características GATT y diagnóstico',
            destination: const FirmwareLabScreen(),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 56, endIndent: 20),
          _aboutItem(context),
          if (isAuthenticated) ...[
            const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 56, endIndent: 20),
            _logoutItem(),
          ],
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required Widget icon,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination)),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            SizedBox(width: 26, height: 26, child: Center(child: icon)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textDim)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _aboutItem(BuildContext context) {
    return InkWell(
      onTap: () {
        showAboutDialog(
          context: context,
          applicationName: 'BSKMT Cockpit',
          applicationVersion: 'v2.6.6 (Ecosistema BSKMT)',
          applicationIcon: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 28),
          ),
          children: [
            Text(
              'Aplicación móvil oficial de telemetría, navegación Cockpit HUD y control para miembros de BSK Motorcycle Team.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
          ],
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: Center(child: Icon(Icons.info_outline_rounded, size: 22, color: Color(0xFF0F172A))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Acerca de BSKMT', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('BSK Motorcycle Team • Versión 2.6.6', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textDim)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _logoutItem() {
    return InkWell(
      onTap: onLogout,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: Center(child: Icon(Icons.logout_rounded, size: 22, color: AppColors.error)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cerrar Sesión BSKMT', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Desvincular cuenta del dispositivo', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textDim)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

