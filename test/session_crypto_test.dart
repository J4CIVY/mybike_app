import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybike_app/core/session/bike_session_crypto.dart';

const sessionKeyHex = '1a405dead15ec46d76f6eead2c105cb986a96c63dd59e63d58e14cbcb906ab22';
const testUuid = '84c7be0b-7619-45c1-a503-95f4ff8736ed';

Uint8List _hex(String s) => Uint8List.fromList([
      for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
    ]);

void main() {
  test('deriveSessionKey coincide con vector HKDF', () {
    final sk = BikeSessionCrypto.deriveSessionKey(
      pairingToken: '123456',
      password: 'abc123def',
      challenge: Uint8List.fromList([1, 2, 3, 4, 5]),
    );
    expect(_hexTo(sk), sessionKeyHex);
  });

  test('u32le formato little-endian', () {
    expect(_hexTo(BikeSessionCrypto.u32le(7)), '07000000');
    expect(_hexTo(BikeSessionCrypto.u32le(0x12345678)), '78563412');
  });

  test('uuidToBytes remueve guiones y convierte a bytes', () {
    final b = BikeSessionCrypto.uuidToBytes(testUuid);
    expect(b.length, 16);
    expect(b[0], 0x84);
    expect(b[15], 0xed);
  });

  test('buildProtectedWrite coincide con vector de trama', () {
    final frame = BikeSessionCrypto.buildProtectedWrite(
      sessionKey: _hex(sessionKeyHex),
      counter: 7,
      characteristicUuid: testUuid,
      data: [0xAA, 0x55, 0x10],
    );
    expect(_hexTo(frame), '07000000aa5510948b3d10');
  });

  test('computeAuthResponse coincide con vector real de autenticacion', () {
    const token = 'c97eb99d-c695-4b5f-8a99-7b24ff2a7980';
    var r = BikeSessionCrypto.computeAuthResponse(
      pairingToken: token,
      nonce15: _hex('2b4371f9d80e6cca87fe48790c34f4'),
    );
    expect(_hexTo(r), 'b950cdc50aeaeee33e86142717ae7f33');

    r = BikeSessionCrypto.computeAuthResponse(
      pairingToken: token,
      nonce15: _hex('0beb6afd43771d33b009f2f6c0d581'),
    );
    expect(_hexTo(r), '646720b851680b873873170de1dae378');

    r = BikeSessionCrypto.computeAuthResponse(
      pairingToken: token,
      nonce15: _hex('c6f8998126d88b3ba9de9ef35a5d59'),
    );
    expect(_hexTo(r), 'fc7ff0fc9d645e6a76a041757771d1cd');
  });

  test('computeAppAuthChallengeResponse coincide con vector real de btsnoop', () {
    final hashHex = BikeSessionCrypto.computeAppAuthChallengeResponse(
      challengeRaw: [0x6d, 0x41, 0x9f, 0x2f],
      password: '5bMO8m3wF9q3',
    );
    expect(hashHex, 'da18e1345f09f5516e0b800238aef13ca8e1e9825c7dec6d2a7e59d38c901a4b');
  });

  test('decryptProtectedRead: cabecera 4B + XOR keystream + frame <4B retorna vacio', () {
    final resp = _hex(
        '21435842b68adf3a05fd024d81f69951f171b5d84cedadee96907cb7a33c1ba7c6196a79efda79971d5c149c');
    final plain = BikeSessionCrypto.decryptProtectedRead(
      sessionKey: _hex(sessionKeyHex),
      characteristicUuid: testUuid,
      response: resp,
    );
    expect(plain.length, 40);
    expect(_hexTo(plain), _hexTo(Uint8List.fromList(List.generate(40, (i) => i))));

    expect(
      BikeSessionCrypto.decryptProtectedRead(
          sessionKey: _hex(sessionKeyHex),
          characteristicUuid: testUuid,
          response: [0x21, 0x43, 0x00]),
      isEmpty,
    );

    final sliced = BikeSessionCrypto.decryptProtectedRead(
      sessionKey: _hex(sessionKeyHex),
      characteristicUuid: testUuid,
      response: resp,
      expectedLength: 12,
    );
    expect(sliced.length, 12);
    expect(_hexTo(sliced), _hexTo(Uint8List.fromList(List.generate(12, (i) => i))));
  });
}

String _hexTo(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
