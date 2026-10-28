import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/offline_map_models.dart';
import 'offline_map_service.dart';

/// Manejador de descargas por lotes de teselas de mapas para uso offline.
class OfflineMapDownloader {
  final OfflineMapService _service;
  bool _isDownloading = false;
  bool _cancelRequested = false;
  bool _pauseRequested = false;

  OfflineMapDownloader(this._service);

  bool get isDownloading => _isDownloading;

  Future<File> getTaskFile() async {
    final dir = await _service.getCacheDirectory();
    return File('${dir.path}/download_task.json');
  }

  Future<void> saveTaskState({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    required String regionName,
    required int totalTiles,
  }) async {
    try {
      final file = await getTaskFile();
      final map = {
        'regionName': regionName,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
        'north': bounds.north,
        'south': bounds.south,
        'east': bounds.east,
        'west': bounds.west,
        'totalTiles': totalTiles,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(jsonEncode(map));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getPendingTask() async {
    try {
      final file = await getTaskFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearPendingTask() async {
    try {
      final file = await getTaskFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> cancelDownload() async {
    _cancelRequested = true;
    _pauseRequested = false;
    await clearPendingTask();
    _service.progressNotifier.value = const DownloadProgress();
  }

  void pauseDownload() {
    _pauseRequested = true;
  }

  Future<void> resumeDownload({void Function(DownloadProgress progress)? onProgress}) async {
    final task = await getPendingTask();
    if (task == null) return;

    final bounds = LatLngBounds(
      LatLng((task['south'] as num).toDouble(), (task['west'] as num).toDouble()),
      LatLng((task['north'] as num).toDouble(), (task['east'] as num).toDouble()),
    );
    final minZoom = (task['minZoom'] as num).toInt();
    final maxZoom = (task['maxZoom'] as num).toInt();
    final regionName = (task['regionName'] as String?) ?? 'Mapa';

    await downloadRegion(
      bounds: bounds,
      minZoom: minZoom,
      maxZoom: maxZoom,
      regionName: regionName,
      onProgress: onProgress,
    );
  }

  Future<void> downloadRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    String regionName = 'Mapa offline',
    String urlTemplate = 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
    List<String> subdomains = const ['a', 'b', 'c'],
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    if (_isDownloading) return;
    _isDownloading = true;
    _cancelRequested = false;
    _pauseRequested = false;

    final tiles = _service.calculateTileList(bounds: bounds, minZoom: minZoom, maxZoom: maxZoom);
    final total = tiles.length;
    int current = 0;
    int totalBytes = 0;

    await saveTaskState(
      bounds: bounds,
      minZoom: minZoom,
      maxZoom: maxZoom,
      regionName: regionName,
      totalTiles: total,
    );

    void notify(DownloadProgress p) {
      _service.progressNotifier.value = p;
      onProgress?.call(p);
    }

    notify(DownloadProgress(current: 0, total: total, bytes: 0, isRunning: true, regionName: regionName));

    final subLen = subdomains.length;
    int subIndex = 0;
    const concurrency = 4;
    int index = 0;

    Future<void> worker() async {
      while (index < tiles.length && !_cancelRequested && !_pauseRequested) {
        final curIndex = index++;
        final tile = tiles[curIndex];

        final file = await _service.getTileFile(tile.z, tile.x, tile.y);
        if (await file.exists()) {
          current++;
          totalBytes += await file.length();
          notify(DownloadProgress(
            current: current,
            total: total,
            bytes: totalBytes,
            isRunning: true,
            regionName: regionName,
          ));
          continue;
        }

        final sub = subdomains[subIndex++ % subLen];
        final url = urlTemplate
            .replaceAll('{s}', sub)
            .replaceAll('{z}', '${tile.z}')
            .replaceAll('{x}', '${tile.x}')
            .replaceAll('{y}', '${tile.y}');

        try {
          final res = await http.get(
            Uri.parse(url),
            headers: {'User-Agent': 'DatBikeApp/2.6.4 (offline-cache)'},
          ).timeout(const Duration(seconds: 8));

          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
            await file.parent.create(recursive: true);
            await file.writeAsBytes(res.bodyBytes);
            totalBytes += res.bodyBytes.length;
          }
        } catch (_) {}

        current++;
        notify(DownloadProgress(
          current: current,
          total: total,
          bytes: totalBytes,
          isRunning: true,
          regionName: regionName,
        ));
      }
    }

    final workers = List.generate(concurrency, (_) => worker());
    await Future.wait(workers);

    _isDownloading = false;

    if (_cancelRequested) {
      await clearPendingTask();
      notify(DownloadProgress(
        current: current,
        total: total,
        bytes: totalBytes,
        isRunning: false,
        isPaused: false,
        isCompleted: false,
        regionName: regionName,
      ));
    } else if (_pauseRequested) {
      notify(DownloadProgress(
        current: current,
        total: total,
        bytes: totalBytes,
        isRunning: false,
        isPaused: true,
        isCompleted: false,
        regionName: regionName,
      ));
    } else {
      await clearPendingTask();
      notify(DownloadProgress(
        current: current,
        total: total,
        bytes: totalBytes,
        isRunning: false,
        isPaused: false,
        isCompleted: true,
        regionName: regionName,
      ));
    }
  }
}

