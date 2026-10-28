part of 'ble_controller.dart';

extension BleControllerPower on BleController {
  Future<void> turnOnBike() async {
    _lastUserCommandAt = DateTime.now();
    if (state.isLocked) {
      state = state.copyWith(
          message: 'La moto está bloqueada — desbloquea antes de encender');
      BleLogger.instance.event('power_blocked', {
        'reason': 'moto bloqueada (ARM) — desbloquear primero',
      });
      throw Exception('La moto está bloqueada — desbloquea antes de encender');
    }
    await _waitWhileCommandBusy();
    if (_isCommandBusy) {
      throw Exception('La moto está procesando la orden anterior, espera un momento...');
    }
    await _throttleCommand();
    _isCommandBusy = true;
    try {
      await _sendPowerCommand('1', 'ENCENDER');
    } finally {
      _isCommandBusy = false;
      _lastCommandCompletedAt = DateTime.now();
    }
  }

  Future<void> turnOffBike() async {
    _lastUserCommandAt = DateTime.now();
    await _waitWhileCommandBusy();
    if (_isCommandBusy) {
      throw Exception('La moto está procesando la orden anterior, espera un momento...');
    }
    await _throttleCommand();
    _isCommandBusy = true;
    try {
      await _sendPowerCommand('0', 'APAGAR');
      unawaited(_archiveCurrentTripIfMeaningful());
    } finally {
      _isCommandBusy = false;
      _lastCommandCompletedAt = DateTime.now();
    }
  }

  Future<void> _sendPowerCommand(String value, String label) async {
    if (!state.isAuthorized || _sessionKey == null) {
      state = state.copyWith(
          message: 'Sesión no autenticada — comando $label ignorado');
      BleLogger.instance.event('power_blocked', {
        'reason': 'sin autenticar — envio bloqueado',
      });
      throw Exception('Sesión de la moto no autenticada');
    }

    final spd = state.lastTelemetry?.speed ?? 0.0;
    if (value == '0' && spd > 0.5) {
      final warn =
          '¡No se puede apagar/bloquear cuando la moto está en marcha (${spd.toStringAsFixed(1)} km/h)!';
      state = state.copyWith(message: warn);
      BleLogger.instance.event('power_command_blocked_safety', {
        'speed': spd,
        'val': value,
        'label': label,
      });
      throw Exception(warn);
    }

    final pwrChar = _findPowerCmdChar();
    if (pwrChar == null) {
      throw Exception('Característica de control de energía no encontrada (7f13fe5c)');
    }

    await _enqueueGatt(() async {
      final frame = BikeSessionCrypto.buildProtectedWrite(
        sessionKey: _sessionKey!,
        counter: _writeCounter++,
        characteristicUuid: pwrChar.uuid.str128,
        data: value.codeUnits,
      );
      await pwrChar.write(frame, withoutResponse: false);
      BleLogger.instance.event('power_command', {
        'target': 'powerOnOffChar (7f13fe5c)',
        'uuid': pwrChar.uuid.str128,
        'val': value,
        'counter': _writeCounter - 1,
      });
    });

    final curTele = state.lastTelemetry;
    if (curTele != null) {
      curTele.state = (value == '1') ? BikeState.parking : BikeState.off;
    }
    state = state.copyWith(
      lastTelemetry: curTele,
      message: 'Comando $label enviado',
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (state.phase == BlePhase.connected) {
        unawaited(_pollDashboard());
      }
    });
  }

  Future<String> unlockBike() async {
    _lastUserCommandAt = DateTime.now();
    final device = _device;
    if (device == null || state.phase != BlePhase.connected) {
      return '¡Moto no conectada por Bluetooth!\n→ Si está bloqueada, pasa la tarjeta NFC por la moto e intenta nuevamente.';
    }
    if (_isCommandBusy) {
      return 'La moto está procesando la orden anterior, por favor espera un momento...';
    }
    try {
      return await setImmobilizer(false);
    } catch (e) {
      return 'Error al enviar orden de desbloqueo: $e';
    }
  }

  Future<String> lockBike() async {
    _lastUserCommandAt = DateTime.now();
    final device = _device;
    if (device == null || state.phase != BlePhase.connected) {
      return '¡Moto no conectada por Bluetooth!';
    }
    if (_isCommandBusy) {
      return 'La moto está procesando la orden anterior, por favor espera un momento...';
    }
    final spd = state.lastTelemetry?.speed ?? 0.0;
    if (spd > 0.5) {
      return '⚠️ ¡No es posible bloquear cuando la moto está en movimiento (${spd.toStringAsFixed(1)} km/h)!';
    }
    if (state.lastTelemetry?.isBikeOn == true) {
      BleLogger.instance.event('lock_flow_auto_off', {'speed': spd});
      try {
        await turnOffBike();
      } catch (e) {
        return 'No fue posible apagar la moto para bloquear: $e\n→ Apágala manualmente e intenta bloquear.';
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    try {
      return await setImmobilizer(true);
    } catch (e) {
      return 'Error al enviar orden de bloqueo: $e';
    }
  }
}

