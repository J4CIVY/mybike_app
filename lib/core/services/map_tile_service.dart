import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'offline_map_service.dart';

enum MapTileStyle {
  fastCdn,
  darkEv,
  cyclosm,
  osmStandard,
}

class MapTileService {
  /// Matriz de inversión y rotación de color para transformar mapa OSM en modo nocturno
  static const List<double> darkMatrix = <double>[
    -0.574, -1.430, -0.144, 0, 255,
    -0.426, -0.570, -0.144, 0, 255,
    -0.426, -1.430,  0.856, 0, 255,
     0,      0,      0,      1,   0,
  ];

  static TileLayer buildTileLayer({
    MapTileStyle style = MapTileStyle.fastCdn,
  }) {
    final offlineProvider = OfflineCacheTileProvider();

    switch (style) {
      case MapTileStyle.fastCdn:
        return TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.bskmt.app',
          maxZoom: 20,
          tileProvider: offlineProvider,
        );

      case MapTileStyle.darkEv:
        return TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.bskmt.app',
          maxZoom: 20,
          tileProvider: offlineProvider,
          tileBuilder: (context, tileWidget, tile) {
            return ColorFiltered(
              colorFilter: const ColorFilter.matrix(darkMatrix),
              child: tileWidget,
            );
          },
        );

      case MapTileStyle.cyclosm:
        return TileLayer(
          urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.bskmt.app',
          maxZoom: 20,
          tileProvider: offlineProvider,
        );

      case MapTileStyle.osmStandard:
        return TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.bskmt.app',
          maxZoom: 19,
          tileProvider: offlineProvider,
        );
    }
  }

  static String getStyleName(MapTileStyle style) {
    switch (style) {
      case MapTileStyle.fastCdn:
        return 'Carga Rápida (OSM-FR)';
      case MapTileStyle.darkEv:
        return 'Modo Nocturno EV';
      case MapTileStyle.cyclosm:
        return 'Carril Motos / 2 Ruedas';
      case MapTileStyle.osmStandard:
        return 'OpenStreetMap Estándar';
    }
  }

  static IconData getStyleIcon(MapTileStyle style) {
    switch (style) {
      case MapTileStyle.fastCdn:
        return Icons.bolt_rounded;
      case MapTileStyle.darkEv:
        return Icons.dark_mode_rounded;
      case MapTileStyle.cyclosm:
        return Icons.two_wheeler_rounded;
      case MapTileStyle.osmStandard:
        return Icons.public_rounded;
    }
  }
}
