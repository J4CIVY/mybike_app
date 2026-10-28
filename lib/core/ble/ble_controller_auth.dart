part of 'ble_controller.dart';

extension BleControllerAuth on BleController {
  Future<bool> authenticateSession({
    BluetoothDevice? targetDevice,
    List<BluetoothCharacteristic>? chars,
    String? pairingToken,
    String? password,
    bool forceRegister = false,
  }) async {
    final effectiveChars = (chars != null && chars.isNotEmpty)
        ? chars
        : state.characteristics;

    final dev = targetDevice ?? state.device;

    final token = (pairingToken?.isNotEmpty ?? false)
        ? pairingToken!
        : Gatt.defaultPairingToken;
    final prefs = await _prefs;
    final stored = prefs.getString(BleController._kBikePassword);
    final hasStoredPassword = stored != null && stored.isNotEmpty;
    final pin = (password != null && password.isNotEmpty)
        ? password
        : (hasStoredPassword ? stored : '');

    BleLogger.instance.event('auto_handshake_start', {
      'token': token,
      'pin': pin,
      'chars_count': effectiveChars.length,
      'has_stored': hasStoredPassword,
      'force_register': forceRegister,
    });

    if (effectiveChars.isEmpty) {
      BleLogger.instance.event('auto_handshake_err', {'error': 'Lista de características vacía'});
      return false;
    }

    BluetoothCharacteristic? find(String uuid) {
      final clean = uuid.toLowerCase().replaceAll('-', '');
      for (final c in effectiveChars) {
        if (c.uuid.str128.toLowerCase().replaceAll('-', '') == clean) return c;
      }
      return null;
    }

    try {
      final authChar = find(Gatt.authorizationChar);
      if (authChar == null) {
        BleLogger.instance.event('auto_handshake_err',
            {'error': 'No se encontró AUTHORIZATION_CHAR (5e9a2c71)'});
        return false;
      }

      List<int> nonce1 = Uint8List(0);
      try {
        nonce1 = await authChar
            .read()
            .timeout(const Duration(milliseconds: 800), onTimeout: () => Uint8List(0));
      } catch (e) {
        if (_isAuthError(e)) {
          if (dev != null) {
            await _ensureBonded(dev, reason: 'auth char requiere enlace cifrado');
            try {
              nonce1 = await authChar
                  .read()
                  .timeout(const Duration(milliseconds: 800), onTimeout: () => Uint8List(0));
            } catch (_) {}
          }
        } else {
          BleLogger.instance.event('auto_handshake_step1_warn', {'error': '$e'});
        }
      }

      BleLogger.instance.event('auto_handshake_challenge',
          {'hex': BleLogger.hex(nonce1), 'len': nonce1.length});
      if (nonce1.length != 16) {
        BleLogger.instance.event('auto_handshake_err',
            {'error': 'Nonce debe ser 16B, se recibió ${nonce1.length}'});
        return false;
      }
      var nonce15 = Uint8List.fromList(nonce1.sublist(0, 15));
      final status1 = nonce1[15];
      BleLogger.instance.event('auto_handshake_status', {
        'status': status1,
        'note': status1 == Gatt.authStatusOk ? 'autenticado previamente' : 'no autenticado'
      });

      final appAuthChar = find(Gatt.appAuthChar);
      Uint8List? acceptedNonce;

      if (status1 == Gatt.authStatusOk && !forceRegister) {
        acceptedNonce = Uint8List.fromList(nonce1);
        _lastAuthNonce15 = nonce15;
        BleLogger.instance.event('auto_handshake_fast_path', {'hex': BleLogger.hex(nonce1)});
      } else {
        if (pin.isNotEmpty && appAuthChar != null && !forceRegister) {
          try {
            final challengeRaw = await appAuthChar
                .read()
                .timeout(const Duration(milliseconds: 600), onTimeout: () => Uint8List(0));
            BleLogger.instance.event('auto_handshake_app_auth_read', {
              'hex': BleLogger.hex(challengeRaw),
              'len': challengeRaw.length,
            });
            if (challengeRaw.length >= 4) {
              final respHex = BikeSessionCrypto.computeAppAuthChallengeResponse(
                challengeRaw: challengeRaw,
                password: pin,
              );
              BleLogger.instance.event('auto_handshake_app_auth_solve', {
                'respHex': respHex,
                'candidate_pw': pin,
              });
              await appAuthChar
                  .write(ascii.encode(respHex), withoutResponse: false)
                  .timeout(const Duration(milliseconds: 800));
              await Future.delayed(const Duration(milliseconds: 50));
              try {
                final ack = await appAuthChar
                    .read()
                    .timeout(const Duration(milliseconds: 600), onTimeout: () => Uint8List(0));
                BleLogger.instance.event('auto_handshake_app_auth_ack', {
                  'hex': BleLogger.hex(ack),
                  'verified': ack.isNotEmpty && (ack[0] & 1) == 1,
                });
              } catch (_) {}
            }
          } catch (e) {
            BleLogger.instance.event('auto_handshake_app_auth_error', {'error': '$e'});
          }
        }

        const maxAttempts = 3;
        for (var attempt = 1; attempt <= maxAttempts; attempt++) {
          if (attempt > 1) {
            final fresh = await authChar
                .read()
                .timeout(const Duration(milliseconds: 800), onTimeout: () => Uint8List(0));
            BleLogger.instance.event('auto_handshake_challenge',
                {'attempt': attempt, 'hex': BleLogger.hex(fresh)});
            if (fresh.length == 16) {
              nonce15 = Uint8List.fromList(fresh.sublist(0, 15));
            }
          }
          final resp = BikeSessionCrypto.computeAuthResponse(
            pairingToken: token,
            nonce15: nonce15,
          );

          await authChar
              .write(resp, withoutResponse: false)
              .timeout(const Duration(milliseconds: 800));
          BleLogger.instance.event('auto_handshake_response_sent',
              {'attempt': attempt, 'hex': BleLogger.hex(resp)});

          await Future.delayed(const Duration(milliseconds: 120));

          final post = await authChar
              .read()
              .timeout(const Duration(milliseconds: 800), onTimeout: () => Uint8List(0));
          BleLogger.instance.event('auto_handshake_post_status',
              {'hex': BleLogger.hex(post)});
          if (post.length == 16 && post[15] == Gatt.authStatusOk) {
            acceptedNonce = Uint8List.fromList(post);
            _lastAuthNonce15 = Uint8List.fromList(post.sublist(0, 15));
            break;
          }
          if (attempt < maxAttempts) {
            await Future.delayed(
                Duration(milliseconds: attempt == 1 ? 300 : 1200));
          }
        }
      }

      if (acceptedNonce == null) {
        BleLogger.instance.event('auto_handshake_rejected', {
          'note': 'estado 0x00 persistente — token o challenge no aceptados',
        });
        state = state.copyWith(
          isAuthorized: false,
          message: hasStoredPassword
              ? 'Autenticación rechazada (00) — pasa la tarjeta NFC por la moto si cambiaste de dispositivo'
              : 'Autenticación rechazada (00) — pasa la tarjeta NFC por la moto para vincular por primera vez',
        );
        return false;
      }

      if (dev != null) {
        await _ensureBonded(dev, reason: 'autenticacion exitosa, estableciendo vinculo');
      }

      return await _authenticateSessionPassword(
        token: token,
        pin: pin,
        nonce15: nonce15,
        acceptedNonce: acceptedNonce,
        appAuthChar: appAuthChar,
        forceRegister: forceRegister,
        hasStoredPassword: hasStoredPassword,
        stored: stored,
      );
    } catch (e) {
      BleLogger.instance.event('auto_handshake_failed', {'error': '$e'});
      return false;
    }
  }
}

