part of 'ble_controller.dart';

extension BleControllerLab on BleController {
  BluetoothCharacteristic? _labChar(String uuid) => _findCharacteristic(uuid);

  void setLabMode(bool active) {
    _labModeActive = active;
    BleLogger.instance.event('lab_mode', {'active': active});
  }

  Future<LabIoResult> labRead(String uuid, {String? testId}) async {
    final sw = Stopwatch()..start();
    final c = _labChar(uuid);
    if (state.phase != BlePhase.connected || c == null) {
      return _labLog(LabIoResult(
        op: 'read',
        uuid: uuid,
        ok: false,
        error: state.phase != BlePhase.connected
            ? 'Moto no conectada'
            : 'Característica no disponible en la tabla GATT (¿UUID incorrecto?)',
      ), testId);
    }
    try {
      final raw = await _enqueueGatt(() => c.read().timeout(
          const Duration(milliseconds: 1600), onTimeout: () => Uint8List(0)));
      List<int>? dec;
      String? text;
      String? parsed;

      final cleanUuid = uuid.replaceAll('-', '').toLowerCase();
      final isBeepScan = cleanUuid.startsWith('87efab0d');

      if (isBeepScan) {
        text = utf8.decode(raw, allowMalformed: true);
      } else {
        if (_sessionKey != null && raw.length >= 4) {
          try {
            final expectedLen = BleControllerQueue.expectedLengthForUuid(uuid);
            final d = BikeSessionCrypto.decryptProtectedRead(
              sessionKey: _sessionKey!,
              characteristicUuid: uuid,
              response: raw,
              expectedLength: expectedLen,
            );
            if (d.isNotEmpty) {
              dec = d;
              text = BleLogger.tryUtf8(d);

              if (cleanUuid.startsWith('35a9b4f6') && d.length >= 12) {
                final bd = ByteData.sublistView(Uint8List.fromList(d), 0, 12);
                final motorCurrent = bd.getFloat32(0, Endian.little);
                final vescVoltage = bd.getFloat32(4, Endian.little);
                final dutyCycle = bd.getFloat32(8, Endian.little);
                parsed = 'VESC: I=${motorCurrent.toStringAsFixed(2)}A, '
                    'V=${vescVoltage.toStringAsFixed(2)}V, '
                    'duty=${dutyCycle.toStringAsFixed(3)}';
              } else if (cleanUuid.startsWith('2c73e84e') && d.length >= 16) {
                final bd = ByteData.sublistView(Uint8List.fromList(d), 0, 16);
                final s0 = bd.getUint32(0, Endian.little);
                final s1 = bd.getUint32(4, Endian.little);
                final s2 = bd.getUint32(8, Endian.little);
                final s3 = bd.getUint32(12, Endian.little);
                parsed = 'LogBuffer: s0=$s0, s1=$s1, s2=$s2, s3=$s3';
              }
            }
          } catch (_) {}
        }
        text ??= BleLogger.tryUtf8(raw);
      }
      return _labLog(LabIoResult(
        op: 'read',
        uuid: uuid,
        ok: true,
        payload: raw,
        decrypted: dec,
        text: text,
        parsed: parsed,
        elapsedMs: sw.elapsedMilliseconds,
      ), testId);
    } catch (e) {
      return _labLog(LabIoResult(
        op: 'read',
        uuid: uuid,
        ok: false,
        error: '$e',
        elapsedMs: sw.elapsedMilliseconds,
      ), testId);
    }
  }

  Future<LabIoResult> labWritePlain(String uuid, List<int> data, {String? testId}) async {
    final sw = Stopwatch()..start();
    final c = _labChar(uuid);
    if (state.phase != BlePhase.connected || c == null) {
      return _labLog(LabIoResult(
        op: 'write_plain',
        uuid: uuid,
        ok: false,
        error: state.phase != BlePhase.connected
            ? 'Moto no conectada'
            : 'Característica no disponible en la tabla GATT',
      ), testId);
    }
    final noResp = !c.properties.write && c.properties.writeWithoutResponse;
    try {
      await _enqueueGatt(() => c.write(Uint8List.fromList(data), withoutResponse: noResp));
      return _labLog(LabIoResult(
        op: 'write_plain',
        uuid: uuid,
        ok: true,
        payload: data,
        text: BleLogger.tryUtf8(data),
        elapsedMs: sw.elapsedMilliseconds,
      ), testId);
    } catch (e) {
      return _labLog(LabIoResult(
        op: 'write_plain',
        uuid: uuid,
        ok: false,
        error: '$e',
        elapsedMs: sw.elapsedMilliseconds,
      ), testId);
    }
  }

  Future<LabIoResult> labWriteProtected(String uuid, List<int> data, {String? testId}) async {
    final sw = Stopwatch()..start();
    final c = _labChar(uuid);
    if (state.phase != BlePhase.connected || c == null) {
      return _labLog(LabIoResult(
        op: 'write_protected',
        uuid: uuid,
        ok: false,
        error: state.phase != BlePhase.connected
            ? 'Moto no conectada'
            : 'Característica no disponible en la tabla GATT',
      ), testId);
    }
    if (_sessionKey == null) {
      return _labLog(LabIoResult(
        op: 'write_protected',
        uuid: uuid,
        ok: false,
        error: 'Sin clave de sesión — conecta y autentica primero',
      ), testId);
    }
    try {
      final frame = BikeSessionCrypto.buildProtectedWrite(
        sessionKey: _sessionKey!,
        counter: _writeCounter++,
        characteristicUuid: uuid,
        data: data,
      );
      await _enqueueGatt(() => c.write(frame, withoutResponse: false));
      return _labLog(LabIoResult(
        op: 'write_protected',
        uuid: uuid,
        ok: true,
        payload: frame,
        elapsedMs: sw.elapsedMilliseconds,
      ), testId, {
        'data_hex': BleLogger.hex(data, maxBytes: 64),
        'data_utf8': BleLogger.tryUtf8(data) ?? '',
        'counter': _writeCounter - 1,
      });
    } catch (e) {
      return _labLog(LabIoResult(
        op: 'write_protected',
        uuid: uuid,
        ok: false,
        error: '$e',
        elapsedMs: sw.elapsedMilliseconds,
      ), testId);
    }
  }

  LabIoResult _labLog(LabIoResult r, String? testId, [Map<String, dynamic>? extra]) {
    BleLogger.instance.event('lab_${r.op}', {
      'test_id': testId,
      'uuid': r.uuid,
      'ok': r.ok,
      if (r.error != null) 'error': r.error,
      if (r.payload.isNotEmpty) 'hex': BleLogger.hex(r.payload, maxBytes: 64),
      if (r.decrypted != null) 'dec_hex': BleLogger.hex(r.decrypted!, maxBytes: 64),
      if (r.decrypted != null) 'dec_utf8': BleLogger.tryUtf8(r.decrypted!) ?? '',
      if (r.text != null) 'utf8': r.text,
      'ms': r.elapsedMs,
      ...?extra,
    });
    return r;
  }
}

