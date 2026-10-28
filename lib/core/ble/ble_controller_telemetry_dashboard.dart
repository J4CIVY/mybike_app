part of 'ble_controller.dart';

extension BleControllerTelemetryDashboard on BleController {
  void _handleDashboardPayload(List<int> raw) {
    String? plainHex;
    Uint8List payloadToDecode = Uint8List.fromList(raw);
    if (_sessionKey != null) {
      try {
        final decrypted = BikeSessionCrypto.decryptProtectedRead(
          sessionKey: _sessionKey!,
          characteristicUuid: Gatt.dashboardCharacteristic,
          response: raw,
          expectedLength: 41,
        );
        if (decrypted.isNotEmpty) {
          payloadToDecode = decrypted;
          plainHex = BleLogger.hex(decrypted, maxBytes: 96);
        }
      } catch (_) {}
    }

    String? dk;
    try {
      final msg = (payloadToDecode.length >= 36)
          ? decodeDashboardStruct(payloadToDecode)
          : decodeBikeLogMsg(payloadToDecode);

      if (!_isTelemetrySane(msg)) {
        _decodeFailStreak++;
        BleLogger.instance.event('dashboard_insane_telemetry', {
          'streak': _decodeFailStreak,
          'speed': msg.speed,
          'odo': msg.odo,
          'volts': msg.voltage,
          'percent': msg.percent,
        });
        if (_decodeFailStreak >= 3) {
          state = state.copyWith(dashboardEncrypted: true);
          if (state.phase == BlePhase.connected && !_establishBusy && _device != null) {
            BleLogger.instance.event('session_resync_triggered', {'reason': 'telemetry_corrupted'});
            unawaited(authenticateSession(targetDevice: _device, chars: state.characteristics));
          }
        }
        return;
      }

      _decodeFailStreak = 0;
      if (state.dashboardEncrypted) {
        state = state.copyWith(dashboardEncrypted: false);
      }

      if (payloadToDecode.length >= 41) {
        final b12 = payloadToDecode[12];
        final bd = ByteData.sublistView(payloadToDecode);
        final b13_14 = bd.getUint16(13, Endian.little);
        final b32 = payloadToDecode[32];
        final sig = '$b12:$b13_14:$b32';
        if (sig != _lastRawStatusSig) {
          _lastRawStatusSig = sig;
          BleLogger.instance.event('dashboard_raw_status_bytes', {
            'byte12': b12,
            'byte13_14': b13_14,
            'byte32': b32,
            'mode': msg.drivingModeLabel,
            'parking': msg.parking,
            'speed': msg.speed,
          });
        }
      }

      dk = 'st=${msg.state.name} sp=${msg.speed} odo=${msg.odo} '
          'km=${msg.kmLeft} ecu=${msg.ecu} mot=${msg.motor} '
          'fw=${msg.version} model=${msg.model}';

      TripGpsTracker.instance.updateBikeSpeed(msg.speed);
      if (!TripGpsTracker.instance.isTracking && (msg.speed > 0.5 || state.phase == BlePhase.connected)) {
        unawaited(TripGpsTracker.instance.startTracking());
      }

      _tripStartTime ??= DateTime.now();
      if (_tripStartOdo == null && msg.odo > 0) _tripStartOdo = msg.odo;
      if (_tripStartPercent == null && msg.percent > 0) _tripStartPercent = msg.percent;

      final dist = (msg.odo > 0 && _tripStartOdo != null)
          ? max(0.0, msg.odo - _tripStartOdo!)
          : state.trip.distanceKm;
      final dur = DateTime.now().difference(_tripStartTime!);
      if (msg.speed > _tripMaxSpeed) _tripMaxSpeed = msg.speed;
      if (msg.speed > 0.5) {
        _tripSpeedSum += msg.speed;
        _tripSpeedSamples++;
      }
      final avgSpd = _tripSpeedSamples > 0 ? (_tripSpeedSum / _tripSpeedSamples) : 0.0;
      final usedPct = (_tripStartPercent != null && msg.percent > 0)
          ? max(0, _tripStartPercent! - msg.percent)
          : 0;
      final pKw = (msg.voltage > 0) ? ((msg.voltage * msg.phase) / 1000.0) : 0.0;

      final currentTrip = TripData(
        distanceKm: dist,
        duration: dur,
        avgSpeedKmh: avgSpd,
        maxSpeedKmh: _tripMaxSpeed,
        usedPercent: usedPct,
        powerKw: pKw,
      );

      String? autoSerial = state.frameSerial;
      if (autoSerial == null && msg.frame.isNotEmpty) {
        final clean = msg.frame.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '').trim();
        if (clean.isNotEmpty) autoSerial = clean;
      }

      state = state.copyWith(lastTelemetry: msg, trip: currentTrip, frameSerial: autoSerial);
      _telemetry.add(BikeTelemetry(msg, DateTime.now()));
    } catch (e) {
      _decodeFailStreak++;
      dk = 'parse_fail: $e';
      if (_decodeFailStreak >= 3) {
        state = state.copyWith(dashboardEncrypted: true);
      }
    }

    final n = _plainLogCount++;
    final detail = n < 3 || n % 20 == 0;
    BleLogger.instance.event('dashboard_payload', {
      'len': raw.length,
      'hex': detail ? BleLogger.hex(raw, maxBytes: 64) : null,
      'plain': detail ? plainHex : null,
      'dk': detail ? dk : null,
    });
  }
}

