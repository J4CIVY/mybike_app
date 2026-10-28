part of 'ble_controller.dart';

extension BleControllerStorage on BleController {
  void _initSavedBike() async {
    final SharedPreferences prefs;
    try {
      prefs = await _prefs;
    } catch (e, st) {
      if (!ref.mounted) return;
      await BleLogger.logAppError('prefs_init', e, st);
      state = state.copyWith(
        message: 'Error en almacenamiento local de la app: $e',
      );
      return;
    }
    if (!ref.mounted) return;
    final savedName = prefs.getString(BleController._kLastBikeName);
    final savedId = prefs.getString(BleController._kLastBikeId);
    final autoLock = prefs.getBool(BleController._kAutoLockWalkAway) ?? false;
    final walkUp = prefs.getBool(BleController._kWalkUpUnlock) ?? false;
    final walkUpPowerOn = prefs.getBool(BleController._kWalkUpAutoPowerOn) ?? false;
    final walkUpRssi = prefs.getDouble(BleController._kWalkUpRssiThreshold);
    final autoLockRssi = prefs.getDouble(BleController._kAutoLockRssiThreshold);
    final theft5m = prefs.getBool(BleController._kAntiTheft5m) ?? false;
    final antiForget = prefs.getBool(BleController._kAntiForgetAlert) ?? true;
    final autoLockDist = prefs.getInt(BleController._kAutoLockDistance) ?? 1;
    final antiForgetDist = prefs.getInt(BleController._kAntiForgetDistance) ?? 1;
    final findBikePat = prefs.getInt(BleController._kFindBikePattern) ?? 0;
    final recup = prefs.getInt(BleController._kRecupLevel) ?? 1;
    final throttle = prefs.getInt(BleController._kThrottleResponse) ?? 1;
    final speedLimit = prefs.getInt(BleController._kSpeedLimitMode) ?? 0;
    final eceM = prefs.getInt(BleController._kEceMode) ?? 0;
    final grabM = prefs.getInt(BleController._kGrabMode) ?? 0;
    final idlingOff = prefs.getBool(BleController._kIdlingTurnOff) ?? false;
    final distM = prefs.getInt(BleController._kDistanceMode) ?? 0;
    final chargeP = prefs.getInt(BleController._kChargingProfile) ?? 0;
    final savedUserName = prefs.getString(BleController._kUserName);

    List<TripRecord> loadedHistory = [];
    final tripHistJson = prefs.getString(BleController._kTripHistory);
    if (tripHistJson != null && tripHistJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(tripHistJson) as List<dynamic>;
        loadedHistory = decoded
            .map((e) => TripRecord.fromJson(e as Map<String, dynamic>))
            .where((e) => e.distanceKm >= 1.0)
            .toList();
      } catch (_) {}
    }

    state = state.copyWith(
      bikeName: (savedId != null && savedName != null) ? savedName : state.bikeName,
      userName: savedUserName,
      tripHistory: loadedHistory,
      autoLockWalkAway: autoLock,
      walkUpUnlock: walkUp,
      walkUpAutoPowerOn: walkUpPowerOn,
      walkUpRssiThreshold: walkUpRssi,
      autoLockRssiThreshold: autoLockRssi,
      antiTheft5m: theft5m,
      antiForgetAlert: antiForget,
      autoLockDistance: autoLockDist,
      antiForgetDistance: antiForgetDist,
      findBikePattern: findBikePat,
      recupLevel: recup,
      throttleResponse: throttle,
      speedLimitMode: speedLimit,
      eceMode: eceM,
      grabMode: grabM,
      idlingTurnOff: idlingOff,
      distanceMode: distM,
      chargingProfile: chargeP,
    );
    if (savedId != null && savedId.isNotEmpty) {
      unawaited(tryRestoreLastBike());
    }
  }

  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    final prefs = await _prefs;
    await prefs.setString(BleController._kUserName, trimmed);
    state = state.copyWith(userName: trimmed);
    BleLogger.instance.event('user_name_updated', {'name': trimmed});
  }

  Future<void> clearTripHistory() async {
    state = state.copyWith(tripHistory: const []);
    try {
      final prefs = await _prefs;
      await prefs.remove(BleController._kTripHistory);
      BleLogger.instance.event('trip_history_cleared', {});
    } catch (_) {}
  }

  Future<void> _archiveCurrentTripIfMeaningful() async {
    final trip = state.trip;
    final durSec = trip.duration.inSeconds;
    final gpsDistKm = TripGpsTracker.instance.totalDistanceKm;
    final effectiveDistKm = trip.distanceKm > 0 ? trip.distanceKm : gpsDistKm;

    if (effectiveDistKm < 1.0 || _tripStartTime == null) {
      BleLogger.instance.event('trip_skipped_under_1km', {
        'distance_km': effectiveDistKm,
        'odo_dist_km': trip.distanceKm,
        'gps_dist_km': gpsDistKm,
        'duration_sec': durSec,
      });
      TripGpsTracker.instance.stopTracking();
      TripGpsTracker.instance.clear();
      final curTele = state.lastTelemetry;
      _tripStartOdo = curTele?.odo;
      _tripStartTime = null;
      _tripStartPercent = curTele?.percent;
      _tripMaxSpeed = 0.0;
      _tripSpeedSum = 0.0;
      _tripSpeedSamples = 0;
      state = state.copyWith(
        trip: TripData(powerKw: state.trip.powerKw),
      );
      return;
    }

    final now = DateTime.now();
    final recordedRoute = TripGpsTracker.instance.stopTracking();
    final record = TripRecord(
      startTime: _tripStartTime!,
      endTime: now,
      distanceKm: double.parse(effectiveDistKm.toStringAsFixed(2)),
      durationSec: durSec,
      avgSpeedKmh: trip.avgSpeedKmh,
      maxSpeedKmh: trip.maxSpeedKmh,
      usedPercent: trip.usedPercent,
      startOdo: _tripStartOdo,
      endOdo: state.lastTelemetry?.odo,
      route: recordedRoute,
    );

    final updated = [record, ...state.tripHistory].take(50).toList();
    final curTele = state.lastTelemetry;
    _tripStartOdo = curTele?.odo;
    _tripStartTime = null;
    _tripStartPercent = curTele?.percent;
    _tripMaxSpeed = 0.0;
    _tripSpeedSum = 0.0;
    _tripSpeedSamples = 0;
    state = state.copyWith(
      tripHistory: updated,
      trip: TripData(powerKw: state.trip.powerKw),
    );

    try {
      final prefs = await _prefs;
      final jsonStr = jsonEncode(updated.map((e) => e.toJson()).toList());
      await prefs.setString(BleController._kTripHistory, jsonStr);
      BleLogger.instance.event('trip_archived', {
        'dist_km': record.distanceKm,
        'dur_sec': record.durationSec,
        'avg_speed': record.avgSpeedKmh,
        'route_points': record.route.length,
      });
    } catch (e) {
      BleLogger.instance.event('trip_archive_error', {'error': '$e'});
    }
  }

  Future<String?> lastBikeName() async {
    final prefs = await _prefs;
    return prefs.getString(BleController._kLastBikeName);
  }

  Future<String?> lastBikeId() async {
    final prefs = await _prefs;
    return prefs.getString(BleController._kLastBikeId);
  }

  Future<void> _saveLastBike(BluetoothDevice device, String? name) async {
    final prefs = await _prefs;
    await prefs.setString(BleController._kLastBikeId, device.remoteId.str);
    await prefs.setString(BleController._kLastBikeName, name ?? device.platformName);
    state = state.copyWith(bikeName: name ?? device.platformName);
  }
}

