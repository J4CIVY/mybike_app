part of 'ble_controller.dart';

extension BleControllerConnect on BleController {
  Future<void> connect(BluetoothDevice device, {String? name}) async {
    if (state.phase == BlePhase.connected &&
        state.isAuthorized &&
        state.device?.remoteId == device.remoteId) {
      return;
    }
    _manualDisconnect = false;
    _writeCounter = 0;
    _cancelReconnect();
    state = BleState(phase: BlePhase.connecting, device: device, bikeName: name);
    unawaited(ForegroundService.start(
      title: 'Dat Bike',
      text: 'Conectando con ${name ?? device.platformName}...',
    ));
    await BleLogger.instance.startSession();
    BleLogger.instance.event('connect_start', {
      'device_id': device.remoteId.str,
      'name': name ?? device.platformName,
    });
    try {
      await _prefs;
    } catch (e, st) {
      BleLogger.instance.event('prefs_broken', {'error': '$e'});
      await BleLogger.logAppError('prefs_connect', e, st);
      state = state.copyWith(
        phase: BlePhase.disconnected,
        message: 'Error en almacenamiento local: $e\n→ Reinstala la aplicación.',
      );
      unawaited(ForegroundService.stop());
      throw Exception('Error en almacenamiento local: $e');
    }

    var recovered = false;
    for (var cycle = 1; cycle <= 5 && !recovered; cycle++) {
      if (cycle > 1) {
        state = state.copyWith(
          phase: BlePhase.reconnecting,
          message: 'Reintentando conexión ($cycle/5, cada 3s)...',
        );
        BleLogger.instance.event('auth_recovery_wait', {'cycle': cycle, 'delay_s': 3});
        _manualDisconnect = true;
        _recoveryDisconnect = true;
        try {
          await device.disconnect();
        } catch (_) {}
        await Future.delayed(const Duration(seconds: 3));
        _recoveryDisconnect = false;
        _manualDisconnect = false;
      }
      var ok = false;
      try {
        ok = await _establish(device);
      } catch (e) {
        BleLogger.instance.event('establish_err', {'cycle': cycle, 'error': '$e'});
        ok = false;
      }
      if (ok && state.isAuthorized) {
        await _saveLastBike(device, name);
        _watchConnection(device);
        state = state.copyWith(phase: BlePhase.connected, isAuthorized: true, message: null);
        unawaited(ForegroundService.start(
          title: 'Dat Bike: ${state.bikeName ?? device.platformName}',
          text: 'Bluetooth conectado — Listo para operar',
        ));
        _failStreak = 0;
        recovered = true;
      }
    }
    if (recovered) return;
    try {
      final ok = await _establish(device);
      if (ok && state.isAuthorized) {
        await _saveLastBike(device, name);
        _watchConnection(device);
        state = state.copyWith(phase: BlePhase.connected, isAuthorized: true, message: null);
        unawaited(ForegroundService.start(
          title: 'Dat Bike: ${state.bikeName ?? device.platformName}',
          text: 'Bluetooth conectado — Listo para operar',
        ));
        _failStreak = 0;
        return;
      } else {
        throw Exception(state.message ?? 'No fue posible autenticar la sesión tras 5 intentos');
      }
    } catch (e) {
      BleLogger.instance.event('connect_failed', {'error': '$e'});
      state = state.copyWith(
          phase: BlePhase.disconnected, message: 'Conexión fallida: $e');
      unawaited(ForegroundService.stop());
      rethrow;
    }
  }

  Future<bool> _establish(BluetoothDevice device) async {
    if (!BleLogger.instance.active) {
      await BleLogger.instance.startSession();
      BleLogger.instance.event('auto_session_start', {
        'device_id': device.remoteId.str,
        'name': device.platformName,
      });
    }
    if (_establishBusy) {
      BleLogger.instance.event('establish_skipped', {'reason': 'busy'});
      return state.isAuthorized;
    }
    _establishBusy = true;
    try {
      return await _establishInner(device);
    } finally {
      _establishBusy = false;
    }
  }

  Future<void> _connectWithCachePrime(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final alreadyConnected = FlutterBluePlus.connectedDevices
        .any((d) => d.remoteId == device.remoteId);
    if (alreadyConnected) {
      try {
        await device.connect(
          license: License.nonprofit,
          timeout: const Duration(seconds: 4),
          autoConnect: false,
        );
        return;
      } catch (_) {}
    }

    try {
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        await FlutterBluePlus.adapterState
            .where((s) => s == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 4));
      }
    } catch (_) {}

    try {
      if (!FlutterBluePlus.isScanningNow) {
        StreamSubscription? scanSub;
        final completer = Completer<void>();
        scanSub = FlutterBluePlus.scanResults.listen((results) {
          if (results.any((r) => r.device.remoteId == device.remoteId)) {
            if (!completer.isCompleted) completer.complete();
          }
        });
        await FlutterBluePlus.startScan(
          withRemoteIds: [device.remoteId.str],
          timeout: const Duration(seconds: 3),
          androidScanMode: AndroidScanMode.lowLatency,
        );
        await completer.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () {},
        );
        await scanSub.cancel();
      }
    } catch (_) {
    } finally {
      if (FlutterBluePlus.isScanningNow) {
        try {
          await FlutterBluePlus.stopScan();
        } catch (_) {}
      }
    }

    await device.connect(
      license: License.nonprofit,
      timeout: timeout,
      autoConnect: false,
    );
  }

  bool _isAuthError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('137') ||
        s.contains('insufficient') ||
        s.contains('gatt_auth') ||
        s.contains('auth_fail');
  }

  Future<bool> _ensureBonded(BluetoothDevice device, {String reason = ''}) async {
    BleLogger.instance.event('bond_start', {'reason': reason});
    try {
      final currentBond = await device.bondState.first.timeout(
        const Duration(milliseconds: 1200),
        onTimeout: () => BluetoothBondState.none,
      );
      if (currentBond == BluetoothBondState.bonded) {
        BleLogger.instance.event('bond_already_bonded', {});
        return true;
      }
      await device.createBond();
      BleLogger.instance.event('bond_created', {});
      return true;
    } catch (e) {
      BleLogger.instance.event('bond_failed', {'error': '$e'});
      return false;
    }
  }
}

