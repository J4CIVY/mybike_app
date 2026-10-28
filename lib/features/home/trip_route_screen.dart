import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../core/ble/ble_controller.dart' show TripRecord, TripGpsPoint;
import '../../core/services/map_tile_service.dart';
import '../../core/services/trip_gps_tracker.dart';
import '../../ui/app_theme.dart';
import 'widgets/trip_route_info_sheet.dart';
import 'widgets/trip_route_map_overlays.dart';
import 'widgets/trip_route_map_view.dart';
import 'widgets/trip_route_playback_bar.dart';
import 'widgets/trip_route_search_modal.dart';
import 'widgets/trip_route_utils.dart';

class TripRouteScreen extends StatefulWidget {
  final TripRecord trip;
  final int tripIndex;
  final List<TripRecord>? allTrips;

  const TripRouteScreen({
    super.key,
    required this.trip,
    required this.tripIndex,
    this.allTrips,
  });

  @override
  State<TripRouteScreen> createState() => _TripRouteScreenState();
}

class _TripRouteScreenState extends State<TripRouteScreen> with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late TripRecord _currentTrip;
  late int _currentTripIndex;
  List<TripRecord> _allTrips = [];
  List<TripGpsPoint> _routePoints = [];

  int _currentIndex = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  Timer? _replayTimer;
  bool _followBike = true;
  bool _isLocating = false;
  LatLng? _myLocation;
  bool _isSimulated = false;

  MapTileStyle _tileStyle = MapTileStyle.fastCdn;
  bool _useNavPuckMarker = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentTrip = widget.trip;
    _currentTripIndex = widget.tripIndex;

    if (widget.allTrips != null && widget.allTrips!.isNotEmpty) {
      _allTrips = widget.allTrips!;
    } else {
      TripRouteUtils.loadTripHistoryFromPrefs().then((list) {
        if (mounted && list.isNotEmpty) setState(() => _allTrips = list);
      });
    }

    _initRouteData();
  }

  void _initRouteData() {
    if (_currentTrip.route.isNotEmpty) {
      _routePoints = TripGpsTracker.cleanAndSmoothRoute(_currentTrip.route);
      _isSimulated = false;
    } else {
      _routePoints = TripRouteUtils.generateSimulatedRoute(_currentTrip);
      _isSimulated = true;
    }
    _currentIndex = 0;
  }

  @override
  void dispose() {
    _replayTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _locateMe() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    final pos = await TripGpsTracker.instance.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isLocating = false);

    if (pos != null) {
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _myLocation = loc);
      _mapController.move(loc, 16.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la ubicación actual. Activa el GPS.'), backgroundColor: AppColors.red),
      );
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
      SnackBar(content: Text('Capa del mapa: ${MapTileService.getStyleName(_tileStyle)}'), duration: const Duration(seconds: 1)),
    );
  }

  void _togglePlayPause() => _isPlaying ? _stopPlayback() : _startPlayback();

  void _startPlayback() {
    if (_routePoints.isEmpty) return;
    if (_currentIndex >= _routePoints.length - 1) _currentIndex = 0;
    setState(() => _isPlaying = true);

    _replayTimer?.cancel();
    _replayTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentIndex += math.max(1, (_playbackSpeed * 1.5).round());
        if (_currentIndex >= _routePoints.length - 1) {
          _currentIndex = _routePoints.length - 1;
          _stopPlayback();
        }
      });

      if (_followBike && _routePoints.isNotEmpty && _currentIndex < _routePoints.length) {
        final cur = _routePoints[_currentIndex];
        _mapController.move(LatLng(cur.lat, cur.lng), _mapController.camera.zoom);
      }
    });
  }

  void _stopPlayback() {
    _replayTimer?.cancel();
    _replayTimer = null;
    if (mounted) setState(() => _isPlaying = false);
  }

  void _seekTo(int index) {
    if (_routePoints.isEmpty) return;
    final clamped = index.clamp(0, _routePoints.length - 1);
    setState(() => _currentIndex = clamped);
    final cur = _routePoints[clamped];
    if (_followBike) _mapController.move(LatLng(cur.lat, cur.lng), _mapController.camera.zoom);
  }

  void _cyclePlaybackSpeed() {
    setState(() {
      _playbackSpeed = _playbackSpeed == 1.0 ? 2.0 : (_playbackSpeed == 2.0 ? 4.0 : (_playbackSpeed == 4.0 ? 8.0 : 1.0));
    });
    if (_isPlaying) _startPlayback();
  }

  @override
  Widget build(BuildContext context) {
    final hasPoints = _routePoints.isNotEmpty;
    final currentPoint = hasPoints ? _routePoints[_currentIndex] : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          TripRouteMapView(
            mapController: _mapController,
            tileStyle: _tileStyle,
            routePoints: _routePoints,
            myLocation: _myLocation,
            currentPoint: currentPoint,
            heading: TripRouteUtils.getReplayHeading(_routePoints, _currentIndex),
            useNavPuckMarker: _useNavPuckMarker,
            onToggleMarkerStyle: () => setState(() => _useNavPuckMarker = !_useNavPuckMarker),
            onMapReady: () => Future.delayed(const Duration(milliseconds: 300), () => TripRouteUtils.fitRouteBounds(_mapController, _routePoints)),
          ),

          TripRouteMapOverlays(
            currentTripIndex: _currentTripIndex,
            currentTrip: _currentTrip,
            isLocating: _isLocating,
            tileStyle: _tileStyle,
            mapController: _mapController,
            onOpenTripSearch: () {
              TripRouteSearchModal.show(
                context: context,
                tripsToDisplay: _allTrips.isNotEmpty ? _allTrips : [_currentTrip],
                currentTrip: _currentTrip,
                onSelectTrip: (trip, index) {
                  setState(() {
                    _currentTrip = trip;
                    _currentTripIndex = index;
                    _initRouteData();
                  });
                  Future.delayed(const Duration(milliseconds: 200), () => TripRouteUtils.fitRouteBounds(_mapController, _routePoints));
                },
              );
            },
            onShowTripInfo: () {
              TripRouteInfoSheet.show(context: context, trip: _currentTrip, routePointsCount: _routePoints.length, isSimulated: _isSimulated);
            },
            onFitRouteBounds: () => TripRouteUtils.fitRouteBounds(_mapController, _routePoints),
            onLocateMe: _locateMe,
            onCycleTileStyle: _cycleTileStyle,
          ),

          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: TripRoutePlaybackBar(
              routePoints: _routePoints,
              currentIndex: _currentIndex,
              isPlaying: _isPlaying,
              playbackSpeed: _playbackSpeed,
              followBike: _followBike,
              onSeekTo: _seekTo,
              onTogglePlayPause: _togglePlayPause,
              onCyclePlaybackSpeed: _cyclePlaybackSpeed,
              onToggleFollowBike: () {
                setState(() => _followBike = !_followBike);
                if (_followBike && currentPoint != null) {
                  _mapController.move(LatLng(currentPoint.lat, currentPoint.lng), _mapController.camera.zoom);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
