import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import 'offline_map_service.dart';

/// Proveedor de teselas con caché local en disco.
/// Carga primero desde almacenamiento local (0ms latencia, offline).
/// Si no existe, descarga de la red y almacena en caché para el futuro.
class OfflineCacheTileProvider extends TileProvider {
  OfflineCacheTileProvider({super.headers});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return OfflineTileImageProvider(
      coordinates: coordinates,
      options: options,
      url: url,
      headers: headers,
    );
  }
}

class OfflineTileImageProvider extends ImageProvider<OfflineTileImageProvider> {
  final TileCoordinates coordinates;
  final TileLayer options;
  final String url;
  final Map<String, String>? headers;

  const OfflineTileImageProvider({
    required this.coordinates,
    required this.options,
    required this.url,
    this.headers,
  });

  @override
  Future<OfflineTileImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<OfflineTileImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(OfflineTileImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      informationCollector: () => [
        DiagnosticsProperty<String>('URL', url),
        DiagnosticsProperty<TileCoordinates>('Coordinates', coordinates),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(OfflineTileImageProvider key, ImageDecoderCallback decode) async {
    final file = await OfflineMapService.instance.getTileFile(
      coordinates.z,
      coordinates.x,
      coordinates.y,
    );

    if (await file.exists()) {
      try {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
          return await decode(buffer);
        }
      } catch (_) {}
    }

    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        unawaited(
          file.parent.create(recursive: true).then((_) {
            file.writeAsBytes(response.bodyBytes);
          }).catchError((_) {}),
        );

        final buffer = await ui.ImmutableBuffer.fromUint8List(response.bodyBytes);
        return await decode(buffer);
      }
    } catch (_) {}

    final transparentPng = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
    final buffer = await ui.ImmutableBuffer.fromUint8List(transparentPng);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is OfflineTileImageProvider &&
        other.coordinates == coordinates &&
        other.url == url;
  }

  @override
  int get hashCode => Object.hash(coordinates, url);
}

