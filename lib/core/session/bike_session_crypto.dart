import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Implementación criptográfica de sesión BLE (HKDF, Protected Read/Write, HMAC-SHA256)
class BikeSessionCrypto {
  BikeSessionCrypto(this.sessionKey);

  final Uint8List sessionKey;

  static const infoSalt = 'DBsess1';
  static const writePrefix = 0x57; // 'W'
  static const readPrefix = 0x52; // 'R'
  static const hmacTagLen = 4;
  static const keystreamBlock = 32;

  /// Derivación de clave de sesión mediante HKDF (Extract + Expand)
  static Uint8List deriveSessionKey({
    required String pairingToken,
    required String password,
    required Uint8List challenge,
  }) {
    final ikm = [...utf8.encode(pairingToken), ...utf8.encode(password)];
    final prk = _hmac(challenge, ikm);
    final info = [...utf8.encode(infoSalt), 0x01];
    return _hmac(prk, info);
  }

  /// Construye trama de escritura protegida: [u32le(counter)][data][hmac-tag 4B]
  static Uint8List buildProtectedWrite({
    required Uint8List sessionKey,
    required int counter,
    required String characteristicUuid,
    required List<int> data,
  }) {
    final counterLe = u32le(counter);
    final uuidBytes = uuidToBytes(characteristicUuid);
    final body = [writePrefix, ...counterLe, ...uuidBytes, ...data];
    final tag = _hmac(sessionKey, body).sublist(0, hmacTagLen);
    return Uint8List.fromList([...counterLe, ...data, ...tag]);
  }

  /// Descifra respuesta de lectura protegida utilizando flujo de claves HMAC
  static Uint8List decryptProtectedRead({
    required Uint8List sessionKey,
    required String characteristicUuid,
    required List<int> response,
    int? expectedLength,
  }) {
    if (response.length < 4) return Uint8List(0);
    final header = response.sublist(0, 4);
    final cipher = response.sublist(4);
    final uuidBytes = uuidToBytes(characteristicUuid);
    final out = Uint8List(cipher.length);
    var block = 0;
    for (var off = 0; off < cipher.length; off += keystreamBlock, block++) {
      final ks = _hmac(sessionKey,
          [readPrefix, ...header, ...uuidBytes, ...u32le(block)]);
      final chunk = (cipher.length - off).clamp(0, keystreamBlock);
      for (var t = 0; t < chunk; t++) {
        out[off + t] = cipher[off + t] ^ ks[t];
      }
    }
    if (expectedLength != null && out.length > expectedLength) {
      return Uint8List.sublistView(out, 0, expectedLength);
    }
    return out;
  }

  /// Calcula respuesta de autenticación Fase 1 con HMAC-SHA256
  static Uint8List computeAuthResponse({
    required String pairingToken,
    required Uint8List nonce15,
  }) {
    final msg =
        Uint8List.fromList([...utf8.encode('DBauth'), ...nonce15]);
    return Uint8List.fromList(
        _hmac(utf8.encode(pairingToken), msg).sublist(0, 16));
  }

  /// Calcula respuesta al desafío SHA-256 para reconexión automática sin tarjeta NFC
  static String computeAppAuthChallengeResponse({
    required List<int> challengeRaw,
    required String password,
  }) {
    if (challengeRaw.length < 4) {
      throw ArgumentError('challengeRaw debe tener al menos 4 bytes');
    }
    final u32 = ByteData.sublistView(Uint8List.fromList(challengeRaw))
        .getUint32(0, Endian.little);
    final challenge = u32 >> 1;
    final hashInput = '$challenge$password';
    return sha256.convert(utf8.encode(hashInput)).toString().toLowerCase();
  }

  static Uint8List u32le(int v) => Uint8List.fromList([
        v & 0xff,
        (v >> 8) & 0xff,
        (v >> 16) & 0xff,
        (v >> 24) & 0xff,
      ]);

  static Uint8List uuidToBytes(String uuid) {
    final hex = uuid.replaceAll('-', '').replaceAll(' ', '');
    if (hex.length != 32) {
      throw FormatException('UUID inválido: $uuid');
    }
    return Uint8List.fromList([
      for (var i = 0; i < 32; i += 2) int.parse(hex.substring(i, i + 2), radix: 16),
    ]);
  }

  static Uint8List _hmac(List<int> key, List<int> msg) =>
      Uint8List.fromList(Hmac(sha256, key).convert(msg).bytes);

  static Uint8List hmacPublic(List<int> key, List<int> msg) =>
      _hmac(key, msg);
}
