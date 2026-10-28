part of 'ble_controller.dart';

extension BleControllerDiagnostics on BleController {
  Future<void> fetchVehicleDiagnostics() async {
    if (state.phase != BlePhase.connected || _sessionKey == null) return;

    final modelDec = await readFwSettingRaw(Gatt.bikeModelChar, 'bike_model');
    final modelStr = modelDec.isEmpty ? null : BleLogger.tryUtf8(modelDec)?.trim();

    final mfDec = await readFwSettingRaw(Gatt.boardManifestChar, 'board_manifest');
    final mfStr = mfDec.isEmpty ? null : BleLogger.tryUtf8(mfDec)?.trim();

    await readDeviceSerial();

    final fwName = await readFwBikeName();

    double? vI, vV, vDuty;
    final vescDec = await readFwSettingRaw(Gatt.vescSnapshotChar, 'vesc_snapshot');
    if (vescDec.length >= 12) {
      final bd = ByteData.sublistView(vescDec, 0, 12);
      vI = bd.getFloat32(0, Endian.little);
      vV = bd.getFloat32(4, Endian.little);
      vDuty = bd.getFloat32(8, Endian.little);
    }

    state = state.copyWith(
      bikeName: (fwName != null && fwName.isNotEmpty) ? fwName : state.bikeName,
      bikeModelCode: modelStr ?? state.bikeModelCode,
      boardManifest: mfStr ?? state.boardManifest,
      vescCurrent: vI ?? state.vescCurrent,
      vescVoltage: vV ?? state.vescVoltage,
      vescDutyCycle: vDuty ?? state.vescDutyCycle,
    );
  }

  Future<void> sniffAllCharacteristics() async {
    if (state.phase != BlePhase.connected) return;
    final chars = state.characteristics
        .where((c) => c.properties.read)
        .toList(growable: false);
    BleLogger.instance.event('sniff_sweep_start', {'chars': chars.length});
    for (final c in chars) {
      try {
        final v = await c
            .read()
            .timeout(const Duration(milliseconds: 1500), onTimeout: () => Uint8List(0));
        if (v.isEmpty) {
          BleLogger.instance.event('sniff_read', {
            'uuid': c.uuid.str128,
            'len': 0,
          });
          continue;
        }
        final utf8s = BleLogger.tryUtf8(v);
        BleLogger.instance.event('sniff_read', {
          'uuid': c.uuid.str128,
          'len': v.length,
          'hex': BleLogger.hex(v, maxBytes: 64),
          'utf8': utf8s,
        });
        if (_sessionKey != null && v.length >= 4 && utf8s == null) {
          try {
            final dec = BikeSessionCrypto.decryptProtectedRead(
              sessionKey: _sessionKey!,
              characteristicUuid: c.uuid.str128,
              response: v,
            );
            final decStr = dec.isEmpty ? null : BleLogger.tryUtf8(dec);
            BleLogger.instance.event('sniff_read_decrypted', {
              'uuid': c.uuid.str128,
              'hex': BleLogger.hex(dec, maxBytes: 64),
              'utf8': decStr,
            });
          } catch (_) {}
        }
      } catch (e) {
        BleLogger.instance.event('sniff_read_err', {
          'uuid': c.uuid.str128,
          'error': '$e',
        });
      }
      await Future.delayed(const Duration(milliseconds: 120));
    }
    BleLogger.instance.event('sniff_sweep_done', {});
  }

  Future<String?> readDeviceSerial() async {
    final dev = _device;
    if (dev == null || state.phase != BlePhase.connected) return null;
    final c = _findCharacteristic(Gatt.deviceSerialChar);
    if (c == null) return null;
    try {
      final raw = await _enqueueGatt(() => c.read());
      BleLogger.instance.event('device_serial_read_raw', {
        'len': raw.length,
        'hex': BleLogger.hex(raw),
      });

      String? best;

      if (_sessionKey != null && raw.length >= 4) {
        try {
          final dec = BikeSessionCrypto.decryptProtectedRead(
            sessionKey: _sessionKey!,
            characteristicUuid: Gatt.deviceSerialChar,
            response: raw,
            expectedLength: BleControllerQueue.expectedLengthForUuid(Gatt.deviceSerialChar),
          );
          if (dec.isNotEmpty) {
            BleLogger.instance.event('device_serial_read_decrypted', {
              'hex': BleLogger.hex(dec),
            });
            final s = BleLogger.tryUtf8(dec);
            if (s != null && s.trim().isNotEmpty) best = s.trim();
          }
        } catch (_) {}
      }

      final plain = utf8
          .decode(raw, allowMalformed: true)
          .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '')
          .trim();
      final printable =
          plain.isEmpty ? 0.0 : plain.runes.where((r) => r >= 32 && r <= 126).length / plain.runes.length;
      if (best == null || (plain.isNotEmpty && printable > 0.85 && plain.length >= 4)) {
        best = (printable > 0.85 && plain.isNotEmpty) ? plain : best;
      }

      BleLogger.instance.event('device_serial_read', {
        'serial': best ?? '',
        'source': (best == plain && best != null) ? 'plain' : (best != null ? 'decrypted' : 'none'),
      });
      if (best != null && best.isNotEmpty) {
        state = state.copyWith(frameSerial: best);
        return best;
      }
      return null;
    } catch (e) {
      BleLogger.instance.event('device_serial_read_err', {'error': '$e'});
      return null;
    }
  }
}

