part of 'ble_controller.dart';

extension BleControllerSettingsIo on BleController {
  Future<String> _writeSetting(String uuid, List<int> data, String label) async {
    if (state.phase != BlePhase.connected || !state.isAuthorized) {
      return 'Moto no conectada o no autenticada — no se pudo aplicar $label';
    }
    final c = _findCharacteristic(uuid);
    if (c == null) {
      BleLogger.instance.event('setting_write_err', {
        'char': uuid,
        'label': label,
        'error': 'char not found',
      });
      return 'La moto no expone la característica $label';
    }
    if (_sessionKey == null) {
      return 'Sin clave de sesión — no se pudo aplicar $label';
    }
    return _enqueueGatt(() async {
      String oldHex = '';
      try {
        final cur = await c.read().timeout(
            const Duration(milliseconds: 1200), onTimeout: () => Uint8List(0));
        final dec = (cur.length >= 4)
            ? BikeSessionCrypto.decryptProtectedRead(
                sessionKey: _sessionKey!,
                characteristicUuid: uuid,
                response: cur,
                expectedLength: BleControllerQueue.expectedLengthForUuid(uuid),
              )
            : Uint8List(0);
        oldHex = dec.isEmpty ? '' : BleLogger.hex(dec, maxBytes: 16);
        BleLogger.instance.event('setting_read_current', {
          'char': uuid,
          'label': label,
          'hex': BleLogger.hex(cur, maxBytes: 48),
          'dec_hex': dec.isEmpty ? '' : BleLogger.hex(dec, maxBytes: 48),
          'dec_utf8': BleLogger.tryUtf8(dec) ?? '',
        });
      } catch (_) {}
      try {
        final frame = BikeSessionCrypto.buildProtectedWrite(
          sessionKey: _sessionKey!,
          counter: _writeCounter++,
          characteristicUuid: uuid,
          data: data,
        );
        await c.write(frame, withoutResponse: false);
        BleLogger.instance.event('setting_write', {
          'char': uuid,
          'label': label,
          'data': String.fromCharCodes(data),
          'counter': _writeCounter - 1,
        });
        await Future.delayed(const Duration(milliseconds: 150));
        String newHex = '';
        try {
          final re = await c.read().timeout(
              const Duration(milliseconds: 1200), onTimeout: () => Uint8List(0));
          final dec = (re.length >= 4)
              ? BikeSessionCrypto.decryptProtectedRead(
                  sessionKey: _sessionKey!,
                  characteristicUuid: uuid,
                  response: re,
                  expectedLength: BleControllerQueue.expectedLengthForUuid(uuid),
                )
              : Uint8List(0);
          newHex = dec.isEmpty ? '' : BleLogger.hex(dec, maxBytes: 16);
          BleLogger.instance.event('setting_verify_read', {
            'char': uuid,
            'label': label,
            'hex': BleLogger.hex(re, maxBytes: 48),
            'dec_hex': dec.isEmpty ? '' : BleLogger.hex(dec, maxBytes: 48),
            'old': oldHex,
            'new': newHex,
          });
        } catch (e) {
          BleLogger.instance.event('setting_verify_read_err', {
            'char': uuid,
            'label': label,
            'error': '$e',
          });
        }
        final tail = newHex.isEmpty
            ? ''
            : (newHex == oldHex
                ? ' — valor sin cambios ($newHex)'
                : ' — confirmado: $oldHex → $newHex');
        return 'Ajuste $label aplicado correctamente (${String.fromCharCodes(data)})$tail';
      } catch (e) {
        BleLogger.instance.event('setting_write_err', {
          'char': uuid,
          'label': label,
          'error': '$e',
        });
        return 'Error al aplicar $label: $e';
      }
    });
  }

  Future<Uint8List> readFwSettingRaw(String uuid, String label) async {
    final empty = Uint8List(0);
    if (state.phase != BlePhase.connected) return empty;
    final c = _findCharacteristic(uuid);
    if (c == null) return empty;
    try {
      final raw = await _enqueueGatt(() => c.read().timeout(
          const Duration(milliseconds: 1200), onTimeout: () => Uint8List(0)));
      if (raw.length < 4) return empty;
      if (_sessionKey == null) return empty;
      final dec = BikeSessionCrypto.decryptProtectedRead(
        sessionKey: _sessionKey!,
        characteristicUuid: uuid,
        response: raw,
        expectedLength: BleControllerQueue.expectedLengthForUuid(uuid),
      );
      BleLogger.instance.event('setting_read', {
        'char': uuid,
        'label': label,
        'hex': BleLogger.hex(raw, maxBytes: 48),
        'dec_hex': dec.isEmpty ? '' : BleLogger.hex(dec, maxBytes: 48),
      });
      return dec;
    } catch (_) {
      return empty;
    }
  }

  Future<void> refreshFwSettings() async {
    if (state.phase != BlePhase.connected || _sessionKey == null) return;
    final speed = await readFwSettingRaw(Gatt.speedLimitChar, 'límite de velocidad');
    final ece = await readFwSettingRaw(Gatt.eceModeChar, 'modo ECE');
    final grab = await readFwSettingRaw(Gatt.grabModeChar, 'modo Grab');
    final idling = await readFwSettingRaw(Gatt.idlingTurnOffChar, 'auto apagado');
    final dist = await readFwSettingRaw(Gatt.distanceChar, 'distancia proximidad');
    final chgDec = await readFwSettingRaw(Gatt.chargingProfileChar, 'perfil carga');
    final vescProgDec = await readFwSettingRaw(Gatt.vescProgrammingChar, 'vesc programming');
    final isLockedVal = await readLockStatus();

    final isLimited = (speed.isNotEmpty && speed[0] == 1) && (ece.isNotEmpty && ece[0] == 1);
    final fwSpeedRaw = speed.isNotEmpty ? speed[0] : null;

    int? distU16;
    if (dist.length >= 2) {
      distU16 = ByteData.sublistView(Uint8List.fromList(dist)).getUint16(0, Endian.little);
    } else if (dist.isNotEmpty) {
      distU16 = dist[0];
    }

    final isVescProg = vescProgDec.isNotEmpty && vescProgDec[0] == 0x01;

    int? chgProfile;
    if (chgDec.isNotEmpty && chgDec[0] >= 0 && chgDec[0] <= 2) {
      chgProfile = chgDec[0];
    }
    state = state.copyWith(
      speedLimitMode: isLimited ? 1 : 0,
      fwSpeedLimitRaw: fwSpeedRaw ?? state.fwSpeedLimitRaw,
      eceMode: ece.isNotEmpty && ece[0] == 1 ? 1 : 0,
      grabMode: grab.isNotEmpty && grab[0] == 1 ? 1 : 0,
      idlingTurnOff: idling.isNotEmpty && idling[0] == 1,
      distanceMode: dist.isNotEmpty && dist[0] > 0 ? 1 : 0,
      distanceRawU16: distU16 ?? state.distanceRawU16,
      vescProgActive: isVescProg,
      chargingProfile: chgProfile ?? state.chargingProfile,
      isLocked: isLockedVal ?? state.isLocked,
    );
    BleLogger.instance.event('fw_settings_synced', {
      'speed': speed.isEmpty ? null : speed[0],
      'ece': ece.isEmpty ? null : ece[0],
      'is_speed_limited': isLimited,
      'grab': grab.isEmpty ? null : grab[0],
      'idling': idling.isEmpty ? null : idling[0],
      'distance': dist.isEmpty ? null : dist[0],
      'distance_u16': distU16,
      'vesc_prog_active': isVescProg,
      'charging_profile': chgProfile,
      'is_locked': isLockedVal,
    });
  }
}

