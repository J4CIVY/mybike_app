part of 'ble_controller.dart';

extension BleControllerAuthSession on BleController {
  Uint8List _sessionKeyOf(String token, String pw, Uint8List salt) =>
      BikeSessionCrypto.deriveSessionKey(
          pairingToken: token, password: pw, challenge: salt);

  Future<bool> _authenticateSessionPassword({
    required String token,
    required String pin,
    required Uint8List nonce15,
    required Uint8List acceptedNonce,
    required BluetoothCharacteristic? appAuthChar,
    required bool forceRegister,
    required bool hasStoredPassword,
    required String? stored,
  }) async {
    final saltNonce = nonce15;
    final dash = _findCharacteristic(Gatt.dashboardCharacteristic);
    final serialChar = _findCharacteristic(Gatt.bikeSerial);
    final prefs = await _prefs;

    int ctr(List<int> r) => r.length >= 4
        ? r[0] | (r[1] << 8) | (r[2] << 16) | (r[3] << 24)
        : -1;

    Future<bool> tryPassword(String label, String pw, Uint8List salt) async {
      final sk = BikeSessionCrypto.deriveSessionKey(
          pairingToken: token, password: pw, challenge: salt);
      BleLogger.instance.event('auto_handshake_try_password',
          {'candidate': label, 'key8': BleLogger.hex(sk.sublist(0, 8))});
      if (serialChar != null) {
        final now = DateTime.now();
        final secondsOfDay =
            ((now.hour * 3600) + (now.minute * 60) + now.second).toString();
        final frame = BikeSessionCrypto.buildProtectedWrite(
          sessionKey: sk,
          counter: _writeCounter++,
          characteristicUuid: Gatt.timeSyncChar,
          data: secondsOfDay.codeUnits,
        );
        await serialChar
            .write(frame, withoutResponse: false)
            .timeout(const Duration(milliseconds: 800));
        BleLogger.instance.event('auto_handshake_time_sync_probe',
            {'candidate': label, 'seconds_of_day': secondsOfDay, 'hex': BleLogger.hex(frame)});
      }
      if (dash == null) return false;
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        final r1 = await dash
            .read()
            .timeout(const Duration(milliseconds: 800), onTimeout: () => Uint8List(0));
        var live = _isValidTelemetry(sk, r1);
        final c1 = ctr(r1);
        var c2 = c1;
        if (!live) {
          await Future.delayed(const Duration(milliseconds: 700));
          final r2 = await dash
              .read()
              .timeout(const Duration(milliseconds: 800), onTimeout: () => Uint8List(0));
          c2 = ctr(r2);
          live = _isValidTelemetry(sk, r2) || (c1 >= 0 && c2 > c1);
        }
        BleLogger.instance.event('auto_handshake_session_check', {
          'candidate': label,
          'password': pw,
          'counter1': c1,
          'counter2': c2,
          'session_live': live,
          'telemetry_valid': live,
          'salt': BleLogger.hex(salt),
          'sk': BleLogger.hex(sk),
        });
        return live;
      } catch (_) {
        return false;
      }
    }

    var live = false;
    var livePw = '';
    Uint8List? liveKey;

    if (pin.isNotEmpty) {
      _writeCounter = 0;
      live = await tryPassword('candidate "$pin"', pin, saltNonce);
      if (!live) {
        _writeCounter = 0;
        final postNonce15 = Uint8List.fromList(acceptedNonce.sublist(0, 15));
        live = await tryPassword('candidate "$pin" (postNonce)', pin, postNonce15);
        if (live) {
          livePw = pin;
          liveKey = _sessionKeyOf(token, pin, postNonce15);
          await prefs.setString(BleController._kBikePassword, pin);
        }
      } else if (live) {
        livePw = pin;
        liveKey = _sessionKeyOf(token, pin, saltNonce);
        await prefs.setString(BleController._kBikePassword, pin);
      }
    }

    if (!live && hasStoredPassword && stored != pin) {
      _writeCounter = 0;
      live = await tryPassword('registered "$stored"', stored!, saltNonce);
      if (!live) {
        _writeCounter = 0;
        final postNonce15 = Uint8List.fromList(acceptedNonce.sublist(0, 15));
        live = await tryPassword('registered "$stored" (postNonce)', stored, postNonce15);
        if (live) {
          livePw = stored;
          liveKey = _sessionKeyOf(token, stored, postNonce15);
          await prefs.setString(BleController._kBikePassword, stored);
        }
      } else if (live) {
        livePw = stored;
        liveKey = _sessionKeyOf(token, stored, saltNonce);
        await prefs.setString(BleController._kBikePassword, stored);
      }
    }

    if (!live && appAuthChar != null && (!hasStoredPassword || forceRegister)) {
      final newPw = pin.isNotEmpty ? pin : () {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        final rng = Random.secure();
        return List.generate(12, (_) => chars[rng.nextInt(chars.length)]).join();
      }();
      BleLogger.instance.event('auto_handshake_register_password',
          {'new_password': newPw, 'is_fallback': hasStoredPassword});
      try {
        await appAuthChar
            .write(newPw.codeUnits, withoutResponse: false)
            .timeout(const Duration(milliseconds: 800));
        await Future.delayed(const Duration(milliseconds: 80));
        await appAuthChar
            .write(newPw.codeUnits, withoutResponse: false)
            .timeout(const Duration(milliseconds: 800));
        await Future.delayed(const Duration(milliseconds: 80));
        try {
          final ack = await appAuthChar
              .read()
              .timeout(const Duration(milliseconds: 600), onTimeout: () => Uint8List(0));
          BleLogger.instance.event('auto_handshake_register_ack', {'hex': BleLogger.hex(ack)});
        } catch (_) {}
      } catch (e) {
        BleLogger.instance.event('auto_handshake_register_error', {'error': '$e'});
      }

      await Future.delayed(const Duration(milliseconds: 150));
      final authChar = _findCharacteristic(Gatt.authorizationChar);
      if (authChar != null) {
        final nonce2 = await authChar
            .read()
            .timeout(const Duration(milliseconds: 800), onTimeout: () => Uint8List(0));
        if (nonce2.length == 16) {
          final n2 = Uint8List.fromList(nonce2.sublist(0, 15));
          final resp2 = BikeSessionCrypto.computeAuthResponse(pairingToken: token, nonce15: n2);
          await authChar
              .write(resp2, withoutResponse: false)
              .timeout(const Duration(milliseconds: 800));
          await Future.delayed(const Duration(milliseconds: 120));
          final post2 = await authChar
              .read()
              .timeout(const Duration(milliseconds: 800), onTimeout: () => Uint8List(0));
          final ok2 = post2.length == 16 && post2[15] == Gatt.authStatusOk;
          BleLogger.instance.event('auto_handshake_reauth',
              {'post_status': BleLogger.hex(post2), 'ok': ok2});
          if (ok2) {
            _lastAuthNonce15 = Uint8List.fromList(post2.sublist(0, 15));
            final sk2 = _sessionKeyOf(token, newPw, n2);
            BleLogger.instance.event('auto_handshake_session_key', {
              'salt_nonce2': BleLogger.hex(n2),
              'session_key': BleLogger.hex(sk2),
              'password': newPw,
            });
            _writeCounter = 0;
            live = await tryPassword('self-registered', newPw, n2);
            if (live) {
              livePw = newPw;
              liveKey = _sessionKeyOf(token, newPw, n2);
              await prefs.setString(BleController._kBikePassword, newPw);
            }
          }
        }
      }
    }

    if (live && liveKey != null) {
      final sessionUuidChar = _findCharacteristic(Gatt.sessionUuid);
      if (sessionUuidChar != null) {
        await sessionUuidChar
            .write(token.codeUnits, withoutResponse: false)
            .timeout(const Duration(milliseconds: 800));
        BleLogger.instance.event('auto_handshake_uuid_sent', {'token': token});
      }
      _sessionKey = liveKey;
      _activePassword = livePw;
      _startKeepalive();
      state = state.copyWith(
        isAuthorized: true,
        sessionKey: liveKey,
        lastTimeSynced: DateTime.now(),
        message: 'Sesión autenticada correctamente — Lista para operar',
      );

      BleLogger.instance.event('auto_handshake_success');
      unawaited(refreshFwSettings());
      unawaited(fetchVehicleDiagnostics());
      return true;
    } else {
      _sessionKey = null;
      _stopKeepalive();
      final msg = hasStoredPassword
          ? 'Autenticación denegada con la clave guardada. Pasa la tarjeta NFC por la moto o usa Olvidar moto.'
          : 'Autenticación pendiente. Pasa la tarjeta NFC por la moto para emparejar.';
      state = state.copyWith(
        isAuthorized: false,
        sessionKey: null,
        message: msg,
      );
      BleLogger.instance.event('auto_handshake_failed_not_live');
      return false;
    }
  }
}

