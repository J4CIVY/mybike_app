import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybike_app/core/proto/bike_log.dart';

Uint8List u8(List<int> xs) => Uint8List.fromList(xs);

List<int> varint(int v) {
  final out = <int>[];
  while (v > 0x7f) {
    out.add((v & 0x7f) | 0x80);
    v >>= 7;
  }
  out.add(v);
  return out;
}

List<int> tag(int field, int wire) => varint((field << 3) | wire);

void main() {
  test('BikeLogMsg: speed/state/kmLeft/charging', () {
    final speed = <int>[...tag(16, 5), 0x00, 0x00, 0xCC, 0x41]; // 25.5f
    final state = <int>[...tag(13, 0), 3];
    final km = <int>[...tag(21, 5), 0x00, 0x00, 0x28, 0x42];
    final nameBytes = utf8.encode('Xe nha');
    final name = <int>[...tag(1, 2), ...varint(nameBytes.length), ...nameBytes];
    final charger = <int>[...tag(5, 0), ...varint(1500)];
    final charging = <int>[...tag(22, 2), ...varint(charger.length), ...charger];

    final msg = decodeBikeLogMsg(u8([...name, ...state, ...speed, ...km, ...charging]));

    expect(msg.name, 'Xe nha');
    expect(msg.state, BikeState.drive);
    expect(msg.speed, closeTo(25.5, 0.001));
    expect(msg.kmLeft, closeTo(42.0, 0.001));
    expect(msg.charging, isNotNull);
    expect(msg.charging!.power, 1500);
  });

  test('BikeLogMsg: campos desconocidos son ignorados', () {
    final unknown = <int>[...tag(99, 0), 5];
    final speed = <int>[...tag(16, 5), 0x00, 0x00, 0xCC, 0x41];
    final msg = decodeBikeLogMsg(u8([...unknown, ...speed]));
    expect(msg.speed, closeTo(25.5, 0.001));
  });

  test('BatteryLogMsg: cellVols packed + voltage', () {
    final f1 = ByteData(4)..setFloat32(0, 3.85, Endian.little);
    final f2 = ByteData(4)..setFloat32(0, 3.86, Endian.little);
    final body = [...f1.buffer.asUint8List(), ...f2.buffer.asUint8List()];
    final cells = <int>[...tag(12, 2), ...varint(body.length), ...body];
    final volt = <int>[...tag(1, 5), 0x9A, 0x99, 0x69, 0x42];
    final soc = <int>[...tag(17, 5), 0x00, 0x00, 0x99, 0x42];

    final m = decodeBatteryLogMsg(u8([...volt, ...cells, ...soc]));
    expect(m.voltage, closeTo(58.4, 0.001));
    expect(m.cellVols, hasLength(2));
    expect(m.cellVols[0], closeTo(3.85, 0.001));
    expect(m.cellVols[1], closeTo(3.86, 0.001));
    expect(m.socSoc, closeTo(76.5, 0.01));
  });

  test('decodeBikeLogMsg con buffer vacio retorna mensaje vacio', () {
    final m = decodeBikeLogMsg(u8([]));
    expect(m.state, BikeState.off);
    expect(m.name, '');
    expect(m.charging, isNull);
  });

  test('campo con tipo de dato incorrecto no desincroniza campos posteriores', () {
    final wrongWire = <int>[...tag(16, 0), 5];
    final km = <int>[...tag(21, 5), 0x00, 0x00, 0x28, 0x42];
    final m = decodeBikeLogMsg(u8([...wrongWire, ...km]));
    expect(m.speed, 0.0);
    expect(m.kmLeft, closeTo(42.0, 0.001));
  });

  test('BatteryLogMsg: decodificacion desde JSON UTF-8 (soporte 23 celdas)', () {
    final cell23 = List.generate(23, (i) => 3.70 + (i * 0.005));
    final jsonString = jsonEncode({
      'voltage': 85.1,
      'current': 2.4,
      'balancing': 1,
      'protection': 0,
      'charge': true,
      'discharge': false,
      'cellVols': cell23,
      'NTCs': [31.5, 32.0, 31.8],
      'soc': {
        'V': 85.1,
        'I': 2.4,
        'soc': 82.5,
        'cycles': 145.0,
      },
    });

    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    final m = decodeBatteryLogMsg(bytes);

    expect(m.voltage, closeTo(85.1, 0.001));
    expect(m.current, closeTo(2.4, 0.001));
    expect(m.cellVols, hasLength(23));
    expect(m.cellVols.first, closeTo(3.70, 0.001));
    expect(m.cellVols.last, closeTo(3.81, 0.001));
    expect(m.socSoc, closeTo(82.5, 0.01));
    expect(m.socCycles, closeTo(145.0, 0.01));
  });
}
