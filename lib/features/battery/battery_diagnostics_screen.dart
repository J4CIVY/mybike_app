import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';
import '../../core/services/battery_diagnostics_service.dart';
import '../../ui/app_theme.dart';
import '../../ui/widgets.dart';
import 'widgets/battery_health_overview_card.dart';
import 'widgets/cell_balance_card.dart';
import 'widgets/cell_voltages_chart.dart';
import 'widgets/obd_diagnostics_card.dart';
import 'widgets/thermal_radar_card.dart';

class BatteryDiagnosticsScreen extends ConsumerStatefulWidget {
  const BatteryDiagnosticsScreen({super.key});

  @override
  ConsumerState<BatteryDiagnosticsScreen> createState() => _BatteryDiagnosticsScreenState();
}

class _BatteryDiagnosticsScreenState extends ConsumerState<BatteryDiagnosticsScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(bleProvider).phase == BlePhase.connected) {
        ref.read(bleProvider.notifier).fetchBatteryDetails();
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await ref.read(bleProvider.notifier).fetchBatteryDetails();
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ ¡Diagnóstico de batería y OBD actualizado con éxito desde la moto!'),
          backgroundColor: AppColors.tertiary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);
    final connected = ble.phase == BlePhase.connected;
    final telemetry = ble.lastTelemetry;
    final battery = ble.lastBattery;

    final resolvedModel = (ble.bikeName != null && ble.bikeName!.isNotEmpty)
        ? ble.bikeName!
        : ((ble.frameSerial?.toUpperCase().contains('DBQ') == true)
            ? 'Quantum S'
            : (telemetry?.model.isNotEmpty == true ? telemetry!.model : 'Quantum S'));

    final report = BatteryDiagnosticsService.analyze(
      telemetry: telemetry,
      battery: battery,
      modelName: resolvedModel,
    );

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
          'Diagnóstico Batería & BMS',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Volver a escanear datos de la moto',
            onPressed: connected && !_isRefreshing ? _refreshData : null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (!connected) ...[
            const NoticeBanner(
              color: AppColors.amber,
              text: 'Moto desconectada de Bluetooth. Por favor conecte la moto para escanear parámetros BMS y OBD.',
            ),
            const SizedBox(height: 14),
          ] else if (report.isSimulated) ...[
            const NoticeBanner(
              color: AppColors.secondary,
              text: 'Bluetooth conectado. Esperando telemetría detallada de celdas desde el BMS.',
            ),
            const SizedBox(height: 14),
          ],

          BatteryHealthOverviewCard(report: report, socPercent: telemetry?.percent ?? 0),
          const SizedBox(height: 16),

          const SectionTitle('BALANCE DEL PACK DE BATERÍA (CELL BALANCE)'),
          const SizedBox(height: 10),
          CellBalanceCard(report: report),
          const SizedBox(height: 16),

          const SectionTitle('VOLTAJE DETALLADO POR CELDA'),
          const SizedBox(height: 10),
          CellVoltagesChart(report: report),
          const SizedBox(height: 16),

          const SectionTitle('MONITOREO TÉRMICO (RADAR 3 PUNTOS)'),
          const SizedBox(height: 10),
          ThermalRadarCard(report: report),
          const SizedBox(height: 16),

          const SectionTitle('DIAGNÓSTICO DEL SISTEMA OBD'),
          const SizedBox(height: 10),
          ObdDiagnosticsCard(report: report),
        ],
      ),
    );
  }
}
