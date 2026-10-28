part of 'ble_controller.dart';

extension BleControllerDriverProfile on BleController {
  Future<void> setFindBikePattern(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(BleController._kFindBikePattern, val);
    state = state.copyWith(findBikePattern: val);
  }

  Future<void> setRecupLevel(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(BleController._kRecupLevel, val);
    state = state.copyWith(recupLevel: val);
    BleLogger.instance.event('driver_profile_recup_set_local', {'level': val});
  }

  Future<void> setThrottleResponse(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(BleController._kThrottleResponse, val);
    state = state.copyWith(throttleResponse: val);
    BleLogger.instance.event('driver_profile_throttle_set_local', {'response': val});
  }

  Future<void> setEceMode(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(BleController._kEceMode, val);
    state = state.copyWith(eceMode: val);
  }

  Future<void> setGrabMode(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(BleController._kGrabMode, val);
    state = state.copyWith(grabMode: val);
  }

  Future<void> setIdlingTurnOff(bool val) async {
    final prefs = await _prefs;
    await prefs.setBool(BleController._kIdlingTurnOff, val);
    state = state.copyWith(idlingTurnOff: val);
  }

  Future<void> setChargingProfile(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(BleController._kChargingProfile, val);
    state = state.copyWith(chargingProfile: val);
  }

  Future<void> setDistanceMode(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(BleController._kDistanceMode, val);
    state = state.copyWith(distanceMode: val);
  }

  Future<void> setSpeedLimitMode(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(BleController._kSpeedLimitMode, val);
    state = state.copyWith(speedLimitMode: val);
    BleLogger.instance.event('driver_profile_speed_mode_set_local', {'mode': val});
  }

  Future<void> resetTrip() async {
    await _archiveCurrentTripIfMeaningful();
    TripGpsTracker.instance.clear();
    _tripStartOdo = state.lastTelemetry?.odo;
    _tripStartTime = DateTime.now();
    _tripStartPercent = state.lastTelemetry?.percent;
    _tripMaxSpeed = 0.0;
    _tripSpeedSum = 0.0;
    _tripSpeedSamples = 0;
    state = state.copyWith(
      trip: TripData(powerKw: state.trip.powerKw),
    );
  }

  Future<void> setLocalBikeName(String name) async {
    final trimmed = name.trim();
    final prefs = await _prefs;
    await prefs.setString(BleController._kLastBikeName, trimmed);
    state = state.copyWith(bikeName: trimmed);
  }
}

