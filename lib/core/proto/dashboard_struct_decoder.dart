import 'dart:typed_data';
import 'bike_models.dart';

/// Decodificador de estructura binaria (41 bytes) para la característica Dashboard (6d2eb205)
BikeLogMsg decodeDashboardStruct(Uint8List pt) {
  final m = BikeLogMsg();
  m.model = 'BSKMT';
  m.version = '1.14.0';
  if (pt.length < 41) return m;

  final bd = ByteData.sublistView(pt);
  m.odo = bd.getFloat32(0, Endian.little);
  m.speed = bd.getFloat32(4, Endian.little);
  m.phase = bd.getFloat32(8, Endian.little);
  m.left = pt[12] != 0;
  m.right = pt[13] != 0;
  m.parking = pt[14] != 0;
  m.voltage = bd.getFloat32(15, Endian.little);
  m.percent = pt[19];
  m.bmsTemp = bd.getFloat32(20, Endian.little);
  m.motor = bd.getFloat32(24, Endian.little);
  m.ecu = bd.getFloat32(28, Endian.little);
  m.state = BikeState.fromInt(pt[32]);
  m.error = bd.getUint32(33, Endian.little);
  m.kmLeft = bd.getFloat32(37, Endian.little);
  return m;
}

