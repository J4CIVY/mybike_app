import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../proto/bike_log.dart';
import '../models/trip_gps_point.dart';

export '../models/trip_gps_point.dart';

enum BlePhase { idle, scanning, connecting, connected, reconnecting, disconnected }

class BikeTelemetry {
  final BikeLogMsg? bike;
  final DateTime at;
  BikeTelemetry(this.bike, this.at);
}

class TripData {
  final double distanceKm;
  final Duration duration;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int usedPercent;
  final double powerKw;

  const TripData({
    this.distanceKm = 0.0,
    this.duration = Duration.zero,
    this.avgSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.usedPercent = 0,
    this.powerKw = 0.0,
  });

  TripData copyWith({
    double? distanceKm,
    Duration? duration,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    int? usedPercent,
    double? powerKw,
  }) =>
      TripData(
        distanceKm: distanceKm ?? this.distanceKm,
        duration: duration ?? this.duration,
        avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
        maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
        usedPercent: usedPercent ?? this.usedPercent,
        powerKw: powerKw ?? this.powerKw,
      );
}

class TripRecord {
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final int durationSec;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int usedPercent;
  final double? startOdo;
  final double? endOdo;
  final List<TripGpsPoint> route;

  const TripRecord({
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.durationSec,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.usedPercent,
    this.startOdo,
    this.endOdo,
    this.route = const [],
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'distanceKm': distanceKm,
    'durationSec': durationSec,
    'avgSpeedKmh': avgSpeedKmh,
    'maxSpeedKmh': maxSpeedKmh,
    'usedPercent': usedPercent,
    if (startOdo != null) 'startOdo': startOdo,
    if (endOdo != null) 'endOdo': endOdo,
    if (route.isNotEmpty) 'route': route.map((e) => e.toJson()).toList(),
  };

  factory TripRecord.fromJson(Map<String, dynamic> json) => TripRecord(
    startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ?? DateTime.now(),
    endTime: DateTime.tryParse(json['endTime'] as String? ?? '') ?? DateTime.now(),
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
    durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
    avgSpeedKmh: (json['avgSpeedKmh'] as num?)?.toDouble() ?? 0.0,
    maxSpeedKmh: (json['maxSpeedKmh'] as num?)?.toDouble() ?? 0.0,
    usedPercent: (json['usedPercent'] as num?)?.toInt() ?? 0,
    startOdo: (json['startOdo'] as num?)?.toDouble(),
    endOdo: (json['endOdo'] as num?)?.toDouble(),
    route: (json['route'] as List?)
            ?.map((e) => TripGpsPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}

class LabIoResult {
  final String op;
  final String uuid;
  final bool ok;
  final List<int> payload;
  final List<int>? decrypted;
  final String? text;
  final String? parsed;
  final String? error;
  final int elapsedMs;

  const LabIoResult({
    required this.op,
    required this.uuid,
    required this.ok,
    this.payload = const [],
    this.decrypted,
    this.text,
    this.parsed,
    this.error,
    this.elapsedMs = 0,
  });
}

