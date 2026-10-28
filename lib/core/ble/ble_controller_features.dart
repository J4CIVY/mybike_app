part of 'ble_controller.dart';

extension BleControllerFeatures on BleController {
  Future<String> syncTimeWithBike([DateTime? customTime]) async {
    final device = _device;
    if (device == null || state.phase != BlePhase.connected) {
      return '¡Moto no conectada por Bluetooth!';
    }

    final localTime = customTime ?? DateTime.now();
    final totalSecondsLocal =
        (localTime.hour * 3600) + (localTime.minute * 60) + localTime.second;
    final payload = utf8.encode(totalSecondsLocal.toString());

    final timeChar = _findCharacteristic(Gatt.currentTimeChar);
    if (timeChar == null) {
      BleLogger.instance.event('sync_time_err', {'error': 'Characteristic currentTimeChar not found'});
      return '¡Característica de sincronización horaria no encontrada en la moto!';
    }

    try {
      if (_sessionKey != null) {
        final frame = BikeSessionCrypto.buildProtectedWrite(
          sessionKey: _sessionKey!,
          counter: _writeCounter++,
          characteristicUuid: Gatt.currentTimeChar,
          data: payload,
        );
        await _enqueueGatt(() => timeChar.write(frame, withoutResponse: false));
        BleLogger.instance.event('sync_time_success', {
          'type': 'protected',
          'secondsLocal': totalSecondsLocal,
          'timeLocal': localTime.toIso8601String(),
          'counter': _writeCounter - 1,
        });
      } else {
        await _enqueueGatt(() => timeChar.write(payload, withoutResponse: false));
        BleLogger.instance.event('sync_time_success', {
          'type': 'plain',
          'secondsLocal': totalSecondsLocal,
          'timeLocal': localTime.toIso8601String(),
        });
      }

      state = state.copyWith(lastTimeSynced: localTime);
      final formattedTime = '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}';
      return '¡Hora $formattedTime sincronizada con éxito en el tablero de la moto!';
    } catch (e) {
      BleLogger.instance.event('sync_time_err', {'error': '$e'});
      return 'Error al sincronizar hora en la moto: $e';
    }
  }

  Future<String> findBike({Duration timeout = const Duration(seconds: 10)}) async {
    _lastUserCommandAt = DateTime.now();
    final device = _device;
    if (device == null || state.phase != BlePhase.connected || !state.isAuthorized) {
      return '¡Moto no conectada o no autenticada por Bluetooth!';
    }
    final spd = state.lastTelemetry?.speed ?? 0.0;
    if (spd > 0.5) {
      return '¡La función de localizador no está disponible con la moto en movimiento!';
    }
    if (state.lastTelemetry?.isBikeOn == true) {
      return 'El pito localizador funciona con la moto en reposo. Apaga la moto antes de accionar.';
    }

    _findBikeTimeoutTimer?.cancel();
    _findBikePeriodicTimer?.cancel();

    state = state.copyWith(isFindingBike: true, message: 'Localizando moto (sonando pito)…');
    BleLogger.instance.event('find_bike_start', {
      'timeout_s': timeout.inSeconds,
      'pattern': state.findBikePattern,
      'mode': 'honk',
    });

    final pattern = state.findBikePattern;
    final intervalMs = switch (pattern) {
      1 => 1400,
      2 => 1000,
      _ => 1500,
    };

    await _sendFindBikeHonk();

    _findBikePeriodicTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) async {
      if (!state.isFindingBike || _honkBusy) return;
      _honkBusy = true;
      try {
        await _sendFindBikeHonk();
      } catch (e) {
        BleLogger.instance.event('find_bike_tick_err', {'error': '$e'});
      } finally {
        _honkBusy = false;
      }
    });

    _findBikeTimeoutTimer = Timer(timeout, () {
      stopFindBike();
    });
    return 'Localizando moto durante ${timeout.inSeconds}s (activando pito y destello)...';
  }

  Future<String> stopFindBike() async {
    _lastUserCommandAt = DateTime.now();
    _findBikeTimeoutTimer?.cancel();
    _findBikeTimeoutTimer = null;
    _findBikePeriodicTimer?.cancel();
    _findBikePeriodicTimer = null;
    if (state.isFindingBike) {
      state = state.copyWith(isFindingBike: false, message: 'Localizador detenido');
      BleLogger.instance.event('find_bike_stop', {});
    }
    return 'Localizador detenido con éxito.';
  }

  Future<void> _sendFindBikeHonk() async {
    final sw = _findCharacteristic(Gatt.powerSwitchChar);
    if (sw == null) {
      BleLogger.instance.event('find_bike_honk_err',
          {'target': 'powerSwitchChar', 'error': 'char not found'});
      return;
    }
    try {
      await _enqueueGatt(() => sw.write('1'.codeUnits, withoutResponse: false));
      BleLogger.instance.event('find_bike_honk', {
        'target': 'powerSwitchChar',
        'note': 'single plain 1 = honk (LAB verified)',
      });
    } catch (e) {
      BleLogger.instance.event('find_bike_honk_err',
          {'target': 'powerSwitchChar', 'error': '$e'});
    }
  }

  void _startKeepalive() {
    if (!BleController.enableKeepalive) return;
    _keepaliveTimer?.cancel();
    _keepaliveCount = 0;
    _keepaliveTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      _runKeepaliveCycle();
    });
    BleLogger.instance.event('keepalive_start', {});
  }

  void _stopKeepalive() {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
  }

  Future<void> _runKeepaliveCycle() async {
    if (_keepaliveBusy || !state.isAuthorized) return;
    final nonce = _lastAuthNonce15;
    final dev = _device;
    if (nonce == null || dev == null || _activePassword.isEmpty) return;

    final authChar = _findCharacteristic(Gatt.authorizationChar);
    if (authChar == null) return;
    _keepaliveBusy = true;
    try {
      final resp = BikeSessionCrypto.computeAuthResponse(
        pairingToken: Gatt.defaultPairingToken,
        nonce15: nonce,
      );
      await authChar.write(resp, withoutResponse: false);
      final post = await authChar.read();
      _sessionKey = BikeSessionCrypto.deriveSessionKey(
        pairingToken: Gatt.defaultPairingToken,
        password: _activePassword,
        challenge: nonce,
      );
      _writeCounter = 0;
      if (post.length == 16) {
        _lastAuthNonce15 = Uint8List.fromList(post.sublist(0, 15));
      }
      _keepaliveCount++;
      if (_keepaliveCount == 1 || _keepaliveCount % 20 == 0) {
        BleLogger.instance.event('keepalive', {
          'n': _keepaliveCount,
          'answered': BleLogger.hex(nonce),
        });
      }
    } catch (e) {
      BleLogger.instance.event('keepalive_error', {'error': '$e'});
      _stopKeepalive();
    } finally {
      _keepaliveBusy = false;
    }
  }
}

