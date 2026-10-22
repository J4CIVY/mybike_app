import 'dart:convert';
import 'dart:typed_data';

enum BikeState {
  off,
  standBy,
  parking,
  drive,
  super_,
  cruiseControl,
  reverse,
  lock,
  turtle;

  static BikeState fromInt(int v) =>
      BikeState.values.firstWhere((e) => e.index == v, orElse: () => BikeState.off);
}

class ChargerLogMsg {
  int stage = 0;
  int fault = 0;
  int profile = 0;
  int fetTemp = 0;
  int power = 0;
  int etaSec = 0;
  int boostLeftSec = 0;
  int vinRms = 0;
  int stageSec = 0;

  @override
  String toString() => 'Charger(stage=$stage, fault=$fault, profile=$profile, '
      'power=${power}W, eta=${etaSec}s, vinRms=$vinRms)';
}

class BikeLogMsg {
  String name = '';
  String model = '';
  String frame = '';
  int distance = 0;
  bool idleOff = false;
  String version = '';
  String hash = '';
  double ecu = 0;
  double motor = 0;
  double adc1 = 0;
  double adc2 = 0;
  double phase = 0;
  BikeState state = BikeState.off;
  int error = 0;
  double odo = 0;
  double speed = 0;
  double throttle = 0;
  bool left = false;
  bool right = false;
  bool headlight = false;
  double kmLeft = 0;
  double voltage = 0;
  int percent = 0;
  double bmsTemp = 0;
  bool parking = false;
  ChargerLogMsg? charging;
  int chargeProfile = 0;

  bool get isBikeOn => state != BikeState.off && state != BikeState.lock;

  @override
  String toString() => 'Bike(name=$name, model=$model, state=$state, '
      'speed=$speed, odo=$odo, kmLeft=$kmLeft, soc=$percent%, v=$voltage, '
      'ecu=$ecu, motor=$motor, bms=$bmsTemp, parking=$parking, error=$error, '
      'charging=${charging == null ? "no" : "yes"})';
}

class BatteryLogMsg {
  double voltage = 0;
  double current = 0;
  int balancing = 0;
  int protection = 0;
  bool charge = false;
  bool discharge = false;
  List<double> ntcs = [];
  double resistor = 0;
  double fet = 0;
  List<int> protections = [];
  int error = 0;
  List<double> cellVols = [];
  double socV = 0;
  double socI = 0;
  double socAh = 0;
  double socCycles = 0;
  double socSoc = 0;
  double socAbsAh = 0;

  @override
  String toString() => 'Battery(v=$voltage, i=$current, cells=${cellVols.length}, '
      'soc=$socSoc, cycles=$socCycles, error=$error)';
}

class _Reader {
  final Uint8List b;
  int pos = 0;
  _Reader(this.b);
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

void _forEachField(Uint8List data, void Function(int field, int wire, _Reader r) fn) {
  final r = _Reader(data);
  while (!r.eof) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    final before = r.pos;
    fn(field, wire, r);

    if (r.pos == before) _skip(r, wire);
  }
}

String? _readString(_Reader r, int wire) {
  if (wire != 2) return null;
  final len = r.readVarint();
  return utf8.decode(r.readBytes(len), allowMalformed: true);
}

double? _readFloat(_Reader r, int wire) {
  if (wire != 5) return null;
  return r.readFloat();
}

int? _readVarint(_Reader r, int wire) {
  if (wire != 0) return null;
  return r.readVarint();
}

List<double>? _readPackedFloats(_Reader r, int wire) {
  if (wire != 2) return null;
  final len = r.readVarint();
  final body = r.readBytes(len);
  final out = <double>[];
  final rr = _Reader(body);
  while (!rr.eof) {
    out.add(rr.readFloat());
  }
  return out;
}

List<int>? _readPackedVarints(_Reader r, int wire) {
  if (wire != 2) return null;
  final len = r.readVarint();
  final body = r.readBytes(len);
  final out = <int>[];
  final rr = _Reader(body);
  while (!rr.eof) {
    out.add(rr.readVarint());
  }
  return out;
}

ChargerLogMsg? decodeChargerLogMsg(Uint8List data) {
  final m = ChargerLogMsg();
  var seen = false;
  void setInt(void Function(int) assign, _Reader r, int wire) {
    final v = _readVarint(r, wire);
    if (v != null) {
      assign(v);
      seen = true;
    }
  }

  _forEachField(data, (field, wire, r) {
    switch (field) {
      case 1:
        setInt((x) => m.stage = x, r, wire);
      case 2:
        setInt((x) => m.fault = x, r, wire);
      case 3:
        setInt((x) => m.profile = x, r, wire);
      case 4:
        setInt((x) => m.fetTemp = x, r, wire);
      case 5:
        setInt((x) => m.power = x, r, wire);
      case 6:
        setInt((x) => m.etaSec = x, r, wire);
      case 7:
        setInt((x) => m.boostLeftSec = x, r, wire);
      case 8:
        setInt((x) => m.vinRms = x, r, wire);
      case 9:
        setInt((x) => m.stageSec = x, r, wire);
      default:
        _skip(r, wire);
    }
  });
  return seen ? m : null;
}

BikeLogMsg decodeBikeLogMsg(Uint8List data) {
  final m = BikeLogMsg();
  _forEachField(data, (field, wire, r) {
    switch (field) {
      case 1:
        m.name = _readString(r, wire) ?? m.name;
      case 2:
        m.model = _readString(r, wire) ?? m.model;
      case 3:
        m.frame = _readString(r, wire) ?? m.frame;
      case 4:
        m.distance = _readVarint(r, wire) ?? m.distance;
      case 5:
        m.idleOff = (_readVarint(r, wire) ?? 0) != 0;
      case 6:
        m.version = _readString(r, wire) ?? m.version;
      case 7:
        m.hash = _readString(r, wire) ?? m.hash;
      case 8:
        m.ecu = _readFloat(r, wire) ?? m.ecu;
      case 9:
        m.motor = _readFloat(r, wire) ?? m.motor;
      case 10:
        m.adc1 = _readFloat(r, wire) ?? m.adc1;
      case 11:
        m.adc2 = _readFloat(r, wire) ?? m.adc2;
      case 12:
        m.phase = _readFloat(r, wire) ?? m.phase;
      case 13:
        m.state = BikeState.fromInt(_readVarint(r, wire) ?? 0);
      case 14:
        m.error = _readVarint(r, wire) ?? m.error;
      case 15:
        m.odo = _readFloat(r, wire) ?? m.odo;
      case 16:
        m.speed = _readFloat(r, wire) ?? m.speed;
      case 17:
        m.throttle = _readFloat(r, wire) ?? m.throttle;
      case 18:
        m.left = (_readVarint(r, wire) ?? 0) != 0;
      case 19:
        m.right = (_readVarint(r, wire) ?? 0) != 0;
      case 20:
        m.headlight = (_readVarint(r, wire) ?? 0) != 0;
      case 21:
        m.kmLeft = _readFloat(r, wire) ?? m.kmLeft;
      case 22:
        if (wire == 2) {
          final len = r.readVarint();
          m.charging = decodeChargerLogMsg(r.readBytes(len));
        }
      case 23:
        m.chargeProfile = _readVarint(r, wire) ?? m.chargeProfile;
      default:
        _skip(r, wire);
    }
  });
  return m;
}

BatteryLogMsg decodeBatteryLogMsg(Uint8List data) {
  final m = BatteryLogMsg();
  _forEachField(data, (field, wire, r) {
    switch (field) {
      case 1:
        m.voltage = _readFloat(r, wire) ?? m.voltage;
      case 2:
        m.current = _readFloat(r, wire) ?? m.current;
      case 3:
        m.balancing = _readVarint(r, wire) ?? m.balancing;
      case 4:
        m.protection = _readVarint(r, wire) ?? m.protection;
      case 5:
        m.charge = (_readVarint(r, wire) ?? 0) != 0;
      case 6:
        m.discharge = (_readVarint(r, wire) ?? 0) != 0;
      case 7:
        m.ntcs = _readPackedFloats(r, wire) ?? m.ntcs;
      case 8:
        m.resistor = _readFloat(r, wire) ?? m.resistor;
      case 9:
        m.fet = _readFloat(r, wire) ?? m.fet;
      case 10:
        m.protections = _readPackedVarints(r, wire) ?? m.protections;
      case 11:
        m.error = _readVarint(r, wire) ?? m.error;
      case 12:
        m.cellVols = _readPackedFloats(r, wire) ?? m.cellVols;
      case 13:
        m.socV = _readFloat(r, wire) ?? m.socV;
      case 14:
        m.socI = _readFloat(r, wire) ?? m.socI;
      case 15:
        m.socAh = _readFloat(r, wire) ?? m.socAh;
      case 16:
        m.socCycles = _readFloat(r, wire) ?? m.socCycles;
      case 17:
        m.socSoc = _readFloat(r, wire) ?? m.socSoc;
      case 18:
        m.socAbsAh = _readFloat(r, wire) ?? m.socAbsAh;
      default:
        _skip(r, wire);
    }
  });
  return m;
}

void _skip(_Reader r, int wire) {
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
      throw FormatException('wire type $wire không hỗ trợ — buffer lỗi?');
  }
}

BikeLogMsg decodeDashboardStruct(Uint8List pt) {
  final m = BikeLogMsg();
  m.model = 'My Bike';
  m.version = '1.0.0';
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
