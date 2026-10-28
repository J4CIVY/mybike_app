import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';
import '../../ui/app_theme.dart';
import 'widgets/charging_details_card.dart';
import 'widgets/charging_visual_card.dart';

class ChargingScreen extends ConsumerStatefulWidget {
  const ChargingScreen({super.key});

  @override
  ConsumerState<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends ConsumerState<ChargingScreen> {
  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);
    final connected = ble.phase == BlePhase.connected;
    final telemetry = ble.lastTelemetry;
    final hasTelemetry = connected && telemetry != null;

    final isCharging = hasTelemetry && (telemetry.charging != null || telemetry.phase > 0.5);
    final percent = telemetry?.percent;
    final percentStr = (hasTelemetry && percent != null) ? '$percent' : '--';
    final voltage = telemetry?.voltage ?? 0.0;
    final currentA = (telemetry?.phase ?? 0.0).abs();
    final powerKw = (voltage * currentA / 1000.0);
    final kmLeftVal = (telemetry != null && telemetry.kmLeft > 0)
        ? telemetry.kmLeft.round()
        : (percent != null ? ((percent / 100.0) * 270).round() : null);
    final kmLeftStr = (hasTelemetry && kmLeftVal != null) ? '$kmLeftVal' : '--';

    final etaSec = telemetry?.charging?.etaSec ?? 0;
    final remainingTimeStr = isCharging
        ? (etaSec > 0 ? '${(etaSec / 60).round()} min' : 'Cargando...')
        : '---';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'Control de Carga & Energía',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    kmLeftStr,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 54,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      color: AppColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'km restantes',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ChargingVisualCard(
                isCharging: isCharging,
                percentStr: percentStr,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statusBullet(
                    color: isCharging ? AppColors.tertiary : AppColors.textDim,
                    label: isCharging
                        ? 'Carga activa y segura'
                        : (connected ? 'Cargador no conectado' : 'Moto desconectada'),
                  ),
                  const SizedBox(width: 18),
                  _statusBullet(
                    color: AppColors.primary,
                    label: isCharging ? 'Carga Rápida BSKMT' : 'Protocolo 72V Li-ion',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ChargingDetailsCard(
                isCharging: isCharging,
                hasTelemetry: hasTelemetry,
                connected: connected,
                remainingTimeStr: remainingTimeStr,
                powerKw: powerKw,
                currentA: currentA,
                voltage: voltage,
                bmsTemp: telemetry?.bmsTemp ?? 28.0,
                chargingProfile: ble.chargingProfile,
                onSelectProfile: (profile) async {
                  ref.read(bleProvider.notifier).setChargingProfile(profile);
                  final res = await ref.read(bleProvider.notifier).setFwChargingProfile(profile);
                  _showSnack(res);
                },
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBullet({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
