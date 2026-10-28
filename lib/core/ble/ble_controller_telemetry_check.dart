part of 'ble_controller.dart';

extension BleControllerTelemetryCheck on BleController {
  void _checkAutoLockAndAlert() {
    if (_labModeActive) return;
    if (_smoothedRssi == null) return;
    final rssi = _smoothedRssi!;
    final isBikeOn = state.lastTelemetry?.isBikeOn == true;
    final speed = state.lastTelemetry?.speed ?? 0.0;

    final userRecent = _lastUserCommandAt != null &&
        DateTime.now().difference(_lastUserCommandAt!) < const Duration(seconds: 10);
    final autoAllowed = !_autoSecureBusy && !_isCommandBusy && !userRecent;

    if (state.antiTheft5m && autoAllowed && isBikeOn) {
      if (rssi <= -78) {
        _theftCounter++;
        if (_theftCounter >= 5) {
          _theftCounter = 0;
          unawaited(_runAutoSecureSequence(theft: true, speed: speed, rssi: rssi));
        }
      } else {
        _theftCounter = 0;
      }
    } else {
      _theftCounter = 0;
    }

    if (state.autoLockWalkAway && autoAllowed && isBikeOn && speed <= 0.5) {
      const lockThresholds = [-75.0, -83.0, -90.0];
      final targetThreshold = state.autoLockRssiThreshold ??
          lockThresholds[state.autoLockDistance.clamp(0, 2)];
      if (rssi <= targetThreshold) {
        _autoLockCounter++;
        if (_autoLockCounter >= 3) {
          _autoLockCounter = 0;
          unawaited(_runAutoSecureSequence(theft: false, speed: speed, rssi: rssi));
        }
      } else {
        _autoLockCounter = 0;
      }
    } else {
      _autoLockCounter = 0;
    }

    if (state.walkUpUnlock && autoAllowed) {
      final nearThreshold = state.walkUpRssiThreshold ?? -55.0;
      final needsAction = state.isLocked || (state.walkUpAutoPowerOn && !isBikeOn);
      if (needsAction) {
        if (rssi >= nearThreshold) {
          _unlockNearCounter++;
          if (_unlockNearCounter >= 2) {
            _unlockNearCounter = 0;
            unawaited(_runWalkUpUnlockAndPower(rssi));
          }
        } else {
          _unlockNearCounter = 0;
        }
      } else {
        _unlockNearCounter = 0;
      }
    } else {
      _unlockNearCounter = 0;
    }

    final proximityNoticeThreshold = (state.walkUpRssiThreshold != null)
        ? (state.walkUpRssiThreshold! - 8.0)
        : -65.0;
    if (_smoothedRssi! > proximityNoticeThreshold) {
      if (!_walkUpTriggered) {
        _walkUpTriggered = true;
        BleLogger.instance.event('walk_up_ready', {'rssi': _smoothedRssi});
        state = state.copyWith(
          message: state.walkUpAutoPowerOn
              ? '👋 ¡Cerca de la moto! Preparando encendido automático.'
              : '👋 ¡Cerca de la moto! Lista para operar.',
        );
      }
    } else if (_smoothedRssi! < ((state.autoLockRssiThreshold ?? -83.0) + 5.0)) {
      _walkUpTriggered = false;
    }

    if (state.antiForgetAlert && isBikeOn) {
      const alertThresholds = [-80, -88, -94];
      final threshold = alertThresholds[state.antiForgetDistance.clamp(0, 2)];
      if (_smoothedRssi! <= threshold) {
        _antiForgetCounter++;
        if (_antiForgetCounter == 3) {
          BleLogger.instance.event('anti_forget_alert_triggered', {
            'smoothed_rssi': _smoothedRssi,
            'threshold': threshold,
          });
          state = state.copyWith(
            message: '⚠️ ADVERTENCIA: Te estás alejando pero la moto sigue ENCENDIDA.',
          );
        }
      } else {
        _antiForgetCounter = 0;
      }
    } else {
      _antiForgetCounter = 0;
    }
  }

  bool _isTelemetrySane(BikeLogMsg msg) {
    if (msg.speed.isNaN || msg.speed < 0 || msg.speed > 250) return false;
    if (msg.odo.isNaN || msg.odo < 0 || msg.odo > 500000) return false;
    if (msg.voltage.isNaN || msg.voltage < 10 || msg.voltage > 130) return false;
    if (msg.percent < 0 || msg.percent > 100) return false;
    if (msg.kmLeft.isNaN || msg.kmLeft < 0 || msg.kmLeft > 500) return false;
    return true;
  }

  bool _isValidTelemetry(Uint8List sessionKey, List<int> raw) {
    if (raw.length < 4) return false;
    try {
      final decrypted = BikeSessionCrypto.decryptProtectedRead(
        sessionKey: sessionKey,
        characteristicUuid: Gatt.dashboardCharacteristic,
        response: raw,
      );
      if (decrypted.length >= 41) {
        final m = decodeDashboardStruct(decrypted);
        return _isTelemetrySane(m);
      }
    } catch (_) {}
    return false;
  }

  void _handleBatteryPayload(List<int> raw) {
    if (raw.isEmpty) return;
    Uint8List payload = Uint8List.fromList(raw);

    try {
      final directMsg = decodeBatteryLogMsg(payload);
      if (directMsg.cellVols.isNotEmpty || directMsg.voltage > 0) {
        state = state.copyWith(lastBattery: directMsg);
        BleLogger.instance.event('battery_log_received_plain', {
          'voltage': directMsg.voltage,
          'current': directMsg.current,
          'cells': directMsg.cellVols.length,
          'balancing': directMsg.balancing,
          'protection': directMsg.protection,
        });
        return;
      }
    } catch (_) {}

    if (_sessionKey != null) {
      try {
        final decrypted = BikeSessionCrypto.decryptProtectedRead(
          sessionKey: _sessionKey!,
          characteristicUuid: Gatt.batteryLogCharacteristic,
          response: raw,
          expectedLength: 207,
        );
        if (decrypted.isNotEmpty) {
          final bMsg = decodeBatteryLogMsg(decrypted);
          state = state.copyWith(lastBattery: bMsg);
          BleLogger.instance.event('battery_log_received_decrypted', {
            'voltage': bMsg.voltage,
            'current': bMsg.current,
            'cells': bMsg.cellVols.length,
            'balancing': bMsg.balancing,
            'protection': bMsg.protection,
          });
          return;
        }
      } catch (e) {
        BleLogger.instance.event('battery_decode_err', {'error': '$e'});
      }
    }
  }

  Future<void> fetchBatteryDetails() async {
    final dev = _device;
    if (dev == null || state.phase != BlePhase.connected) return;
    _batteryChar ??= _findCharacteristic(Gatt.batteryLogCharacteristic);
    final bChar = _batteryChar;
    if (bChar == null) return;
    try {
      final raw = await _enqueueGatt(() => bChar.read());
      _handleBatteryPayload(raw);
    } catch (e) {
      BleLogger.instance.event('battery_read_err', {'error': '$e'});
    }
  }
}

