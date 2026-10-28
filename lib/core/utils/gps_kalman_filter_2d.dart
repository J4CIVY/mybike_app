/// Filtro de Kalman 2D para suavizar coordenadas GPS y reducir deriva
class GpsKalmanFilter2D {
  double? _lat;
  double? _lng;
  double _variance = -1.0;
  DateTime? _lastTimestamp;

  bool get isInitialized => _lat != null && _lng != null;
  double? get lat => _lat;
  double? get lng => _lng;

  void reset() {
    _lat = null;
    _lng = null;
    _variance = -1.0;
    _lastTimestamp = null;
  }

  void filter({
    required double measuredLat,
    required double measuredLng,
    required double accuracyMeters,
    required double speedMps,
    required DateTime timestamp,
  }) {
    final safeAccuracy = accuracyMeters > 0 ? accuracyMeters : 10.0;
    final measurementNoise = safeAccuracy * safeAccuracy;

    if (!isInitialized || _lastTimestamp == null) {
      _lat = measuredLat;
      _lng = measuredLng;
      _variance = measurementNoise;
      _lastTimestamp = timestamp;
      return;
    }

    final dtSec = timestamp.difference(_lastTimestamp!).inMilliseconds / 1000.0;
    _lastTimestamp = timestamp;
    if (dtSec <= 0) return;

    // Predicción
    final effectiveSpeed = speedMps > 0.5 ? speedMps : 0.5;
    final processNoise = (effectiveSpeed * dtSec) * (effectiveSpeed * dtSec);
    final pPredicted = _variance + processNoise;

    // Corrección
    final kalmanGain = pPredicted / (pPredicted + measurementNoise);

    _lat = _lat! + kalmanGain * (measuredLat - _lat!);
    _lng = _lng! + kalmanGain * (measuredLng - _lng!);
    _variance = (1.0 - kalmanGain) * pPredicted;
  }
}

