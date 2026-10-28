import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';

class DashboardSyncFooter extends StatelessWidget {
  final BleState ble;
  final DateTime? lastTelemetryTime;

  const DashboardSyncFooter({
    super.key,
    required this.ble,
    this.lastTelemetryTime,
  });

  @override
  Widget build(BuildContext context) {
    final telemetryTime = lastTelemetryTime == null
        ? 'Recibiendo telemetría…'
        : 'Telemetría: ${lastTelemetryTime!.toLocal().toString().substring(11, 19)}';
    final taploTime = ble.lastTimeSynced == null
        ? ''
        : ' · Reloj: ${ble.lastTimeSynced!.hour.toString().padLeft(2, '0')}:${ble.lastTimeSynced!.minute.toString().padLeft(2, '0')}:${ble.lastTimeSynced!.second.toString().padLeft(2, '0')}';
    final rssiStr = ble.filteredRssi != null ? ' · Señal BLE: ${ble.filteredRssi} dBm' : '';

    return Text(
      '$telemetryTime$taploTime$rssiStr',
      textAlign: TextAlign.center,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 11.5,
        color: AppColors.textDim,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

