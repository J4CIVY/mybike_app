// Scan — Búsqueda BLE de vehículos BSKMT.
// Soporta nombres publicitados BSKMT, Quantum y Dat Bike.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';
import '../../core/ble/ble_logger.dart';
import '../../core/ble/ble_permissions.dart';
import '../../ui/app_theme.dart';
import '../../ui/widgets.dart';
import 'widgets/scan_bike_tile.dart';
import 'widgets/scan_empty_state.dart';
import 'widgets/scan_other_device_tile.dart';
import 'widgets/scan_permission_dialog.dart';
import 'widgets/scan_reconnect_card.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _results = <ScanResult>[];
  StreamSubscription? _sub;
  bool _scanning = false;
  String? _error;
  bool _showAll = false;
  String? _lastBikeId;
  String? _lastBikeName;
  bool _directConnecting = false;

  @override
  void initState() {
    super.initState();
    ref.read(bleProvider.notifier).lastBikeId().then((id) async {
      if (!mounted) return;
      final name = await ref.read(bleProvider.notifier).lastBikeName();
      setState(() {
        _lastBikeId = id;
        _lastBikeName = name;
      });
    });
    _scan();
  }

  bool _isBike(ScanResult r) {
    final name = '${r.advertisementData.advName} ${r.device.platformName}'
        .toLowerCase()
        .replaceAll('.', ' ');
    return name.contains('bskmt') ||
        name.contains('bike') ||
        name.contains('moto') ||
        name.contains('quantum') ||
        name.contains('dat bik') ||
        name.contains('datbike');
  }

  Future<void> _scan() async {
    setState(() {
      _error = null;
      _scanning = true;
    });

    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _scanning = false);
      return;
    }

    final ok = await BlePermissions.ensure();
    if (!ok) {
      setState(() {
        _scanning = false;
        _error = 'Permisos de Bluetooth y Ubicación requeridos para escanear.';
      });
      if (await BlePermissions.permanentlyDenied() && mounted) {
        ScanPermissionDialog.show(context);
      }
      return;
    }

    final adapter = await FlutterBluePlus.adapterState.first;
    if (adapter != BluetoothAdapterState.on) {
      setState(() {
        _scanning = false;
        _error = 'Bluetooth apagado — por favor encienda el Bluetooth y reintente.';
      });
      return;
    }

    if (!BleLogger.instance.active) await BleLogger.instance.startSession();

    _results.clear();
    _sub?.cancel();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));
    _sub = FlutterBluePlus.scanResults.listen((rs) {
      BleLogger.instance.event('scan_batch', {
        'count': rs.length,
        'devices': [
          for (final r in rs)
            {
              'id': r.device.remoteId.str,
              'adv_name': r.advertisementData.advName,
              'platform_name': r.device.platformName,
              'rssi': r.rssi,
            }
        ],
      });
      if (!mounted) return;
      setState(() {
        _results
          ..clear()
          ..addAll(rs);
      });
    });

    try {
      await FlutterBluePlus.isScanning.where((s) => !s).first;
    } catch (_) {}
    if (mounted) setState(() => _scanning = false);
  }

  void _connect(ScanResult r) {
    FlutterBluePlus.stopScan();
    final name = r.advertisementData.advName.isNotEmpty
        ? r.advertisementData.advName
        : r.device.platformName;
    Navigator.of(context).pushReplacementNamed('/connecting', arguments: {
      'device': r.device,
      'name': name.isEmpty ? 'Moto BSKMT' : name,
    });
  }

  Future<void> _connectDirect() async {
    if (_lastBikeId == null) return;
    setState(() => _directConnecting = true);
    final dev = BluetoothDevice.fromId(_lastBikeId!);
    Navigator.of(context).pushReplacementNamed('/connecting', arguments: {
      'device': dev,
      'name': _lastBikeName ?? 'Moto BSKMT',
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bikes = _results.where(_isBike).toList();
    final others = _results.where((r) => !_isBike(r)).toList();
    others.sort((a, b) => b.rssi.compareTo(a.rssi));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'VINCULAR MOTO BLUETOOTH',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _scan,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            if (_lastBikeId != null) ...[
              ScanReconnectCard(
                bikeName: _lastBikeName,
                connecting: _directConnecting,
                onTap: _connectDirect,
              ),
              const SizedBox(height: 16),
            ],
            if (_error != null) ...[
              NoticeBanner(color: AppColors.error, text: _error!),
              const SizedBox(height: 14),
            ],
            if (bikes.isNotEmpty) ...[
              const SectionTitle('MOTOS DETECTADAS'),
              const SizedBox(height: 10),
              for (final r in bikes)
                ScanBikeTile(
                  result: r,
                  onTap: () => _connect(r),
                ),
            ],
            if (bikes.isEmpty && !_scanning && !kIsWeb) ...[
              ScanEmptyState(onRetry: _scan),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const SectionTitle('OTROS DISPOSITIVOS'),
                const Spacer(),
                Text(
                  '${others.length} dispositivos',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDim),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _showAll,
                  onChanged: (v) => setState(() => _showAll = v),
                ),
              ],
            ),
            if (_showAll)
              for (final r in others)
                ScanOtherDeviceTile(
                  result: r,
                  onTap: () => _connect(r),
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const StadiumBorder(),
        onPressed: _scanning ? null : _scan,
        icon: _scanning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : const Icon(Icons.radar),
        label: Text(_scanning ? 'Buscando…' : 'Buscar moto', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
