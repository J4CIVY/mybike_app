import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Información de progreso de descarga del mapa offline.
class DownloadProgress {
  final int current;
  final int total;
  final int bytes;
  final bool isRunning;
  final bool isPaused;
  final bool isCompleted;
  final String? regionName;
  final String? error;

  const DownloadProgress({
    this.current = 0,
    this.total = 0,
    this.bytes = 0,
    this.isRunning = false,
    this.isPaused = false,
    this.isCompleted = false,
    this.regionName,
    this.error,
  });

  double get percent => total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
  int get percentInt => (percent * 100).round();
  String get sizeMbText => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Región predefinida para descarga offline.
class OfflineRegionPreset {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final LatLngBounds bounds;

  const OfflineRegionPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.bounds,
  });
}

