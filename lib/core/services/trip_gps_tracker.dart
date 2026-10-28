import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/trip_gps_point.dart';
import '../utils/gps_kalman_filter_2d.dart';
import 'trip_route_smoother.dart';

export '../utils/gps_kalman_filter_2d.dart';
export 'trip_route_smoother.dart';

/// Servicio de rastreo continuo y filtrado de coordenadas GPS durante el viaje
class TripGpsTracker {
  TripGpsTracker._();
  static final TripGpsTracker instance = TripGpsTracker._();

  StreamSubscription<Position>? _positionSub;
  final List<TripGpsPoint> _recordedPoints = [];
  final StreamController<TripGpsPoint> _pointController = StreamController<TripGpsPoint>.broadcast();

  bool _isTracking = false;
  double _lastKnownBikeSpeed = 0.0;
  DateTime? _lastPointTime;
  Position? _lastPosition;
  TripGpsPoint? _lastFilteredPoint;

  final GpsKalmanFilter2D _kalmanFilter = GpsKalmanFilter2D();

  static const double kMaxAcceptableAccuracyMeters = 25.0;
  static const double kMaxRealisticSpeedKmh = 110.0;
  static const double kStationarySpeedKmh = 1.0;
  static const double kStationaryMinDistanceMeters = 6.0;
  static const double kMovingMinDistanceMeters = 2.5;
  static const int kMinIntervalMs = 1200;

  bool get isTracking => _isTracking;
  List<TripGpsPoint> get recordedPoints => List.unmodifiable(_recordedPoints);
  Stream<TripGpsPoint> get onPointRecorded => _pointController.stream;
  Position? get lastPosition => _lastPosition;
  TripGpsPoint? get currentPoint => _recordedPoints.isNotEmpty ? _recordedPoints.last : null;

  double get totalDistanceKm {
    if (_recordedPoints.length < 2) return 0.0;
    double totalMeters = 0.0;
    for (int i = 0; i < _recordedPoints.length - 1; i++) {
      totalMeters += Geolocator.distanceBetween(
        _recordedPoints[i].lat, _recordedPoints[i].lng,
        _recordedPoints[i + 1].lat, _recordedPoints[i + 1].lng,
      );
    }
    return totalMeters / 1000.0;
  }

  void updateBikeSpeed(double speedKmh) {
    _lastKnownBikeSpeed = speedKmh >= 0 ? speedKmh : 0.0;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      _lastPosition = pos;
      return pos;
    } catch (_) {
      return null;
    }
  }

  Future<bool> startTracking() async {
    if (_isTracking) return true;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }
      if (permission == LocationPermission.deniedForever) return false;

      _isTracking = true;
      _recordedPoints.clear();
      _lastPointTime = null;
      _lastFilteredPoint = null;
      _kalmanFilter.reset();

      try {
        final initialPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (initialPos.accuracy <= kMaxAcceptableAccuracyMeters && initialPos.accuracy > 0) {
          _handleNewPosition(initialPos);
        }
      } catch (_) {}

      final LocationSettings locationSettings = defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 2,
              intervalDuration: const Duration(milliseconds: 1000),
            )
          : (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)
              ? AppleSettings(
                  accuracy: LocationAccuracy.high,
                  activityType: ActivityType.automotiveNavigation,
                  distanceFilter: 2,
                  pauseLocationUpdatesAutomatically: true,
                )
              : const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2);

      _positionSub = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _handleNewPosition,
        onError: (_) {},
      );

      return true;
    } catch (_) {
      _isTracking = false;
      return false;
    }
  }

  void _handleNewPosition(Position pos) {
    _lastPosition = pos;
    final now = DateTime.now();

    if (pos.accuracy > kMaxAcceptableAccuracyMeters || pos.accuracy <= 0) return;
    if (_lastPointTime != null && now.difference(_lastPointTime!).inMilliseconds < kMinIntervalMs) return;

    double distFromLast = 0.0;
    double dtSec = 0.0;
    if (_lastFilteredPoint != null) {
      distFromLast = Geolocator.distanceBetween(_lastFilteredPoint!.lat, _lastFilteredPoint!.lng, pos.latitude, pos.longitude);
      dtSec = now.difference(_lastFilteredPoint!.timestamp).inMilliseconds / 1000.0;
    }

    if (_lastFilteredPoint != null && dtSec > 0.05) {
      final calculatedSpeedKmh = (distFromLast / dtSec) * 3.6;
      if (calculatedSpeedKmh > kMaxRealisticSpeedKmh) return;
    }

    double effectiveSpeedKmh = _lastKnownBikeSpeed;
    if (effectiveSpeedKmh <= 0.0 && pos.speed >= 0.0) {
      effectiveSpeedKmh = pos.speed * 3.6;
    }

    final isStationary = effectiveSpeedKmh <= kStationarySpeedKmh && (pos.speed * 3.6) <= kStationarySpeedKmh;
    if (isStationary && _lastFilteredPoint != null) {
      if (distFromLast < kStationaryMinDistanceMeters) return;
    }

    if (!isStationary && _lastFilteredPoint != null && distFromLast < kMovingMinDistanceMeters) {
      return;
    }

    final speedMps = effectiveSpeedKmh / 3.6;
    _kalmanFilter.filter(
      measuredLat: pos.latitude,
      measuredLng: pos.longitude,
      accuracyMeters: pos.accuracy,
      speedMps: speedMps,
      timestamp: now,
    );

    final filteredLat = _kalmanFilter.lat ?? pos.latitude;
    final filteredLng = _kalmanFilter.lng ?? pos.longitude;

    double? heading = pos.heading >= 0 && pos.heading <= 360 ? pos.heading : null;
    if ((heading == null || heading == 0.0) && _lastFilteredPoint != null && distFromLast >= 2.0) {
      heading = calculateBearing(_lastFilteredPoint!.lat, _lastFilteredPoint!.lng, filteredLat, filteredLng);
    }

    final point = TripGpsPoint(
      lat: double.parse(filteredLat.toStringAsFixed(6)),
      lng: double.parse(filteredLng.toStringAsFixed(6)),
      speedKmh: double.parse(effectiveSpeedKmh.toStringAsFixed(1)),
      timestamp: now,
      altitude: pos.altitude > -100 ? double.parse(pos.altitude.toStringAsFixed(1)) : null,
      heading: heading != null ? double.parse(heading.toStringAsFixed(1)) : null,
    );

    _recordedPoints.add(point);
    _lastPointTime = now;
    _lastFilteredPoint = point;
    _pointController.add(point);
  }

  List<TripGpsPoint> stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _isTracking = false;
    _kalmanFilter.reset();
    return cleanAndSmoothRoute(_recordedPoints);
  }

  List<TripGpsPoint> getCurrentRoute() => List<TripGpsPoint>.from(_recordedPoints);

  void clear() {
    _recordedPoints.clear();
    _lastPointTime = null;
    _lastFilteredPoint = null;
    _kalmanFilter.reset();
  }

  // Delegaciones estáticas de compatibilidad
  static double calculateBearing(double lat1, double lng1, double lat2, double lng2) =>
      TripRouteSmoother.calculateBearing(lat1, lng1, lat2, lng2);

  static List<TripGpsPoint> cleanAndSmoothRoute(List<TripGpsPoint> rawPoints) =>
      TripRouteSmoother.cleanAndSmoothRoute(rawPoints);

  static List<TripGpsPoint> generateSampleRoute({
    required double distanceKm,
    required double avgSpeedKmh,
    required double maxSpeedKmh,
    required DateTime startTime,
    required int durationSec,
  }) =>
      TripRouteSmoother.generateSampleRoute(
        distanceKm: distanceKm,
        avgSpeedKmh: avgSpeedKmh,
        maxSpeedKmh: maxSpeedKmh,
        startTime: startTime,
        durationSec: durationSec,
      );
}
