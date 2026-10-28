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

  int get errorCode => error;

  bool get isBikeOn => state != BikeState.off && state != BikeState.lock;

  String get drivingModeLabel {
    switch (state) {
      case BikeState.drive:
        return 'DRIVE (D)';
      case BikeState.super_:
        return 'SPORT (S)';
      case BikeState.reverse:
        return 'REVERSE (R)';
      case BikeState.turtle:
        return 'ECO (E)';
      case BikeState.parking:
        return 'PARKING (P)';
      case BikeState.standBy:
        return 'STANDBY';
      case BikeState.off:
        return 'OFF';
      case BikeState.lock:
        return 'LOCKED';
      case BikeState.cruiseControl:
        return 'CRUISE';
    }
  }

  String get drivingModeShort {
    switch (state) {
      case BikeState.super_:
        return 'S';
      case BikeState.reverse:
        return 'R';
      case BikeState.turtle:
        return 'E';
      case BikeState.parking:
        return 'P';
      case BikeState.drive:
      default:
        return 'D';
    }
  }

  bool get isSideStandDown => parking;

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

  int get soh => socSoc > 0 ? socSoc.round() : 98;
  int get cycles => socCycles.round();
  bool get isBalancing => balancing != 0;

  double get minCellVol {
    if (cellVols.isEmpty) return 0.0;
    return cellVols.reduce((a, b) => a < b ? a : b);
  }

  double get maxCellVol {
    if (cellVols.isEmpty) return 0.0;
    return cellVols.reduce((a, b) => a > b ? a : b);
  }

  double get deltaCellMv {
    if (cellVols.isEmpty) return 0.0;
    return (maxCellVol - minCellVol) * 1000.0;
  }

  bool get isDeltaCritical => deltaCellMv > 30.0;

  @override
  String toString() => 'Battery(v=$voltage, i=$current, cells=${cellVols.length}, '
      'delta=${deltaCellMv.toStringAsFixed(1)}mV, soc=$socSoc, cycles=$socCycles, error=$error)';
}

