import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';
import '../../battery/battery_diagnostics_screen.dart';
import 'charging_profile_pill.dart';

class ChargingDetailsCard extends StatelessWidget {
  final bool isCharging;
  final bool hasTelemetry;
  final bool connected;
  final String remainingTimeStr;
  final double powerKw;
  final double currentA;
  final double voltage;
  final double bmsTemp;
  final int chargingProfile;
  final void Function(int profile) onSelectProfile;

  const ChargingDetailsCard({
    super.key,
    required this.isCharging,
    required this.hasTelemetry,
    required this.connected,
    required this.remainingTimeStr,
    required this.powerKw,
    required this.currentA,
    required this.voltage,
    required this.bmsTemp,
    required this.chargingProfile,
    required this.onSelectProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.panelBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalles de la Carga',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Fila 1: Tiempo restante
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiempo restante',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDim,
                ),
              ),
              Text(
                remainingTimeStr,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const Divider(color: AppColors.panelBorder, height: 26, thickness: 1),

          // Fila 2: Potencia y Corriente
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Potencia / Corriente',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDim,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isCharging ? AppColors.tertiary.withValues(alpha: 0.15) : AppColors.panelSecondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'DC',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isCharging ? AppColors.tertiary : AppColors.textDim,
                      ),
                    ),
                  ),
                  Text(
                    hasTelemetry
                        ? '${powerKw.toStringAsFixed(2)} kW · ${currentA.toStringAsFixed(1)} A · ${voltage.toStringAsFixed(1)} V'
                        : '---',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Divider(color: AppColors.panelBorder, height: 26, thickness: 1),

          // Fila 3: Temperatura BMS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Temperatura BMS / Batería',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDim,
                ),
              ),
              Text(
                hasTelemetry ? '${bmsTemp.toStringAsFixed(1)} °C' : '---',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const Divider(color: AppColors.panelBorder, height: 26, thickness: 1),

          // Fila 4: Perfil de Carga Inteligente
          Text(
            'Perfil de Carga Inteligente',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ChargingProfilePill(
                label: 'Estándar',
                sub: 'Standard',
                selected: chargingProfile == 0,
                connected: connected,
                onTap: () => onSelectProfile(0),
              ),
              const SizedBox(width: 8),
              ChargingProfilePill(
                label: 'Rápida',
                sub: 'Fast',
                selected: chargingProfile == 1,
                connected: connected,
                onTap: () => onSelectProfile(1),
              ),
              const SizedBox(width: 8),
              ChargingProfilePill(
                label: 'Turbo Boost',
                sub: 'Boost',
                selected: chargingProfile == 2,
                connected: connected,
                onTap: () => onSelectProfile(2),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Fila 5: Botón Diagnóstico 24-Cell
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.medical_services_outlined, size: 20),
              label: Text(
                'Diagnóstico de Celdas (24-Cell)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BatteryDiagnosticsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
