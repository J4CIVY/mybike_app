import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import '../models/offline_map_models.dart';
import 'offline_map_downloader.dart';

export '../models/offline_map_models.dart';
export 'offline_cache_tile_provider.dart';

/// Servicio para gestionar almacenamiento y descarga de mapas offline.
class OfflineMapService {
  OfflineMapService._() {
    _downloader = OfflineMapDownloader(this);
  }
  static final OfflineMapService instance = OfflineMapService._();

  late final OfflineMapDownloader _downloader;
  Directory? _cacheDir;

  final ValueNotifier<DownloadProgress> progressNotifier =
      ValueNotifier<DownloadProgress>(const DownloadProgress());

  bool get isDownloading => _downloader.isDownloading;

  Future<Directory> getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/offline_map_tiles');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  Future<File> getTileFile(int z, int x, int y) async {
    final dir = await getCacheDirectory();
    return File('${dir.path}/${z}_${x}_$y.png');
  }

  Future<bool> hasTile(int z, int x, int y) async {
    final file = await getTileFile(z, x, y);
    return file.exists();
  }

  Future<({int tileCount, int totalBytes, String sizeText})>
  getCacheStats() async {
    try {
      final dir = await getCacheDirectory();
      int count = 0;
      int bytes = 0;
      if (await dir.exists()) {
        final entities = dir.listSync(followLinks: false);
        for (final entity in entities) {
          if (entity is File && entity.path.endsWith('.png')) {
            count++;
            bytes += entity.lengthSync();
          }
        }
      }
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      return (tileCount: count, totalBytes: bytes, sizeText: '$mb MB');
    } catch (_) {
      return (tileCount: 0, totalBytes: 0, sizeText: '0.0 MB');
    }
  }

  Future<void> clearCache() async {
    try {
      final dir = await getCacheDirectory();
      if (await dir.exists()) {
        final entities = dir.listSync(followLinks: false);
        for (final entity in entities) {
          if (entity is File) {
            try {
              entity.deleteSync();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  static int lon2tileX(double lon, int z) {
    return ((lon + 180.0) / 360.0 * (1 << z)).floor();
  }

  static int lat2tileY(double lat, int z) {
    final rad = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(rad) + 1.0 / math.cos(rad)) / math.pi) /
            2.0 *
            (1 << z))
        .floor();
  }

  static List<OfflineRegionPreset> getPresets() {
    return [
      OfflineRegionPreset(
        id: 'bogota',
        name: 'Bogotá & Sabana',
        description: 'Centro, Chapinero, Usaquén, Chía',
        icon: Icons.location_city_rounded,
        bounds: LatLngBounds(
          const LatLng(4.48, -74.25),
          const LatLng(4.85, -74.00),
        ),
      ),
      OfflineRegionPreset(
        id: 'medellin',
        name: 'Medellín & Valle de Aburrá',
        description: 'Poblado, Laureles, Bello, Envigado',
        icon: Icons.account_balance_rounded,
        bounds: LatLngBounds(
          const LatLng(6.15, -75.65),
          const LatLng(6.36, -75.50),
        ),
      ),
      OfflineRegionPreset(
        id: 'cali',
        name: 'Cali & Yumbo',
        description: 'Granada, San Antonio, Ciudad Jardín',
        icon: Icons.beach_access_rounded,
        bounds: LatLngBounds(
          const LatLng(3.30, -76.60),
          const LatLng(3.55, -76.45),
        ),
      ),
    ];
  }

  static LatLngBounds createRadiusBounds(LatLng center, double radiusKm) {
    const latKm = 111.0;
    final deltaLat = radiusKm / latKm;
    final deltaLng =
        radiusKm / (latKm * math.cos(center.latitude * math.pi / 180.0));
    return LatLngBounds(
      LatLng(center.latitude - deltaLat, center.longitude - deltaLng),
      LatLng(center.latitude + deltaLat, center.longitude + deltaLng),
    );
  }

  List<({int z, int x, int y})> calculateTileList({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
  }) {
    final list = <({int z, int x, int y})>[];
    for (int z = minZoom; z <= maxZoom; z++) {
      final minX = lon2tileX(bounds.west, z);
      final maxX = lon2tileX(bounds.east, z);
      final minY = lat2tileY(bounds.north, z);
      final maxY = lat2tileY(bounds.south, z);

      final startX = math.min(minX, maxX);
      final endX = math.max(minX, maxX);
      final startY = math.min(minY, maxY);
      final endY = math.max(minY, maxY);

      for (int x = startX; x <= endX; x++) {
        for (int y = startY; y <= endY; y++) {
          list.add((z: z, x: x, y: y));
        }
      }
    }
    return list;
  }

  Future<void> cancelDownload() => _downloader.cancelDownload();

  void pauseDownload() => _downloader.pauseDownload();

  Future<Map<String, dynamic>?> getPendingTask() =>
      _downloader.getPendingTask();

  Future<void> clearPendingTask() => _downloader.clearPendingTask();

  Future<void> resumeDownload({
    void Function(DownloadProgress progress)? onProgress,
  }) => _downloader.resumeDownload(onProgress: onProgress);

  Future<void> downloadRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    String regionName = 'Mapa offline',
    String urlTemplate =
        'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
    List<String> subdomains = const ['a', 'b', 'c'],
    void Function(DownloadProgress progress)? onProgress,
  }) => _downloader.downloadRegion(
    bounds: bounds,
    minZoom: minZoom,
    maxZoom: maxZoom,
    regionName: regionName,
    urlTemplate: urlTemplate,
    subdomains: subdomains,
    onProgress: onProgress,
  );
}
