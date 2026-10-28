import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/trip_gps_point.dart';
import '../../../core/services/map_tile_service.dart';
import '../../../core/services/trip_gps_tracker.dart';
import '../../../ui/app_theme.dart';
import 'cockpit_map_download_banner.dart';
import 'cockpit_map_glass_button.dart';
import 'cockpit_map_header.dart';
import 'cockpit_map_marker.dart';
import 'cockpit_map_telemetry_bar.dart';
import 'offline_map_sheet.dart';

/// Mapa de conducción en tiempo real para el tablero.
class CockpitLiveMap extends StatefulWidget {
  final double currentSpeedKmh;
  final VoidCallback? onExpandFullScreen;

  const CockpitLiveMap({
    super.key,
    required this.currentSpeedKmh,
    this.onExpandFullScreen,
  });

  @override
  State<CockpitLiveMap> createState() => _CockpitLiveMapState();
}

class _CockpitLiveMapState extends State<CockpitLiveMap> {
  late final MapController _mapController;
  StreamSubscription<TripGpsPoint>? _pointSub;
  List<TripGpsPoint> _liveRoute = [];

  MapTileStyle _tileStyle = MapTileStyle.fastCdn;
  bool _followBike = true;
  bool _isLocating = false;
  LatLng? _myLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _liveRoute = TripGpsTracker.instance.getCurrentRoute();

    _pointSub = TripGpsTracker.instance.onPointRecorded.listen((newPoint) {
      if (!mounted) return;
      setState(() {
        _liveRoute.add(newPoint);
        _myLocation = LatLng(newPoint.lat, newPoint.lng);
      });
      if (_followBike) {
        _mapController.move(LatLng(newPoint.lat, newPoint.lng), _mapController.camera.zoom);
      }
    });

    _locateMe(moveCamera: false);
  }

  @override
  void dispose() {
    _pointSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _locateMe({bool moveCamera = true}) async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    final pos = await TripGpsTracker.instance.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isLocating = false);

    if (pos != null) {
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _myLocation = loc);
      if (moveCamera) {
        _mapController.move(loc, 16.5);
      }
    }
  }

  void _cycleTileStyle() {
    setState(() {
      const styles = MapTileStyle.values;
      final nextIndex = (styles.indexOf(_tileStyle) + 1) % styles.length;
      _tileStyle = styles[nextIndex];
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Capa del mapa: ${MapTileService.getStyleName(_tileStyle)} (100% Gratis)'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRoute = _liveRoute.isNotEmpty;
    final lastPoint = hasRoute ? _liveRoute.last : null;
    final isTracking = TripGpsTracker.instance.isTracking;

    final centerCoord = _myLocation ??
        (lastPoint != null ? LatLng(lastPoint.lat, lastPoint.lng) : const LatLng(4.6097, -74.0817));

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.panelBorderBright, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerCoord,
              initialZoom: 16.0,
            ),
            children: [
              MapTileService.buildTileLayer(style: _tileStyle),
              if (hasRoute) ...[
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _liveRoute.map((p) => LatLng(p.lat, p.lng)).toList(),
                      strokeWidth: 8.0,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                      color: AppColors.primary.withValues(alpha: 0.22),
                    ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    for (int i = 0; i < _liveRoute.length - 1; i++)
                      Polyline(
                        points: [
                          LatLng(_liveRoute[i].lat, _liveRoute[i].lng),
                          LatLng(_liveRoute[i + 1].lat, _liveRoute[i + 1].lng),
                        ],
                        strokeWidth: 5.0,
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                        gradientColors: [
                          getContinuousSpeedColor(_liveRoute[i].speedKmh),
                          getContinuousSpeedColor(_liveRoute[i + 1].speedKmh),
                        ],
                      ),
                  ],
                ),
              ],
              MarkerLayer(
                markers: [
                  if (_myLocation != null || lastPoint != null)
                    Marker(
                      point: _myLocation ?? LatLng(lastPoint!.lat, lastPoint.lng),
                      width: 52,
                      height: 52,
                      child: CockpitMapMarker(
                        speedKmh: widget.currentSpeedKmh,
                        heading: lastPoint?.heading ?? 0.0,
                      ),
                    ),
                ],
              ),
            ],
          ),
          CockpitMapHeader(
            isTracking: isTracking,
            tileStyle: _tileStyle,
            onCycleTileStyle: _cycleTileStyle,
            onOpenOfflineSheet: () {
              OfflineMapSheet.show(
                context,
                currentMapBounds: _mapController.camera.visibleBounds,
              );
            },
            onExpandFullScreen: widget.onExpandFullScreen,
          ),
          CockpitMapDownloadBanner(mapController: _mapController),
          Positioned(
            bottom: 48,
            right: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CockpitMapGlassButton(
                  icon: Icons.my_location_rounded,
                  iconColor: _isLocating ? AppColors.primary : AppColors.textDim,
                  isActive: _isLocating,
                  tooltip: 'Mi ubicación',
                  onTap: () => _locateMe(moveCamera: true),
                ),
                const SizedBox(height: 6),
                CockpitMapGlassButton(
                  icon: Icons.navigation_rounded,
                  iconColor: _followBike ? AppColors.primary : AppColors.textDim,
                  isActive: _followBike,
                  tooltip: _followBike ? 'Fijado en la moto' : 'Rotación libre',
                  onTap: () {
                    setState(() => _followBike = !_followBike);
                    if (_followBike && (_myLocation != null || lastPoint != null)) {
                      _mapController.move(
                        _myLocation ?? LatLng(lastPoint!.lat, lastPoint.lng),
                        _mapController.camera.zoom,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          CockpitMapTelemetryBar(
            currentSpeedKmh: widget.currentSpeedKmh,
            myLocation: _myLocation,
            routePointsCount: _liveRoute.length,
          ),
        ],
      ),
    );
  }
}
