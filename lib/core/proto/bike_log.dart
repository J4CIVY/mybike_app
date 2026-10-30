import 'dart:convert';
import 'dart:typed_data';

import 'bike_models.dart';
import 'proto_wire_reader.dart';

export 'bike_models.dart';
export 'dashboard_struct_decoder.dart';

BikeLogMsg decodeBikeIdentityLog(Uint8List data) => decodeBikeLogMsg(data);

ChargerLogMsg? decodeChargerLogMsg(Uint8List data) {
  final m = ChargerLogMsg();
  var seen = false;
  void setInt(void Function(int) assign, ProtoReader r, int wire) {
    final v = readProtoVarint(r, wire);
    if (v != null) {
      assign(v);
      seen = true;
    }
  }

  forEachProtoField(data, (field, wire, r) {
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
        skipProtoWire(r, wire);
    }
  });
  return seen ? m : null;
}

BikeLogMsg decodeBikeLogMsg(Uint8List data) {
  final m = BikeLogMsg();
  forEachProtoField(data, (field, wire, r) {
    switch (field) {
      case 1:
        m.name = readProtoString(r, wire) ?? m.name;
      case 2:
        m.model = readProtoString(r, wire) ?? m.model;
      case 3:
        m.frame = readProtoString(r, wire) ?? m.frame;
      case 4:
        m.distance = readProtoVarint(r, wire) ?? m.distance;
      case 5:
        m.idleOff = (readProtoVarint(r, wire) ?? 0) != 0;
      case 6:
        m.version = readProtoString(r, wire) ?? m.version;
      case 7:
        m.hash = readProtoString(r, wire) ?? m.hash;
      case 8:
        m.ecu = readProtoFloat(r, wire) ?? m.ecu;
      case 9:
        m.motor = readProtoFloat(r, wire) ?? m.motor;
      case 10:
        m.adc1 = readProtoFloat(r, wire) ?? m.adc1;
      case 11:
        m.adc2 = readProtoFloat(r, wire) ?? m.adc2;
      case 12:
        m.phase = readProtoFloat(r, wire) ?? m.phase;
      case 13:
        m.state = BikeState.fromInt(readProtoVarint(r, wire) ?? 0);
      case 14:
        m.error = readProtoVarint(r, wire) ?? m.error;
      case 15:
        m.odo = readProtoFloat(r, wire) ?? m.odo;
      case 16:
        m.speed = readProtoFloat(r, wire) ?? m.speed;
      case 17:
        m.throttle = readProtoFloat(r, wire) ?? m.throttle;
      case 18:
        m.left = (readProtoVarint(r, wire) ?? 0) != 0;
      case 19:
        m.right = (readProtoVarint(r, wire) ?? 0) != 0;
      case 20:
        m.headlight = (readProtoVarint(r, wire) ?? 0) != 0;
      case 21:
        m.kmLeft = readProtoFloat(r, wire) ?? m.kmLeft;
      case 22:
        if (wire == 2) {
          final len = r.readVarint();
          m.charging = decodeChargerLogMsg(r.readBytes(len));
        }
      case 23:
        m.chargeProfile = readProtoVarint(r, wire) ?? m.chargeProfile;
      default:
        skipProtoWire(r, wire);
    }
  });
  return m;
}

BatteryLogMsg decodeBatteryLogMsg(Uint8List data) {
  if (data.isEmpty) return BatteryLogMsg();

  // Fallback si la carga es JSON UTF-8
  if (data[0] == 0x7B) {
    try {
      final jsonStr = utf8.decode(data, allowMalformed: true).trim();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final m = BatteryLogMsg();
      m.voltage = (map['voltage'] as num?)?.toDouble() ?? 0;
      m.current = (map['current'] as num?)?.toDouble() ?? 0;
      m.balancing = (map['balancing'] as num?)?.toInt() ?? 0;
      m.protection = (map['protection'] as num?)?.toInt() ?? 0;
      m.charge = map['charge'] == true;
      m.discharge = map['discharge'] == true;
      m.resistor = (map['resistor'] as num?)?.toDouble() ?? 0;
      m.fet = (map['fet'] as num?)?.toDouble() ?? 0;
      m.error = (map['error'] as num?)?.toInt() ?? 0;

      if (map['cellVols'] is List) {
        m.cellVols = (map['cellVols'] as List)
            .map((e) => (e as num).toDouble())
            .where((v) => v >= 0.0 && v <= 6.0)
            .toList();
      }
      if (map['NTCs'] is List) {
        m.ntcs = (map['NTCs'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      }
      if (map['protections'] is List) {
        m.protections = (map['protections'] as List)
            .map((e) => (e as num).toInt())
            .toList();
      }
      if (map['soc'] is Map) {
        final s = map['soc'] as Map<String, dynamic>;
        m.socV = (s['V'] as num?)?.toDouble() ?? 0;
        m.socI = (s['I'] as num?)?.toDouble() ?? 0;
        m.socAh = (s['Ah'] as num?)?.toDouble() ?? 0;
        m.socCycles = (s['cycles'] as num?)?.toDouble() ?? 0;
        m.socSoc = (s['soc'] as num?)?.toDouble() ?? 0;
        m.socAbsAh = (s['absAh'] as num?)?.toDouble() ?? 0;
      }
      return m;
    } catch (_) {}
  }

  final m = BatteryLogMsg();
  forEachProtoField(data, (field, wire, r) {
    switch (field) {
      case 1:
        m.voltage = readProtoFloat(r, wire) ?? m.voltage;
      case 2:
        m.current = readProtoFloat(r, wire) ?? m.current;
      case 3:
        m.balancing = readProtoVarint(r, wire) ?? m.balancing;
      case 4:
        m.protection = readProtoVarint(r, wire) ?? m.protection;
      case 5:
        m.charge = (readProtoVarint(r, wire) ?? 0) != 0;
      case 6:
        m.discharge = (readProtoVarint(r, wire) ?? 0) != 0;
      case 7:
        if (wire == 2) {
          m.ntcs = readProtoPackedFloats(r, wire) ?? m.ntcs;
        } else if (wire == 5) {
          m.ntcs.add(r.readFloat());
        }
      case 8:
        m.resistor = readProtoFloat(r, wire) ?? m.resistor;
      case 9:
        m.fet = readProtoFloat(r, wire) ?? m.fet;
      case 10:
        if (wire == 2) {
          m.protections = readProtoPackedVarints(r, wire) ?? m.protections;
        } else if (wire == 0) {
          final v = readProtoVarint(r, wire);
          if (v != null) m.protections.add(v);
        }
      case 11:
        m.error = readProtoVarint(r, wire) ?? m.error;
      case 12:
        if (wire == 2) {
          m.cellVols = readProtoPackedFloats(r, wire) ?? m.cellVols;
        } else if (wire == 5) {
          m.cellVols.add(r.readFloat());
        }
      case 13:
        m.socV = readProtoFloat(r, wire) ?? m.socV;
      case 14:
        m.socI = readProtoFloat(r, wire) ?? m.socI;
      case 15:
        m.socAh = readProtoFloat(r, wire) ?? m.socAh;
      case 16:
        m.socCycles = readProtoFloat(r, wire) ?? m.socCycles;
      case 17:
        m.socSoc = readProtoFloat(r, wire) ?? m.socSoc;
      case 18:
        m.socAbsAh = readProtoFloat(r, wire) ?? m.socAbsAh;
      default:
        skipProtoWire(r, wire);
    }
  });
  return m;
}
