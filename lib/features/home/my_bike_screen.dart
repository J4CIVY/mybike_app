import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';
import '../../core/services/bskmt_provider.dart';
import '../scan/scan_screen.dart';
import 'widgets/bike_header_bar.dart';
import 'widgets/bike_hero_card.dart';
import 'widgets/bike_lock_dialog.dart';
import 'widgets/bike_quick_actions.dart';
import 'widgets/bike_remote_controls_sheet.dart';
import 'widgets/bike_switcher_sheet.dart';
import 'widgets/bike_telemetry_card.dart';
import 'widgets/bike_trip_card.dart';

class MyBikeScreen extends ConsumerStatefulWidget {
  const MyBikeScreen({super.key});

  @override
  ConsumerState<MyBikeScreen> createState() => _MyBikeScreenState();
}

class _MyBikeScreenState extends ConsumerState<MyBikeScreen> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _onAppResume);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndRestore();
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _onAppResume() => _checkAndRestore();

  Future<void> _checkAndRestore() async {
    final ble = ref.read(bleProvider);
    if (ble.phase == BlePhase.connected ||
        ble.phase == BlePhase.connecting ||
        ble.phase == BlePhase.reconnecting ||
        ble.phase == BlePhase.disconnected) {
      return;
    }
    final last = await ref.read(bleProvider.notifier).lastBikeId();
    if (last != null && mounted) {
      await ref.read(bleProvider.notifier).tryRestoreLastBike();
    }
  }

  void _heroSnack(String msg, {String? actionLabel, VoidCallback? onAction, Duration? duration}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: duration ?? const Duration(milliseconds: 1800),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, textColor: const Color(0xFFF59E0B), onPressed: onAction)
            : null,
      ));
  }

  Future<void> _quickLockToggle() async {
    final ble = ref.read(bleProvider);
    final notifier = ref.read(bleProvider.notifier);
    if (ble.isLocked) {
      _heroSnack(await notifier.unlockBike());
      return;
    }
    final spd = ble.lastTelemetry?.speed ?? 0.0;
    if (spd > 0.5) {
      _heroSnack('⚠️ Advertencia: La moto está en movimiento (${spd.toStringAsFixed(0)} km/h), ¡no se puede bloquear!');
      return;
    }
    final ok = await BikeLockDialog.show(context);
    if (ok != true) return;
    _heroSnack(await notifier.lockBike());
  }

  Future<void> _quickPowerToggle() async {
    final ble = ref.read(bleProvider);
    final notifier = ref.read(bleProvider.notifier);
    final on = ble.lastTelemetry?.isBikeOn == true;
    final spd = ble.lastTelemetry?.speed ?? 0.0;
    if (on && spd > 0.5) {
      _heroSnack('⚠️ Advertencia: ¡No puedes apagar la moto mientras está en marcha (${spd.toStringAsFixed(1)} km/h)!');
      return;
    }
    try {
      if (on) {
        await notifier.turnOffBike();
        _heroSnack('Comando enviado: APAGAR sistema de la moto');
      } else {
        await notifier.turnOnBike();
        _heroSnack('Comando enviado: ENCENDER moto (Ready to Ride)');
      }
    } catch (e) {
      _heroSnack('$e');
    }
  }

  Future<void> _quickFindBike() async {
    final ble = ref.read(bleProvider);
    final notifier = ref.read(bleProvider.notifier);
    if (ble.isFindingBike) {
      final msg = await notifier.stopFindBike();
      if (mounted) _heroSnack(msg);
    } else {
      final msg = await notifier.findBike();
      if (mounted) {
        if (ref.read(bleProvider).isFindingBike) {
          _heroSnack(
            'Sonando alarma localizadora en parqueadero…',
            actionLabel: 'SILENCIAR',
            duration: const Duration(seconds: 8),
            onAction: () async {
              final stopMsg = await ref.read(bleProvider.notifier).stopFindBike();
              if (mounted) _heroSnack(stopMsg);
            },
          );
        } else {
          _heroSnack(msg);
        }
      }
    }
  }

  Future<void> _quickSyncTime() async {
    final msg = await ref.read(bleProvider.notifier).syncTimeWithBike();
    if (mounted) _heroSnack(msg);
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);
    final bskmt = ref.watch(bskmtProvider);
    final connected = ble.phase == BlePhase.connected;
    final telemetry = ble.lastTelemetry;
    final hasTelemetry = connected && telemetry != null;

    final bikeDisplayName = bskmt.activeMotorcycle?['plate'] ?? ble.bikeCustomName ?? ble.device?.platformName ?? 'Mi Moto Eléctrica';
    final percent = telemetry?.batteryPercent ?? 0;
    final kmLeft = telemetry?.rangeKm ?? 0;
    final percentDisplay = percent > 0 ? '$percent' : '--';
    final kmLeftDisplay = kmLeft > 0 ? '$kmLeft' : '--';

    final isLocked = ble.isLocked;
    final isBikeOn = telemetry?.isBikeOn == true;
    final speed = telemetry?.speed ?? 0.0;
    final statusText = !connected
        ? (ble.phase == BlePhase.connecting ? 'Conectando por Bluetooth…' : 'Desconectada · Toca para vincular')
        : (isLocked
            ? 'Seguro activo (Bloqueada)'
            : (speed > 0.5 ? 'En marcha (${speed.toStringAsFixed(0)} km/h)' : (isBikeOn ? 'Sistema encendido (Ready)' : 'Estacionada (Parking)')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BikeHeaderBar(
                bikeDisplayName: bikeDisplayName,
                connected: connected,
                documentAlerts: bskmt.documentAlerts,
                onTapSwitcher: () => BikeSwitcherSheet.show(context),
                onTapScan: connected ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen())),
                onTapDashboard: () => Navigator.of(context).pushNamed('/dashboard'),
                onTapLogs: () => Navigator.of(context).pushNamed('/logs'),
                onTapLab: () => Navigator.of(context).pushNamed('/lab'),
              ),
              const SizedBox(height: 14),
              BikeTelemetryCard(
                kmLeftDisplay: kmLeftDisplay,
                hasTelemetry: hasTelemetry,
                isSideStandDown: telemetry?.isSideStandDown ?? false,
                drivingModeShort: telemetry?.drivingModeShort ?? 'D',
                percent: percent,
                percentDisplay: percentDisplay,
                statusText: statusText,
              ),
              const SizedBox(height: 10),
              BikeHeroCard(
                isBikeOn: isBikeOn,
                isFindingBike: ble.isFindingBike,
                onQuickFindBike: _quickFindBike,
              ),
              const SizedBox(height: 16),
              BikeQuickActions(
                isLocked: isLocked,
                isBikeOn: isBikeOn,
                isFindingBike: ble.isFindingBike,
                onQuickLockToggle: _quickLockToggle,
                onQuickPowerToggle: _quickPowerToggle,
                onQuickFindBike: _quickFindBike,
                onQuickSyncTime: _quickSyncTime,
                onOpenRemoteControls: () => BikeRemoteControlsSheet.show(context: context, onHeroSnack: _heroSnack),
              ),
              const SizedBox(height: 16),
              BikeTripCard(trip: ble.trip),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
