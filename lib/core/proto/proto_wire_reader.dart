import 'dart:convert';
import 'dart:typed_data';

class ProtoReader {
  final Uint8List b;
  int pos = 0;
  ProtoReader(this.b);
  bool get eof => pos >= b.length;

  int readVarint() {
    var result = 0;
    var shift = 0;
    while (!eof) {
      final byte = b[pos++];
      result |= (byte & 0x7f) << shift;
      if (byte & 0x80 == 0) break;
      shift += 7;
      if (shift > 63) break;
    }
    return result;
  }

  double readFloat() {
    final v = ByteData.sublistView(b, pos, pos + 4).getFloat32(0, Endian.little);
    pos += 4;
    return v;
  }

  Uint8List readBytes(int len) {
    final out = Uint8List.sublistView(b, pos, pos + len);
    pos += len;
    return out;
  }
}

void forEachProtoField(Uint8List data, void Function(int field, int wire, ProtoReader r) fn) {
  final r = ProtoReader(data);
  while (!r.eof) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    final before = r.pos;
    fn(field, wire, r);
    if (r.pos == before) skipProtoWire(r, wire);
  }
}

String? readProtoString(ProtoReader r, int wire) {
  if (wire != 2) return null;
  final len = r.readVarint();
  return utf8.decode(r.readBytes(len), allowMalformed: true);
}

double? readProtoFloat(ProtoReader r, int wire) {
  if (wire != 5) return null;
  return r.readFloat();
}

int? readProtoVarint(ProtoReader r, int wire) {
  if (wire != 0) return null;
  return r.readVarint();
}

List<double>? readProtoPackedFloats(ProtoReader r, int wire) {
  if (wire != 2) return null;
  final len = r.readVarint();
  final body = r.readBytes(len);
  final out = <double>[];
  final rr = ProtoReader(body);
  while (!rr.eof) {
    out.add(rr.readFloat());
  }
  return out;
}

List<int>? readProtoPackedVarints(ProtoReader r, int wire) {
  if (wire != 2) return null;
  final len = r.readVarint();
  final body = r.readBytes(len);
  final out = <int>[];
  final rr = ProtoReader(body);
  while (!rr.eof) {
    out.add(rr.readVarint());
  }
  return out;
}

void skipProtoWire(ProtoReader r, int wire) {
  switch (wire) {
    case 0:
      r.readVarint();
    case 1:
      r.readBytes(8);
    case 2:
      r.readBytes(r.readVarint());
    case 5:
      r.readBytes(4);
    default:
      throw FormatException('wire type $wire no soportado');
  }
}

