part of 'ble_controller.dart';

extension BleControllerSettingsActions on BleController {
  Future<String> setSafeSpeedLimit60(bool on) async {
    if (state.phase != BlePhase.connected) {
      state = state.copyWith(
        speedLimitMode: on ? 1 : 0,
        eceMode: on ? 1 : 0,
        fwSpeedLimitRaw: on ? 1 : 0,
      );
      if (on) {
        return '⚠️ Moto desconectada. Se guardó el límite de 60 km/h localmente.';
      } else {
        return '⚠️ Moto desconectada. Se desactivó el límite de velocidad localmente.\n💡 Al conectar, la app lo sincronizará con la moto.';
      }
    }
    final msg1 = await _writeSetting(Gatt.speedLimitChar, [on ? 0x31 : 0x30], 'límite de velocidad');
    await Future.delayed(const Duration(milliseconds: 120));
    final msg2 = await _writeSetting(Gatt.eceModeChar, [on ? 0x31 : 0x30], 'modo seguro ECE (60 km/h)');
    state = state.copyWith(
      speedLimitMode: on ? 1 : 0,
      eceMode: on ? 1 : 0,
      fwSpeedLimitRaw: on ? 1 : 0,
    );
    if (on) {
      return '⚡ Límite de velocidad de 60 km/h activado (ECE + SpeedLimit).\n'
          '📌 Nota: Con ECE activo, el modo de manejo se mantiene seguro.\n$msg1\n$msg2';
    } else {
      return '🔓 Límite de velocidad y ECE desactivados — Modos liberados.\n'
          '⚠️ Se recomienda reiniciar la moto (Power-Cycle) para actualizar la RAM del controlador.\n$msg1\n$msg2';
    }
  }

  Future<String> setImmobilizer(bool lock) async {
    final spd = state.lastTelemetry?.speed ?? 0.0;
    if (lock && spd > 0.5) {
      return '⚠️ ADVERTENCIA: ¡No es posible bloquear cuando la moto está en movimiento (${spd.toStringAsFixed(1)} km/h)!';
    }
    if (state.phase != BlePhase.connected) {
      state = state.copyWith(isLocked: lock);
      return '⚠️ Moto no conectada por BLE. Estado actualizado en pantalla.';
    }
    final msg = await _writeSetting(
      Gatt.powerProtectedChar,
      [lock ? 0x31 : 0x30],
      lock ? 'bloqueo de seguridad antirrobo' : 'desbloqueo de seguridad',
    );
    state = state.copyWith(isLocked: lock);
    if (lock) {
      return '$msg\n🔒 Moto BLOQUEADA con alarma antirrobo activa. Pasa tu tarjeta NFC o usa la app para desbloquear.';
    }
    return msg;
  }

  Future<String> setBikeLights(bool on) async {
    BleLogger.instance.event('bike_lights_blocked_safety', {
      'requested': on,
      'reason': 'b0ca953d is onWriteVescProgamming XOR toggle, not a light switch',
    });
    return '⚠️ Bloqueado por seguridad: Función de puerto VESC protegida en movimiento.';
  }

  Future<bool?> readLockStatus() async => null;

  Future<String> setFwSpeedLimit(bool on) =>
      _writeSetting(Gatt.speedLimitChar, [on ? 0x31 : 0x30], 'límite de velocidad');

  Future<String> setFwEceMode(bool on) =>
      _writeSetting(Gatt.eceModeChar, [on ? 0x31 : 0x30], 'modo ECE');

  Future<String> setFwGrabMode(bool on) =>
      _writeSetting(Gatt.grabModeChar, [on ? 0x31 : 0x30], 'modo aceleración suave');

  Future<String> setFwIdlingTurnOff(bool on) =>
      _writeSetting(Gatt.idlingTurnOffChar, [on ? 0x31 : 0x30], 'auto-apagado en parada');

  Future<String> setFwDistanceMode(bool on) =>
      _writeSetting(Gatt.distanceChar, [on ? 0x31 : 0x30], 'distancia de proximidad');

  Future<String> setFwChargingProfile(int profile) =>
      _writeSetting(Gatt.chargingProfileChar, [profile.clamp(0, 2)], 'perfil de carga');

  Future<String> startAddNfcCard() async {
    final r = await _writeSetting(Gatt.addCardChar, [0x31], 'registro de tarjeta NFC');
    return '$r\n👉 Pasa la NUEVA tarjeta por el lector NFC de la moto en los próximos 10 segundos…';
  }

  Future<String> turnOffBms() =>
      _writeSetting(Gatt.turnOffBmsChar, [0x31], 'apagar BMS');

  Future<String> factoryResetBle() =>
      _writeSetting(Gatt.resetBleChar, [0x31], 'restablecimiento de fábrica BLE');

  Future<String> recoverFromVescProgrammingMode() async {
    final cur = await readFwSettingRaw(Gatt.vescProgrammingChar, 'check_vesc_prog');
    if (cur.isEmpty || cur[0] == 0) {
      state = state.copyWith(vescProgActive: false);
      return '✅ Puerto VESC en modo Normal (0x00) — no requiere recuperación.';
    }
    final msg = await _writeSetting(
      Gatt.vescProgrammingChar,
      [0x30],
      'restablecer VESC Programming a Normal (0x00)',
    );
    await refreshFwSettings();
    BleLogger.instance.event('vesc_programming_recovered', {'val': state.vescProgActive ? 1 : 0});
    return '🛠️ $msg';
  }

  Future<String?> readFwBikeName() async {
    final dec = await readFwSettingRaw(Gatt.fwNameChar, 'nombre de la moto');
    if (dec.isEmpty) return null;
    return BleLogger.tryUtf8(dec)?.trim();
  }

  Future<String> setFwBikeName(String name) async {
    final trimmed = name.trim();
    final bytes = utf8.encode(
        trimmed.length > 20 ? trimmed.substring(0, 20) : trimmed);
    final res = await _writeSetting(Gatt.fwNameChar, bytes, 'nombre de la moto');
    final prefs = await _prefs;
    await prefs.setString(BleController._kLastBikeName, trimmed);
    state = state.copyWith(bikeName: trimmed);
    return res;
  }
}
