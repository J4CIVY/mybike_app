import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart' show TripRecord;
import '../../../core/services/map_tile_service.dart';
import '../../../ui/app_theme.dart';
import '../../dashboard/widgets/offline_map_sheet.dart';
import 'trip_route_download_banner.dart';

class TripRouteMapOverlays extends StatelessWidget {
  final int currentTripIndex;
  final TripRecord currentTrip;
  final bool isLocating;
  final MapTileStyle tileStyle;
  final MapController mapController;
  final VoidCallback onOpenTripSearch;
  final VoidCallback onShowTripInfo;
  final VoidCallback onFitRouteBounds;
  final VoidCallback onLocateMe;
  final VoidCallback onCycleTileStyle;

  const TripRouteMapOverlays({
    super.key,
    required this.currentTripIndex,
    required this.currentTrip,
    required this.isLocating,
    required this.tileStyle,
    required this.mapController,
    required this.onOpenTripSearch,
    required this.onShowTripInfo,
    required this.onFitRouteBounds,
    required this.onLocateMe,
    required this.onCycleTileStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _glassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Volver',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: onOpenTripSearch,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.panel.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.panelBorderBright),
                              boxShadow: AppColors.cardShadow,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '#$currentTripIndex · ${currentTrip.distanceKm.toStringAsFixed(1)} km',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.unfold_more_rounded, size: 16, color: AppColors.textDim),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _glassIconButton(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.primary,
                    tooltip: 'Información de velocidad & ruta',
                    onTap: onShowTripInfo,
                  ),
                ],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 56, right: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _glassIconButton(
                    icon: Icons.crop_free_rounded,
                    tooltip: 'Centrar ruta completa',
                    onTap: onFitRouteBounds,
                  ),
                  const SizedBox(height: 8),
                  _glassIconButton(
                    icon: Icons.my_location_rounded,
                    iconColor: isLocating ? AppColors.primary : AppColors.textDim,
                    isActive: isLocating,
                    tooltip: 'Mi ubicación',
                    onTap: onLocateMe,
                  ),
                  const SizedBox(height: 8),
                  _glassIconButton(
                    icon: MapTileService.getStyleIcon(tileStyle),
                    tooltip: MapTileService.getStyleName(tileStyle),
                    onTap: onCycleTileStyle,
                  ),
                  const SizedBox(height: 8),
                  _glassIconButton(
                    icon: Icons.download_for_offline_rounded,
                    tooltip: 'Descargar mapa offline',
                    onTap: () {
                      OfflineMapSheet.show(
                        context,
                        currentMapBounds: mapController.camera.visibleBounds,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        TripRouteDownloadBanner(mapController: mapController),
      ],
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color? iconColor,
    bool isActive = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEFF6FF) : AppColors.panel.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.panelBorderBright,
              width: 1,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              icon,
              color: iconColor ?? (isActive ? AppColors.primary : AppColors.textDim),
              size: 18,
            ),
            tooltip: tooltip,
            onPressed: onTap,
          ),
        ),
      ),
    );
  }
}
