part of 'ble_controller.dart';

extension BleControllerProximityActions on BleController {
  Future<void> _runAutoSecureSequence({
    required bool theft,
    required double speed,
    required double rssi,
  }) async {
    _autoSecureBusy = true;
    try {
      BleLogger.instance.event(
          theft ? 'anti_theft_triggered' : 'auto_secure_triggered',
          {'rssi': rssi, 'speed': speed, 'bike_on': state.lastTelemetry?.isBikeOn});
      if (state.lastTelemetry?.isBikeOn == true) {
        try {
          if (theft && speed > 0.5) {
            await _forceSendPowerOff();
          } else {
            await turnOffBike();
          }
        } catch (e) {
          BleLogger.instance.event('auto_secure_power_off_err', {'error': '$e'});
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
      await setImmobilizer(true);
      state = state.copyWith(
        message: theft
            ? '🚨 Antirrobo activado: vehículo fuera de alcance — apagado y seguro puesto.'
            : '🔒 Moto apagada y asegurada automáticamente (te has alejado).',
      );
    } finally {
      _autoSecureBusy = false;
    }
  }

  BluetoothCharacteristic? _findPowerCmdChar() {
    final direct = _findCharacteristic(Gatt.powerOnOffChar);
    if (direct != null) return direct;
    final chars = state.characteristics;
    for (var i = 0; i + 1 < chars.length; i++) {
      if (chars[i].uuid.str128.toLowerCase() == Gatt.bikeSerial.toLowerCase()) {
        final next = chars[i + 1];
        if (next.serviceUuid.str128.toLowerCase() ==
                Gatt.infoService.toLowerCase() &&
            (next.properties.write || next.properties.writeWithoutResponse)) {
          return next;
        }
      }
    }
    return null;
  }

  Future<void> _forceSendPowerOff() async {
    final pwrChar = _findPowerCmdChar();
    if (pwrChar != null && _sessionKey != null) {
      await _enqueueGatt(() async {
        final frame = BikeSessionCrypto.buildProtectedWrite(
          sessionKey: _sessionKey!,
          counter: _writeCounter++,
          characteristicUuid: pwrChar.uuid.str128,
          data: '0'.codeUnits,
        );
        await pwrChar.write(frame, withoutResponse: false);
      });
      BleLogger.instance.event('power_command', {
        'target': 'powerOnOffChar (7f13fe5c)',
        'val': '0',
        'note': 'anti-theft force',
      });
    }
  }

  Future<void> _runWalkUpUnlockAndPower(double rssi) async {
    BleLogger.instance.event('walk_up_triggered', {
      'rssi': rssi,
      'auto_power': state.walkUpAutoPowerOn,
      'is_locked': state.isLocked,
    });
    try {
      final wasLocked = state.isLocked;
      if (wasLocked) {
        await unlockBike();
      }

      if (state.walkUpAutoPowerOn) {
        final isBikeOn = state.lastTelemetry?.isBikeOn == true;
        if (!isBikeOn) {
          if (wasLocked) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
          await turnOnBike();
          state = state.copyWith(
            message: '⚡ Desbloqueo y encendido automático completado — ¡Listo para rodar!',
          );
          return;
        }
      }

      state = state.copyWith(
        message: '👋 Desbloqueo automático activo. Toca encender para iniciar.',
      );
    } catch (e) {
      BleLogger.instance.event('walk_up_err', {'error': '$e'});
    }
  }
}

