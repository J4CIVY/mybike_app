part of 'ble_controller.dart';

extension BleControllerReconnect on BleController {
  Future<bool> tryRestoreLastBike() async {
    if (_restoreBusy) return state.phase == BlePhase.connected;
    if (state.phase == BlePhase.connected || state.phase == BlePhase.connecting) return true;
    _restoreBusy = true;
    try {
      final SharedPreferences prefs;
      try {
        prefs = await _prefs;
      } catch (e, st) {
        await BleLogger.logAppError('prefs_restore', e, st);
        state = state.copyWith(
          phase: BlePhase.disconnected,
          message: 'Error en almacenamiento local: $e',
        );
        return false;
      }
      final id = prefs.getString(BleController._kLastBikeId);
      if (id == null || id.isEmpty) {
        return false;
      }
      if (state.phase == BlePhase.connected || state.phase == BlePhase.connecting) return true;

      await BlePermissions.ensure();

      try {
        if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
          state = state.copyWith(
            phase: BlePhase.connecting,
            message: 'Esperando activación de Bluetooth…',
          );
          await FlutterBluePlus.adapterState
              .where((s) => s == BluetoothAdapterState.on)
              .first
              .timeout(const Duration(seconds: 4));
        }
      } catch (_) {}

      final name = prefs.getString(BleController._kLastBikeName) ?? 'Moto Dat Bike';
      BluetoothDevice device = BluetoothDevice.fromId(id);
      final connectedMatch = FlutterBluePlus.connectedDevices
          .where((d) => d.remoteId.str == id)
          .firstOrNull;
      if (connectedMatch != null) {
        device = connectedMatch;
      }

      _reconnectAttempts = 0;
      state = state.copyWith(
        phase: BlePhase.connecting,
        device: device,
        bikeName: name,
        message: 'Conectando con la moto $name…',
      );
      try {
        final ok = await _establish(device);
        if (ok && state.isAuthorized) {
          await _saveLastBike(device, name);
          _watchConnection(device);
          state = state.copyWith(phase: BlePhase.connected, reconnectAttempt: 0, message: null);
          unawaited(ForegroundService.start(
            title: 'Dat Bike: $name',
            text: 'Bluetooth conectado — Listo para operar',
          ));
          return true;
        }
      } catch (e) {
        BleLogger.instance.event('restore_attempt_failed', {'error': '$e'});
      }

      _scheduleReconnect(device);
      return false;
    } finally {
      _restoreBusy = false;
    }
  }

  void _scheduleReconnect(BluetoothDevice device) {
    if (_manualDisconnect) return;
    if (_reconnectPending) {
      BleLogger.instance.event('reconnect_debounced', {});
      return;
    }
    _reconnectAttempts++;
    if (_reconnectAttempts > BleController._maxReconnect) {
      _reconnectPending = false;
      _cancelReconnect();
      unawaited(ForegroundService.stop());
      state = state.copyWith(
        phase: BlePhase.disconnected,
        reconnectAttempt: _reconnectAttempts,
        message: 'Búsqueda detenida tras ${BleController._maxReconnect} intentos. Acércate y reconecta.',
      );
      BleLogger.instance.event('reconnect_limit_reached', {'max': BleController._maxReconnect});
      return;
    }

    final delay = (_reconnectAttempts <= BleController._backoff.length)
        ? BleController._backoff[_reconnectAttempts - 1]
        : 30;
    _reconnectPending = true;
    state = state.copyWith(
      phase: BlePhase.reconnecting,
      reconnectAttempt: _reconnectAttempts,
      message: 'Conexión perdida — reintentando en ${delay}s (intento $_reconnectAttempts/${BleController._maxReconnect})',
    );
    unawaited(ForegroundService.start(
      title: 'Dat Bike: ${state.bikeName ?? device.platformName}',
      text: 'Reconectando (intento $_reconnectAttempts/${BleController._maxReconnect})...',
    ));
    BleLogger.instance.event('reconnect_scheduled', {'attempt': _reconnectAttempts, 'delay_s': delay});
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      _reconnectPending = false;
      if (_manualDisconnect || _reconnectAttempts > BleController._maxReconnect) return;
      try {
        final ok = await _establish(device);
        if (ok && state.isAuthorized) {
          BleLogger.instance.event('reconnected', {'attempt': _reconnectAttempts});
          _reconnectAttempts = 0;
          state = state.copyWith(phase: BlePhase.connected, reconnectAttempt: 0, message: null);
          unawaited(ForegroundService.start(
            title: 'Dat Bike: ${state.bikeName ?? device.platformName}',
            text: 'Bluetooth conectado — Listo para operar',
          ));
          _failStreak = 0;
          _watchConnection(device);
        } else {
          throw Exception('Autenticación de sesión no completada');
        }
      } catch (e) {
        BleLogger.instance.event('reconnect_failed', {'attempt': _reconnectAttempts, 'error': '$e'});
        _failStreak++;
        if (_failStreak == 2) {
          state = state.copyWith(
            message: 'Esperando liberación de sesión previa en la moto… reintentando…',
          );
          BleLogger.instance.event('reconnect_waiting_cooldown', {'device': device.remoteId.str});
        }
        if (!_manualDisconnect) {
          _scheduleReconnect(device);
        }
      }
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectPending = false;
    if (FlutterBluePlus.isScanningNow) {
      try {
        FlutterBluePlus.stopScan();
      } catch (_) {}
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    await _archiveCurrentTripIfMeaningful();
    TripGpsTracker.instance.stopTracking();
    _cancelReconnect();
    _stopKeepalive();
    _findBikeTimeoutTimer?.cancel();
    _findBikeTimeoutTimer = null;
    _findBikePeriodicTimer?.cancel();
    _findBikePeriodicTimer = null;
    _sessionKey = null;
    _lastRawStatusSig = null;
    await _connSub?.cancel();
    _connSub = null;
    await _notifySub?.cancel();
    _notifySub = null;
    for (final d in FlutterBluePlus.connectedDevices) {
      try {
        await d.disconnect();
      } catch (_) {}
    }
    await BleLogger.instance.close();
    unawaited(ForegroundService.stop());
    state = state.copyWith(
      phase: BlePhase.disconnected,
      isAuthorized: false,
      isFindingBike: false,
    );
  }

  Future<void> forgetBike() async {
    _manualDisconnect = true;
    _cancelReconnect();
    _stopKeepalive();
    _findBikeTimeoutTimer?.cancel();
    _findBikeTimeoutTimer = null;
    _findBikePeriodicTimer?.cancel();
    _findBikePeriodicTimer = null;
    _sessionKey = null;

    final prefs = await _prefs;
    final savedId = prefs.getString(BleController._kLastBikeId);
    final d = _device ?? (savedId != null ? BluetoothDevice.fromId(savedId) : null);
    if (d != null) {
      BleLogger.instance.event('forget_bike', {'device_id': d.remoteId.str});
      try {
        await d.removeBond();
      } catch (_) {}
      try {
        await d.disconnect();
      } catch (_) {}
    }
    for (final dev in FlutterBluePlus.connectedDevices) {
      try {
        await dev.disconnect();
      } catch (_) {}
    }

    await _connSub?.cancel();
    _connSub = null;
    await _notifySub?.cancel();
    _notifySub = null;

    await prefs.remove(BleController._kLastBikeId);
    await prefs.remove(BleController._kLastBikeName);
    await prefs.remove(BleController._kBikePassword);

    await BleLogger.instance.close();
    unawaited(ForegroundService.stop());

    state = const BleState(
      phase: BlePhase.idle,
      message: 'Información de la moto eliminada',
      device: null,
      bikeName: null,
    );
  }
}

