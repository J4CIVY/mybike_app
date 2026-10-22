import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeyManager {
  SecureKeyManager._();

  static const int _seed = 0x20261022;

  static const List<int> _tokenShards = [
    37, 81, 207, 82, 185, 203, 131, 79, 37, 200, 124, 170, 145, 79, 236, 230,
    6, 41, 111, 160, 95, 107, 182, 231, 212, 25, 175, 169, 203, 170, 37, 224,
    145, 2, 146, 72
  ];

  static const List<int> _pwDefaultShards = [115, 80, 206, 7, 236];

  static const List<int> _pwPrimaryShards = [
    115, 10, 181, 120, 227, 159, 137, 92, 78, 146, 59, 160
  ];

  static const List<int> _pwSecondaryShards = [117, 88, 204, 4, 226, 196];

  static const List<int> _authPrefixShards = [2, 42, 153, 66, 175, 154];

  static const List<int> _sessionSaltShards = [2, 42, 139, 82, 168, 129, 139];

  static List<int> _deriveDynamicMask(int length, int seed) {
    final mask = List<int>.filled(length, 0);
    var v = seed ^ 0x5a5aa5a5;
    for (var i = 0; i < length; i++) {
      v = (v * 1664525 + 1013904223) & 0xffffffff;
      mask[i] = (v >> 16) & 0xff;
    }
    return mask;
  }

  static String _reconstruct(List<int> sharded, int seed) {
    final mask = _deriveDynamicMask(sharded.length, seed);
    final bytes = Uint8List(sharded.length);
    for (var i = 0; i < sharded.length; i++) {
      bytes[i] = sharded[i] ^ mask[i];
    }
    final res = utf8.decode(bytes);
    bytes.fillRange(0, bytes.length, 0);
    return res;
  }

  static String get defaultPairingToken => _reconstruct(_tokenShards, _seed);

  static String get defaultPassword => _reconstruct(_pwDefaultShards, _seed);

  static String get presetPrimaryPassword => _reconstruct(_pwPrimaryShards, _seed);

  static String get presetSecondaryPassword => _reconstruct(_pwSecondaryShards, _seed);

  static String get authPrefix => _reconstruct(_authPrefixShards, _seed);

  static String get sessionSalt => _reconstruct(_sessionSaltShards, _seed);

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static String _pwKey(String bikeId) => 'sec_pw_$bikeId';
  static String _tokenKey(String bikeId) => 'sec_tok_$bikeId';

  static Future<void> saveBikePassword(String bikeId, String password) async {
    if (bikeId.isEmpty) return;
    await _storage.write(key: _pwKey(bikeId), value: password);
  }

  static Future<String?> getBikePassword(String bikeId) async {
    if (bikeId.isEmpty) return null;
    return await _storage.read(key: _pwKey(bikeId));
  }

  static Future<void> saveSessionToken(String bikeId, String token) async {
    if (bikeId.isEmpty) return;
    await _storage.write(key: _tokenKey(bikeId), value: token);
  }

  static Future<String?> getSessionToken(String bikeId) async {
    if (bikeId.isEmpty) return null;
    return await _storage.read(key: _tokenKey(bikeId));
  }

  static Future<void> deleteBikeCredentials(String bikeId) async {
    if (bikeId.isEmpty) return;
    await _storage.delete(key: _pwKey(bikeId));
    await _storage.delete(key: _tokenKey(bikeId));
  }

  static Future<void> clearAllCredentials() async {
    await _storage.deleteAll();
  }
}
