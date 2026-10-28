import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/ble/ble_controller.dart' show TripRecord, TripGpsPoint;

class TripRouteUtils {
  static Color getContinuousSpeedColor(double speedKmh) {
    if (speedKmh <= 15.0) {
      final t = (speedKmh / 15.0).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFF06B6D4), const Color(0xFF10B981), t)!;
    } else if (speedKmh <= 35.0) {
      final t = ((speedKmh - 15.0) / 20.0).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFF10B981), const Color(0xFF0EA5E9), t)!;
    } else if (speedKmh <= 55.0) {
      final t = ((speedKmh - 35.0) / 20.0).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFFF59E0B), const Color(0xFFF97316), t)!;
    } else {
      final t = ((speedKmh - 55.0) / 30.0).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFFF97316), const Color(0xFFEF4444), t)!;
    }
  }

  static String getSpeedLabel(double speedKmh) {
    if (speedKmh < 5.0) return 'DETENIDO';
    if (speedKmh < 20.0) return 'MARCHA LENTA';
    if (speedKmh < 40.0) return 'VELOCIDAD MEDIA';
    if (speedKmh < 60.0) return 'ACELERACIÓN';
    return 'ALTA VELOCIDAD';
  }

  static List<TripGpsPoint> generateSimulatedRoute(TripRecord trip) {
    const startLat = 10.7719;
    const startLng = 106.7195;
    final totalKm = trip.distanceKm > 0 ? trip.distanceKm : 3.5;
    final count = math.max(30, (totalKm * 15).round());

    final list = <TripGpsPoint>[];
    double curLat = startLat;
    double curLng = startLng;
    final startTime = trip.startTime;
    final durationSec = trip.durationSec > 0 ? trip.durationSec : 600;
    final timeStep = durationSec / count;

    for (int i = 0; i < count; i++) {
      final t = i / (count - 1);
      final speed = math.sin(t * math.pi) * (trip.maxSpeedKmh > 0 ? trip.maxSpeedKmh : 48.0);
      curLat += 0.00035 * (1 + 0.3 * math.sin(i * 0.6));
      curLng += 0.00028 * (1 + 0.4 * math.cos(i * 0.8));

      list.add(
        TripGpsPoint(
          lat: curLat,
          lng: curLng,
          speedKmh: speed.clamp(0.0, 90.0),
          heading: (45.0 + math.sin(i * 0.3) * 30.0).clamp(0.0, 360.0),
          altitude: 12.0 + math.sin(i * 0.2) * 4.0,
          timestamp: startTime.add(Duration(seconds: (i * timeStep).round())),
        ),
      );
    }
    return list;
  }

  static Future<List<TripRecord>> loadTripHistoryFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('trip_history_v1');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return (jsonDecode(jsonStr) as List)
            .map((e) => TripRecord.fromJson(e as Map<String, dynamic>))
            .where((e) => e.distanceKm >= 1.0)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static double getReplayHeading(List<TripGpsPoint> points, int currentIndex) {
    if (points.length < 2) return 0.0;
    final idx = currentIndex.clamp(0, points.length - 1);
    final p1 = idx < points.length - 1 ? points[idx] : points[idx - 1];
    final p2 = idx < points.length - 1 ? points[idx + 1] : points[idx];
    final dLng = (p2.lng - p1.lng) * (math.pi / 180.0);
    final lat1 = p1.lat * (math.pi / 180.0);
    final lat2 = p2.lat * (math.pi / 180.0);
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return math.atan2(y, x);
  }

  static void fitRouteBounds(MapController mapController, List<TripGpsPoint> points) {
    if (points.isEmpty) return;
    final latLngs = points.map((p) => LatLng(p.lat, p.lng)).toList();
    final bounds = LatLngBounds.fromPoints(latLngs);
    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(top: 100, bottom: 260, left: 40, right: 40),
      ),
    );
  }
}
