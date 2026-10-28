import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/ble/ble_controller.dart' show TripGpsPoint;
import '../../../core/services/map_tile_service.dart';
import '../../../ui/app_theme.dart';
import 'trip_route_bike_marker.dart';
import 'trip_route_pins.dart';
import 'trip_route_utils.dart';

class TripRouteMapView extends StatelessWidget {
  final MapController mapController;
  final MapTileStyle tileStyle;
  final List<TripGpsPoint> routePoints;
  final LatLng? myLocation;
  final TripGpsPoint? currentPoint;
  final double heading;
  final bool useNavPuckMarker;
  final VoidCallback onToggleMarkerStyle;
  final VoidCallback onMapReady;

  const TripRouteMapView({
    super.key,
    required this.mapController,
    required this.tileStyle,
    required this.routePoints,
    required this.myLocation,
    required this.currentPoint,
    required this.heading,
    required this.useNavPuckMarker,
    required this.onToggleMarkerStyle,
    required this.onMapReady,
  });

  @override
  Widget build(BuildContext context) {
    final hasPoints = routePoints.isNotEmpty;
    final initialCenter = hasPoints
        ? LatLng(routePoints.first.lat, routePoints.first.lng)
        : const LatLng(10.7719, 106.7195);

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15.0,
        onMapReady: onMapReady,
      ),
      children: [
        MapTileService.buildTileLayer(style: tileStyle),
        if (hasPoints) ...[
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints.map((p) => LatLng(p.lat, p.lng)).toList(),
                strokeWidth: 8.0,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
                color: AppColors.primary.withValues(alpha: 0.20),
              ),
            ],
          ),
          PolylineLayer(
            polylines: [
              for (int i = 0; i < routePoints.length - 1; i++)
                Polyline(
                  points: [
                    LatLng(routePoints[i].lat, routePoints[i].lng),
                    LatLng(routePoints[i + 1].lat, routePoints[i + 1].lng),
                  ],
                  strokeWidth: 5.5,
                  strokeCap: StrokeCap.round,
                  strokeJoin: StrokeJoin.round,
                  gradientColors: [
                    TripRouteUtils.getContinuousSpeedColor(routePoints[i].speedKmh),
                    TripRouteUtils.getContinuousSpeedColor(routePoints[i + 1].speedKmh),
                  ],
                ),
            ],
          ),
        ],
        MarkerLayer(
          markers: [
            if (myLocation != null)
              Marker(
                point: myLocation!,
                width: 44,
                height: 44,
                child: const TripRouteMyLocationMarker(),
              ),
            if (hasPoints) ...[
              Marker(
                point: LatLng(routePoints.first.lat, routePoints.first.lng),
                width: 32,
                height: 32,
                child: const TripRouteStartEndPin(label: 'A', isStart: true),
              ),
              Marker(
                point: LatLng(routePoints.last.lat, routePoints.last.lng),
                width: 32,
                height: 32,
                child: const TripRouteStartEndPin(label: 'B', isStart: false),
              ),
              if (currentPoint != null)
                Marker(
                  point: LatLng(currentPoint!.lat, currentPoint!.lng),
                  width: 90,
                  height: 90,
                  alignment: Alignment.center,
                  child: TripRouteBikeMarker(
                    point: currentPoint!,
                    heading: heading,
                    useNavPuckMarker: useNavPuckMarker,
                    onToggleMarkerStyle: onToggleMarkerStyle,
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

