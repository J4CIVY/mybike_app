import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'auth_candidates.dart';
import 'bike_session_crypto.dart';
import '../ble/ble_logger.dart';
import '../ble/gatt.dart';

class AuthProbeResult {
  final bool success;
  final String phase;
  final String detail;
  final Uint8List? sessionKey;

  const AuthProbeResult({
    required this.success,
    required this.phase,
    required this.detail,
    this.sessionKey,
  });
}

class AuthProbe {
  final BluetoothDevice device;
  final String pairingToken;
  final String password;

  AuthProbe({
    required this.device,
    required this.pairingToken,
    required this.password,
  });

  BluetoothCharacteristic? _find(
    List<BluetoothCharacteristic> chars,
    String uuid,
  ) {
    for (final c in chars) {
      if (c.uuid.str128.toLowerCase() == uuid.toLowerCase()) return c;
    }
    return null;
  }

  Future<void> _write(BluetoothCharacteristic c, List<int> payload) async {
    BleLogger.instance.event('probe_write', {
      'uuid': c.uuid.str128.toLowerCase(),
      'len': payload.length,
      'hex': BleLogger.hex(payload),
    });
    await c.write(payload, withoutResponse: false);
  }

  Future<Uint8List> _read(BluetoothCharacteristic c) async {
    final v = await c.read();
    BleLogger.instance.event('probe_read', {
      'uuid': c.uuid.str128.toLowerCase(),
      'len': v.length,
      'hex': BleLogger.hex(v),
      'utf8': BleLogger.tryUtf8(v),
    });
    return Uint8List.fromList(v);
  }

  bool _isAuthError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('137') ||
        s.contains('insufficient') ||
        s.contains('gatt_auth');
  }

  Future<AuthProbeResult> run(List<BluetoothCharacteristic> allChars) async {
    const maxAttempts = 3;
    BleLogger.instance.event('probe_start', {
      'pairing_token_len': pairingToken.length,
      'password_len': password.length,
      'max_attempts': maxAttempts,
    });

    final authChar = _find(allChars, Gatt.authorizationChar);
    if (authChar == null) {
      return const AuthProbeResult(
        success: false,
        phase: 'Configuración',
        detail: 'No se encontró AUTHORIZATION_CHAR (5e9a2c71)',
      );
    }

    Uint8List nonce1;
    try {
      nonce1 = await _read(authChar);
    } catch (e) {
      if (_isAuthError(e)) {
        BleLogger.instance.event('probe_bond_start', {'error': '$e'});
        try {
          await device.createBond();
          BleLogger.instance.event('probe_bond_created', {});
        } catch (e2) {
          return AuthProbeResult(
            success: false,
            phase: 'Emparejamiento',
            detail: 'Fallo al establecer vínculo seguro (Bond): $e2',
          );
        }
        nonce1 = await _read(authChar);
      } else {
        rethrow;
      }
    }

    if (nonce1.length != 16) {
      return AuthProbeResult(
        success: false,
        phase: 'Fase 1',
        detail: 'El nonce debe tener 16 bytes. Se recibieron ${nonce1.length}',
      );
    }
    final nonce15 = Uint8List.fromList(nonce1.sublist(0, 15));
    BleLogger.instance.event('phase1_challenge', {
      'raw': bytesToHex(nonce1),
      'challenge_15B': bytesToHex(nonce15),
      'char': Gatt.authorizationChar,
      'initial_status': nonce1[15],
    });

    final variants = buildAuthVariants(
      pairingToken: pairingToken,
      password: password,
    ).take(maxAttempts).toList();

    Uint8List? acceptedNonce;
    for (final cand in variants) {
      BleLogger.instance.event('phase1_try', {'variant': cand.label});
      final resp = BikeSessionCrypto.computeAuthResponse(
        pairingToken: cand.pairingToken,
        nonce15: nonce15,
      );
      BleLogger.instance.event('phase1_auth_response', {
        'variant': cand.label,
        'response_16B': bytesToHex(resp),
      });
      await _write(authChar, resp);
      await Future.delayed(const Duration(milliseconds: 120));
      final post = await _read(authChar);
      final ok = post.length == 16 && post[15] == Gatt.authStatusOk;
      BleLogger.instance.event('phase1_post_auth', {
        'hex': bytesToHex(post),
        'success': ok,
      });
      if (ok) {
        acceptedNonce = post;
        break;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (acceptedNonce == null) {
      return const AuthProbeResult(
        success: false,
        phase: 'Fase 1',
        detail: 'La moto rechazó la respuesta de autenticación (status 00).',
      );
    }

    final saltNonce = nonce15;
    final dash = _find(allChars, Gatt.dashboardCharacteristic);
    final serialChar = _find(allChars, Gatt.bikeSerial);
    var writeCounter = 0;
    int counterOf(List<int> raw) =>
        raw.length >= 4 ? raw[0] | (raw[1] << 8) | (raw[2] << 16) | (raw[3] << 24) : -1;

    for (final cand in variants) {
      final sessionKey = BikeSessionCrypto.deriveSessionKey(
        pairingToken: cand.pairingToken,
        password: cand.password,
        challenge: saltNonce,
      );
      BleLogger.instance.event('phase2_session_key', {
        'variant': cand.label,
        'salt_nonce': bytesToHex(saltNonce),
        'key8': BleLogger.hex(sessionKey.sublist(0, 8)),
      });

      if (serialChar != null) {
        final frame = BikeSessionCrypto.buildProtectedWrite(
          sessionKey: sessionKey,
          counter: writeCounter++,
          characteristicUuid: Gatt.bikeSerial,
          data: cand.password.codeUnits,
        );
        await _write(serialChar, frame);
      }
      if (cand == variants.first) {
        final sessionUuidChar = _find(allChars, Gatt.sessionUuid);
        if (sessionUuidChar != null) {
          await _write(sessionUuidChar, cand.pairingToken.codeUnits);
        }
      }

      if (dash == null) continue;
      final r1 = await _read(dash);
      await Future.delayed(const Duration(milliseconds: 900));
      final r2 = await _read(dash);
      final c1 = counterOf(r1), c2 = counterOf(r2);
      final live = c1 >= 0 && c2 > c1;
      BleLogger.instance.event('phase3_oracle', {
        'variant': cand.label,
        'counter1': c1,
        'counter2': c2,
        'session_live': live,
      });
      if (live) {
        return AuthProbeResult(
          success: true,
          phase: 'Fase 3',
          detail: 'Sesión válida establecida ($c1 -> $c2)',
          sessionKey: sessionKey,
        );
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    return const AuthProbeResult(
      success: true,
      phase: 'Fase 3',
      detail: 'Autenticación Fase 1 aceptada. Verifique el código PIN o contraseña de la moto.',
    );
  }
}
