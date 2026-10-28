import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../models/trip_gps_point.dart';

/// Algoritmos de post-procesamiento, suavizado y cálculo geodésico para rutas
class TripRouteSmoother {
  TripRouteSmoother._();

  static const double kMaxRealisticSpeedKmh = 110.0;

  /// Calcula rumbo geodésico entre dos coordenadas (0° a 360°)
  static double calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final phi1 = lat1 * math.pi / 180.0;
    final phi2 = lat2 * math.pi / 180.0;
    final deltaLambda = (lng2 - lng1) * math.pi / 180.0;

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final theta = math.atan2(y, x);
    return (theta * 180.0 / math.pi + 360.0) % 360.0;
  }

  /// Limpia picos de velocidad anómalos y aplica media móvil ponderada a la ruta
  static List<TripGpsPoint> cleanAndSmoothRoute(List<TripGpsPoint> rawPoints) {
    if (rawPoints.length <= 2) return List.from(rawPoints);

    // 1. Filtrado de saltos y paradas
    final filtered = <TripGpsPoint>[rawPoints.first];
    for (int i = 1; i < rawPoints.length; i++) {
      final prev = filtered.last;
      final cur = rawPoints[i];
      final dt = cur.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;
      final dist = Geolocator.distanceBetween(prev.lat, prev.lng, cur.lat, cur.lng);

      if (dt > 0.05) {
        final speed = (dist / dt) * 3.6;
        if (speed > kMaxRealisticSpeedKmh) {
          continue;
        }
      }

      if (dist < 2.0 && cur.speedKmh <= 1.5 && prev.speedKmh <= 1.5 && i < rawPoints.length - 1) {
        continue;
      }

      filtered.add(cur);
    }

    if (filtered.length <= 2) return filtered;

    // 2. Media móvil ponderada (0.2 - 0.6 - 0.2)
    final smoothed = <TripGpsPoint>[filtered.first];
    for (int i = 1; i < filtered.length - 1; i++) {
      final pPrev = filtered[i - 1];
      final pCur = filtered[i];
      final pNext = filtered[i + 1];

      final smoothLat = 0.2 * pPrev.lat + 0.6 * pCur.lat + 0.2 * pNext.lat;
      final smoothLng = 0.2 * pPrev.lng + 0.6 * pCur.lng + 0.2 * pNext.lng;

      smoothed.add(TripGpsPoint(
        lat: double.parse(smoothLat.toStringAsFixed(6)),
        lng: double.parse(smoothLng.toStringAsFixed(6)),
        speedKmh: pCur.speedKmh,
        timestamp: pCur.timestamp,
        altitude: pCur.altitude,
        heading: pCur.heading,
      ));
    }
    smoothed.add(filtered.last);
    return smoothed;
  }

  /// Genera una ruta representativa para viajes sin datos GPS directos
  static List<TripGpsPoint> generateSampleRoute({
    required double distanceKm,
    required double avgSpeedKmh,
    required double maxSpeedKmh,
    required DateTime startTime,
    required int durationSec,
  }) {
    final points = <TripGpsPoint>[];
    if (durationSec <= 0 || distanceKm <= 0) return points;

    const baseLat = 10.7719;
    const baseLng = 106.7195;

    final numPoints = math.max(15, math.min(100, durationSec ~/ 5));
    final intervalSec = durationSec / numPoints;

    double curLat = baseLat;
    double curLng = baseLng;
    double currentHeading = 45.0;

    final effectiveMaxSpeed = maxSpeedKmh > 5 ? maxSpeedKmh : 48.0;
    final effectiveAvgSpeed = avgSpeedKmh > 3 ? avgSpeedKmh : 28.0;

    for (int i = 0; i < numPoints; i++) {
      final t = i / (numPoints - 1);
      final pointTime = startTime.add(Duration(seconds: (i * intervalSec).round()));

      final speedWave = math.sin(t * math.pi * 3).abs();
      double speed = effectiveAvgSpeed * 0.5 + (effectiveMaxSpeed - effectiveAvgSpeed * 0.5) * speedWave;
      if (i == 0 || i == numPoints - 1) speed = 0.0;
      if (speed > effectiveMaxSpeed) speed = effectiveMaxSpeed;

      if (i % 8 == 0) {
        currentHeading = (currentHeading + 60.0) % 360.0;
      }
      final rad = currentHeading * math.pi / 180.0;

      final stepKm = (speed / 3600.0) * intervalSec;
      final dLat = (stepKm / 111.0) * math.cos(rad);
      final dLng = (stepKm / (111.0 * math.cos(curLat * math.pi / 180.0))) * math.sin(rad);

      curLat += dLat;
      curLng += dLng;

      points.add(TripGpsPoint(
        lat: double.parse(curLat.toStringAsFixed(6)),
        lng: double.parse(curLng.toStringAsFixed(6)),
        speedKmh: double.parse(speed.toStringAsFixed(1)),
        timestamp: pointTime,
        altitude: 8.0 + math.sin(i.toDouble() * 0.3) * 3.0,
        heading: currentHeading,
      ));
    }

    return points;
  }
}

