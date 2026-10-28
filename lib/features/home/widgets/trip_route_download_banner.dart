import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/offline_map_service.dart';
import '../../../ui/app_theme.dart';
import '../../dashboard/widgets/offline_map_sheet.dart';

class TripRouteDownloadBanner extends StatelessWidget {
  final MapController mapController;

  const TripRouteDownloadBanner({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DownloadProgress>(
      valueListenable: OfflineMapService.instance.progressNotifier,
      builder: (context, progress, _) {
        if (!progress.isRunning && !progress.isPaused) {
          return const SizedBox.shrink();
        }
        return Positioned(
          top: 56,
          left: 14,
          right: 58,
          child: GestureDetector(
            onTap: () => OfflineMapSheet.show(
              context,
              currentMapBounds: mapController.camera.visibleBounds,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.panel.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: progress.isPaused ? AppColors.amber : AppColors.primary,
                    ),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      if (progress.isRunning)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      else
                        const Icon(Icons.pause_circle_rounded, size: 14, color: AppColors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          progress.isPaused
                              ? 'Descarga pausada (${progress.percentInt}%)'
                              : 'Descargando mapa offline: ${progress.percentInt}% (${progress.sizeMbText})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Detalle >',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

