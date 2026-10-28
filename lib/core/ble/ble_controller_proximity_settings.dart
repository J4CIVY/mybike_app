part of 'ble_controller.dart';

extension BleControllerProximitySettings on BleController {
  Future<void> setAutoLockWalkAway(bool val) async {
    final prefs = await _prefs;
    await prefs.setBool(BleController._kAutoLockWalkAway, val);
    state = state.copyWith(autoLockWalkAway: val);
  }

  Future<void> setWalkUpUnlock(bool val) async {
    final prefs = await _prefs;
    await prefs.setBool(BleController._kWalkUpUnlock, val);
    state = state.copyWith(walkUpUnlock: val);
  }

  Future<void> setWalkUpAutoPowerOn(bool val) async {
    final prefs = await _prefs;
    await prefs.setBool(BleController._kWalkUpAutoPowerOn, val);
    state = state.copyWith(walkUpAutoPowerOn: val);
    BleLogger.instance.event('walk_up_auto_power_changed', {'enabled': val});
  }

  Future<void> setWalkUpRssiThreshold(double val) async {
    final prefs = await _prefs;
    await prefs.setDouble(BleController._kWalkUpRssiThreshold, val);
    state = state.copyWith(walkUpRssiThreshold: val);
    BleLogger.instance.event('walk_up_rssi_threshold_changed', {'threshold': val});
  }

  Future<void> setAutoLockRssiThreshold(double val) async {
    final prefs = await _prefs;
    await prefs.setDouble(BleController._kAutoLockRssiThreshold, val);
    int distIndex = 1;
    if (val >= -78.0) {
      distIndex = 0;
    } else if (val <= -88.0) {
      distIndex = 2;
    }
    await prefs.setInt(BleController._kAutoLockDistance, distIndex);
    state = state.copyWith(
      autoLockRssiThreshold: val,
      autoLockDistance: distIndex,
    );
    BleLogger.instance.event('auto_lock_rssi_threshold_changed', {'threshold': val});
  }

  Future<void> setAntiTheft5m(bool val) async {
    final prefs = await _prefs;
    await prefs.setBool(BleController._kAntiTheft5m, val);
    state = state.copyWith(antiTheft5m: val);
  }

  Future<void> setAntiForgetAlert(bool val) async {
    final prefs = await _prefs;
    await prefs.setBool(BleController._kAntiForgetAlert, val);
    state = state.copyWith(antiForgetAlert: val);
  }

  Future<void> setAutoLockDistance(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(BleController._kAutoLockDistance, val);
    const lockThresholds = [-75.0, -83.0, -90.0];
    final rssi = lockThresholds[val.clamp(0, 2)];
    await prefs.setDouble(BleController._kAutoLockRssiThreshold, rssi);
    state = state.copyWith(
      autoLockDistance: val,
      autoLockRssiThreshold: rssi,
    );
  }

  Future<void> setAntiForgetDistance(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(BleController._kAntiForgetDistance, val);
    state = state.copyWith(antiForgetDistance: val);
  }
}

