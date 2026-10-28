import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/offline_map_service.dart';
import '../../../core/services/trip_gps_tracker.dart';
import '../../../ui/app_theme.dart';
import 'offline_map_action_buttons.dart';
import 'offline_map_cache_card.dart';
import 'offline_map_clear_dialog.dart';
import 'offline_map_coverage_selector.dart';
import 'offline_map_pending_card.dart';
import 'offline_map_progress_card.dart';
import 'offline_map_sheet_header.dart';

/// Hoja modal para seleccionar zona y descargar mapas sin conexión.
class OfflineMapSheet extends StatefulWidget {
  final LatLngBounds? currentMapBounds;

  const OfflineMapSheet({super.key, this.currentMapBounds});

  static Future<void> show(BuildContext context, {LatLngBounds? currentMapBounds}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OfflineMapSheet(currentMapBounds: currentMapBounds),
    );
  }

  @override
  State<OfflineMapSheet> createState() => _OfflineMapSheetState();
}

class _OfflineMapSheetState extends State<OfflineMapSheet> {
  final _service = OfflineMapService.instance;

  String _selectedRegionKey = 'my_location_5km';
  int _minZoom = 13;
  int _maxZoom = 15;

  LatLng? _myLocation;
  ({int tileCount, int totalBytes, String sizeText}) _cacheStats =
      (tileCount: 0, totalBytes: 0, sizeText: '0.0 MB');

  Map<String, dynamic>? _pendingTask;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final stats = await _service.getCacheStats();
    final pos = await TripGpsTracker.instance.getCurrentLocation();
    final task = await _service.getPendingTask();
    if (!mounted) return;
    setState(() {
      _cacheStats = stats;
      if (pos != null) {
        _myLocation = LatLng(pos.latitude, pos.longitude);
      }
      _pendingTask = task;
      _isLoadingStats = false;
    });
  }

  String _getSelectedRegionName() {
    if (_selectedRegionKey == 'my_location_5km') {
      return 'Alrededor de la moto (Radio 5 km)';
    }
    if (_selectedRegionKey == 'my_location_10km') {
      return 'Alrededor de la moto (Radio 10 km)';
    }
    return 'Área visible en pantalla';
  }

  LatLngBounds _getSelectedBounds() {
    final center = _myLocation ?? const LatLng(4.6097, -74.0817);
    if (_selectedRegionKey == 'my_location_5km') {
      return OfflineMapService.createRadiusBounds(center, 5.0);
    }
    if (_selectedRegionKey == 'my_location_10km') {
      return OfflineMapService.createRadiusBounds(center, 10.0);
    }
    if (_selectedRegionKey == 'current_viewport' && widget.currentMapBounds != null) {
      return widget.currentMapBounds!;
    }
    return OfflineMapService.createRadiusBounds(center, 5.0);
  }

  int _calculateEstimatedTiles() {
    return _service.calculateTileList(
      bounds: _getSelectedBounds(),
      minZoom: _minZoom,
      maxZoom: _maxZoom,
    ).length;
  }

  String _estimateSizeText(int tileCount) {
    return '~${((tileCount * 25) / 1024.0).toStringAsFixed(1)} MB';
  }

  Future<void> _startDownload() async {
    await _service.downloadRegion(
      bounds: _getSelectedBounds(),
      minZoom: _minZoom,
      maxZoom: _maxZoom,
      regionName: _getSelectedRegionName(),
    );
    final stats = await _service.getCacheStats();
    final task = await _service.getPendingTask();
    if (!mounted) return;
    setState(() {
      _cacheStats = stats;
      _pendingTask = task;
    });
  }

  Future<void> _resumeDownload() async {
    await _service.resumeDownload();
    final stats = await _service.getCacheStats();
    final task = await _service.getPendingTask();
    if (!mounted) return;
    setState(() {
      _cacheStats = stats;
      _pendingTask = task;
    });
  }

  Future<void> _clearPendingTask() async {
    await _service.clearPendingTask();
    setState(() => _pendingTask = null);
  }

  Future<void> _clearCache() async {
    final confirm = await OfflineMapClearDialog.show(
      context,
      tileCount: _cacheStats.tileCount,
      sizeText: _cacheStats.sizeText,
    );

    if (confirm == true) {
      await _service.clearCache();
      final stats = await _service.getCacheStats();
      if (!mounted) return;
      setState(() => _cacheStats = stats);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se ha limpiado la caché de mapas sin conexión.'),
          backgroundColor: AppColors.tertiary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DownloadProgress>(
      valueListenable: _service.progressNotifier,
      builder: (context, progress, _) {
        final isDownloading = progress.isRunning;
        final estTiles = _calculateEstimatedTiles();
        final estSize = _estimateSizeText(estTiles);

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          decoration: const BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.panelBorderBright, width: 1)),
            boxShadow: AppColors.modalShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OfflineMapSheetHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    if (_pendingTask != null && !isDownloading) ...[
                      OfflineMapPendingCard(
                        pendingTask: _pendingTask!,
                        onResume: _resumeDownload,
                        onDiscard: _clearPendingTask,
                      ),
                      const SizedBox(height: 14),
                    ],
                    OfflineMapCacheCard(
                      cacheStats: _cacheStats,
                      isLoadingStats: _isLoadingStats,
                      isDownloading: isDownloading,
                      onClearCache: _clearCache,
                    ),
                    const SizedBox(height: 16),
                    OfflineMapCoverageSelector(
                      selectedRegionKey: _selectedRegionKey,
                      myLocation: _myLocation,
                      hasCurrentMapBounds: widget.currentMapBounds != null,
                      maxZoom: _maxZoom,
                      onSelectRegion: (k) => setState(() => _selectedRegionKey = k),
                      onSelectMaxZoom: (z) => setState(() {
                        _minZoom = 13;
                        _maxZoom = z;
                      }),
                    ),
                    const SizedBox(height: 16),
                    if (isDownloading || progress.isCompleted || progress.isPaused) ...[
                      OfflineMapProgressCard(progress: progress),
                      const SizedBox(height: 14),
                    ],
                    OfflineMapActionButtons(
                      progress: progress,
                      estimatedSizeText: estSize,
                      onStartDownload: _startDownload,
                      onResumeDownload: _resumeDownload,
                      onPauseDownload: () => _service.pauseDownload(),
                      onCancelDownload: () => _service.cancelDownload(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
