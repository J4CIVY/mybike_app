import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';
import '../../core/proto/bike_log.dart';
import '../../core/services/trip_gps_tracker.dart';
import '../../core/services/bskmt_provider.dart';
import '../home/trip_route_screen.dart';
import '../../ui/app_theme.dart';
import 'widgets/dashboard_app_bar_actions.dart';
import 'widgets/dashboard_landscape_cockpit.dart';
import 'widgets/dashboard_portrait_cockpit.dart';
import 'widgets/dashboard_sync_footer.dart';
import 'widgets/dashboard_turn_off_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  BikeLogMsg? _msg;
  DateTime? _last;
  StreamSubscription? _sub;
  bool _powerBusy = false;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(bleProvider.notifier).telemetry.listen((t) {
      if (!mounted) return;
      setState(() {
        _msg = t.bike;
        _last = t.at;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _turnOnBike() async {
    setState(() => _powerBusy = true);
    try {
      await ref.read(bleProvider.notifier).turnOnBike();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚡ Comando enviado: ¡ENCENDER MOTO (Modo Ready)!'), backgroundColor: AppColors.tertiary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al encender moto: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _powerBusy = false);
    }
  }

  Future<void> _turnOffBike() async {
    final speed = _msg?.speed ?? ref.read(bleProvider).lastTelemetry?.speed ?? 0.0;
    if (speed > 0.5) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ADVERTENCIA: ¡No puedes apagar la moto mientras está en movimiento (${speed.toStringAsFixed(1)} km/h)!'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showTurnOffBikeDialog(context);
    if (confirm != true) return;

    setState(() => _powerBusy = true);
    try {
      await ref.read(bleProvider.notifier).turnOffBike();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔒 ¡Comando enviado: MOTO APAGADA!'), backgroundColor: AppColors.error));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al apagar moto: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _powerBusy = false);
    }
  }

  Future<void> _toggleFindBike(BleState ble) async {
    if (ble.isFindingBike) {
      final res = await ref.read(bleProvider.notifier).stopFindBike();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
    } else {
      final res = await ref.read(bleProvider.notifier).findBike();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res), backgroundColor: AppColors.amber, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _syncOdoWithBskmt(double odoKm) async {
    final success = await ref.read(bskmtProvider.notifier).syncOdometer(odoKm);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✅ Odómetro (${odoKm.toInt()} km) sincronizado con Garaje Virtual BSKMT' : '⚠️ No se pudo sincronizar odómetro con Garaje Virtual BSKMT'),
        backgroundColor: success ? AppColors.tertiary : AppColors.amber,
      ),
    );
  }

  void _openFullScreenMap(TripData trip) {
    final curTrip = TripRecord(
      startTime: trip.duration.inSeconds > 0 ? DateTime.now().subtract(trip.duration) : DateTime.now(),
      endTime: DateTime.now(),
      distanceKm: trip.distanceKm,
      durationSec: trip.duration.inSeconds,
      avgSpeedKmh: trip.avgSpeedKmh,
      maxSpeedKmh: trip.maxSpeedKmh,
      usedPercent: trip.usedPercent,
      route: TripGpsTracker.instance.getCurrentRoute(),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TripRouteScreen(trip: curTrip, tripIndex: 0, allTrips: ref.read(bleProvider).tripHistory)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);
    final m = _msg ??
        (ble.lastTelemetry ??
            (BikeLogMsg()
              ..model = (ble.bikeName ?? 'Dat Bike Quantum')
              ..version = '1.14.0'
              ..state = BikeState.standBy));

    final trip = ble.trip;
    final isEncrypted = ble.dashboardEncrypted;
    final powerKw = (m.voltage > 0) ? ((m.voltage * m.phase) / 1000.0) : 0.0;
    final isDraw = powerKw < -0.05;
    final isRecup = powerKw > 0.05;

    final active = ref.watch(bskmtProvider).activeMotorcycle;
    final title = active != null
        ? '${active['brand'] ?? 'BSKMT'} ${active['model'] ?? ''} (${active['plate'] ?? ''})'.toUpperCase()
        : (ble.bikeName ?? 'BSKMT COCKPIT').toUpperCase();

    final syncFooter = DashboardSyncFooter(ble: ble, lastTelemetryTime: _last);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Color(0x180F172A), blurRadius: 4, offset: Offset(0, 1))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/bike_logo_3d.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.5, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          DashboardAppBarActions(
            onSyncOdo: () => _syncOdoWithBskmt((_msg?.odo ?? ble.lastTelemetry?.odo ?? 0.0)),
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return DashboardLandscapeCockpit(
              ble: ble,
              msg: m,
              trip: trip,
              powerKw: powerKw,
              isRecup: isRecup,
              isDraw: isDraw,
              isEncrypted: isEncrypted,
              activeTab: _activeTab,
              onTabChanged: (i) => setState(() => _activeTab = i),
              powerBusy: _powerBusy,
              onTurnOn: _turnOnBike,
              onTurnOff: _turnOffBike,
              onToggleFindBike: () => _toggleFindBike(ble),
              onExpandFullScreen: () => _openFullScreenMap(trip),
              onOpenBatteryDiagnostics: () => Navigator.of(context).pushNamed('/battery'),
              onTryRestoreLastBike: () => ref.read(bleProvider.notifier).tryRestoreLastBike(),
              syncFooter: syncFooter,
            );
          }
          return DashboardPortraitCockpit(
            ble: ble,
            msg: m,
            trip: trip,
            powerKw: powerKw,
            isRecup: isRecup,
            isDraw: isDraw,
            isEncrypted: isEncrypted,
            activeTab: _activeTab,
            onTabChanged: (i) => setState(() => _activeTab = i),
            powerBusy: _powerBusy,
            onTurnOn: _turnOnBike,
            onTurnOff: _turnOffBike,
            onToggleFindBike: () => _toggleFindBike(ble),
            onExpandFullScreen: () => _openFullScreenMap(trip),
            onOpenBatteryDiagnostics: () => Navigator.of(context).pushNamed('/battery'),
            onTryRestoreLastBike: () => ref.read(bleProvider.notifier).tryRestoreLastBike(),
            syncFooter: syncFooter,
          );
        },
      ),
    );
  }
}
