import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../ui/app_theme.dart';
import 'offline_map_options.dart';

class OfflineMapCoverageSelector extends StatelessWidget {
  final String selectedRegionKey;
  final LatLng? myLocation;
  final bool hasCurrentMapBounds;
  final int maxZoom;
  final ValueChanged<String> onSelectRegion;
  final ValueChanged<int> onSelectMaxZoom;

  const OfflineMapCoverageSelector({
    super.key,
    required this.selectedRegionKey,
    required this.myLocation,
    required this.hasCurrentMapBounds,
    required this.maxZoom,
    required this.onSelectRegion,
    required this.onSelectMaxZoom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECCIONAR ZONA DE COBERTURA',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textDim,
          ),
        ),
        const SizedBox(height: 8),
        OfflineMapRegionOption(
          keyId: 'my_location_5km',
          icon: Icons.my_location_rounded,
          title: 'Alrededor de la moto (5 km)',
          subtitle: myLocation != null
              ? 'Coordenadas: ${myLocation!.latitude.toStringAsFixed(3)}°, ${myLocation!.longitude.toStringAsFixed(3)}°'
              : 'Zona habitual del vehículo',
          isSelected: selectedRegionKey == 'my_location_5km',
          onTap: () => onSelectRegion('my_location_5km'),
        ),
        OfflineMapRegionOption(
          keyId: 'my_location_10km',
          icon: Icons.radar_rounded,
          title: 'Alrededor de la moto (10 km)',
          subtitle: 'Cobertura extendida de ciudad y vías periféricas',
          isSelected: selectedRegionKey == 'my_location_10km',
          onTap: () => onSelectRegion('my_location_10km'),
        ),
        OfflineMapRegionOption(
          keyId: 'current_viewport',
          icon: Icons.crop_free_rounded,
          title: 'Área visible en pantalla',
          subtitle: hasCurrentMapBounds ? 'Según el encuadre actual' : 'Centro del mapa',
          isSelected: selectedRegionKey == 'current_viewport',
          onTap: () => onSelectRegion('current_viewport'),
        ),
        const SizedBox(height: 16),
        Text(
          'NIVEL DE DETALLE',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textDim,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OfflineMapZoomOption(
                title: 'Estándar',
                subtitle: 'Avenidas principales (Z13-14)',
                selected: maxZoom == 14,
                onTap: () => onSelectMaxZoom(14),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OfflineMapZoomOption(
                title: 'Detallado (Recomendado)',
                subtitle: 'Calles y callejones (Z13-15)',
                selected: maxZoom == 15,
                onTap: () => onSelectMaxZoom(15),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

