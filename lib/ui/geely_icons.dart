import 'dart:math' as math;
import 'package:flutter/material.dart';

part 'icons/geely_icons_base.dart';
part 'icons/geely_icons_controls.dart';
part 'icons/geely_icons_system.dart';

/// Colección de iconos vectoriales personalizados para vehículo eléctrico.
class GeelyIcons {
  GeelyIcons._();

  static Widget lock({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _LockPainter(isOpen: false),
    );
  }

  static Widget lockOpen({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _LockPainter(isOpen: true),
    );
  }

  static Widget findBike({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _FindBikePainter(),
    );
  }

  static Widget charging({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _ChargingBoltPainter(),
    );
  }

  static Widget clock({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _ClockPainter(),
    );
  }

  static Widget trunk({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _TrunkPainter(),
    );
  }

  static Widget fan({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _FanPainter(),
    );
  }

  static Widget bike({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _BikePainter(),
    );
  }

  static Widget battery({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _BatteryPainter(),
    );
  }

  static Widget speedometer({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _SpeedometerPainter(),
    );
  }

  static Widget shield({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _ShieldPainter(),
    );
  }

  static Widget nfc({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _NfcPainter(),
    );
  }

  static Widget settings({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _SettingsPainter(),
    );
  }

  static Widget profile({double size = 22, Color? color}) {
    return _IconWrapper(
      size: size,
      color: color,
      painter: _ProfilePainter(),
    );
  }
}
