/// Filtro de Kalman 1D optimizado para suavizar lecturas de señal RSSI BLE.
class KalmanFilter1D {
  final double processNoise;
  final double measurementNoise;

  double? _estimate;
  double _errorCovariance = 1.0;

  KalmanFilter1D({
    this.processNoise = 0.008,
    this.measurementNoise = 4.0,
    double? initialEstimate,
  }) : _estimate = initialEstimate;

  double? get currentEstimate => _estimate;

  /// Actualiza el filtro con una nueva medición RSSI
  double filter(double measurement) {
    if (_estimate == null) {
      _estimate = measurement;
      _errorCovariance = 1.0;
      return measurement;
    }

    // 1. Predicción
    final pPredicted = _errorCovariance + processNoise;

    // 2. Corrección (Ganancia de Kalman)
    final kalmanGain = pPredicted / (pPredicted + measurementNoise);

    // Actualización de estado
    _estimate = _estimate! + kalmanGain * (measurement - _estimate!);

    // Actualización de covarianza
    _errorCovariance = (1.0 - kalmanGain) * pPredicted;

    return _estimate!;
  }

  void reset([double? initialValue]) {
    _estimate = initialValue;
    _errorCovariance = 1.0;
  }
}
