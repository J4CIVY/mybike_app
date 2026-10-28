import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';
import '../../ui/app_theme.dart';
import '../../ui/widgets.dart';
import '../firmware_lab/firmware_lab_screen.dart';
import '../logs/logs_screen.dart';
import 'widgets/settings_advanced_card.dart';
import 'widgets/settings_security_card.dart';
import 'widgets/settings_sound_pattern_card.dart';
import 'widgets/settings_speed_limiter_card.dart';
import 'widgets/settings_time_sync_card.dart';
import 'widgets/settings_utility_card.dart';
import 'widgets/settings_vehicle_info_card.dart';

class VehicleSettingsScreen extends ConsumerStatefulWidget {
  const VehicleSettingsScreen({super.key});

  @override
  ConsumerState<VehicleSettingsScreen> createState() => _VehicleSettingsScreenState();
}

class _VehicleSettingsScreenState extends ConsumerState<VehicleSettingsScreen> {
  bool _isReadingSerial = false;
  bool _isSyncingTime = false;
  bool _isRefreshingDiagnostics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ble = ref.read(bleProvider);
      if (ble.phase == BlePhase.connected) {
        unawaited(ref.read(bleProvider.notifier).refreshFwSettings());
      }
    });
  }

  Future<void> _readSerial() async {
    setState(() => _isReadingSerial = true);
    final serial = await ref.read(bleProvider.notifier).readDeviceSerial();
    if (mounted) {
      setState(() => _isReadingSerial = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(serial != null ? '✅ Serial VIN del vehículo: $serial' : 'No se pudo leer el serial en este momento.'),
          backgroundColor: serial != null ? AppColors.tertiary : AppColors.amber,
        ),
      );
    }
  }

  Future<void> _refreshDiagnostics() async {
    setState(() => _isRefreshingDiagnostics = true);
    await ref.read(bleProvider.notifier).fetchVehicleDiagnostics();
    if (mounted) {
      setState(() => _isRefreshingDiagnostics = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Información de hardware y snapshot VESC actualizada'),
          backgroundColor: AppColors.tertiary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _syncTime() async {
    setState(() => _isSyncingTime = true);
    final res = await ref.read(bleProvider.notifier).syncTimeWithBike();
    if (mounted) {
      setState(() => _isSyncingTime = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res),
          backgroundColor: res.toLowerCase().contains('éxito') || res.toLowerCase().contains('exitoso')
              ? AppColors.tertiary
              : AppColors.amber,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showResult(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 12.5)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);
    final connected = ble.phase == BlePhase.connected;
    final telemetry = ble.lastTelemetry;

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
          'Configuración de la Moto',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Registro Bluetooth',
            icon: const Icon(Icons.receipt_long_rounded, size: 22, color: Color(0xFF6366F1)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogsScreen())),
          ),
          IconButton(
            tooltip: 'Laboratorio de Firmware',
            icon: const Icon(Icons.science_rounded, size: 22, color: Color(0xFF8B5CF6)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FirmwareLabScreen())),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          SettingsVehicleInfoCard(
            ble: ble,
            connected: connected,
            fwVersion: telemetry?.version ?? '1.14.0',
            isReadingSerial: _isReadingSerial,
            isRefreshingDiagnostics: _isRefreshingDiagnostics,
            onReadSerial: _readSerial,
            onRefreshDiagnostics: _refreshDiagnostics,
          ),
          const SizedBox(height: 16),

          const SectionTitle('RELOJ DEL PANEL DIGITAL'),
          const SizedBox(height: 10),
          SettingsTimeSyncCard(
            ble: ble,
            connected: connected,
            isSyncingTime: _isSyncingTime,
            onSyncTime: _syncTime,
          ),
          const SizedBox(height: 16),

          const SectionTitle('SEGURIDAD Y CONTROL DE MANEJO'),
          const SizedBox(height: 10),
          SettingsSpeedLimiterCard(
            ble: ble,
            onShowResult: _showResult,
          ),
          const SizedBox(height: 12),
          SettingsSecurityCard(
            ble: ble,
            connected: connected,
            onShowResult: _showResult,
          ),
          const SizedBox(height: 16),

          const SectionTitle('UTILIDADES Y AUTOMATIZACIÓN'),
          const SizedBox(height: 10),
          SettingsUtilityCard(
            ble: ble,
            connected: connected,
            onShowResult: _showResult,
          ),
          const SizedBox(height: 16),

          const SectionTitle('LOCALIZADOR SONORO (PITO)'),
          const SizedBox(height: 10),
          SettingsSoundPatternCard(
            ble: ble,
            connected: connected,
          ),
          const SizedBox(height: 16),

          SettingsAdvancedCard(
            ble: ble,
            connected: connected,
            onShowResult: _showResult,
          ),
        ],
      ),
    );
  }
}
