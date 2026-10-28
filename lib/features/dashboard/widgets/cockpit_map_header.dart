import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/map_tile_service.dart';
import '../../../ui/app_theme.dart';
import 'cockpit_map_glass_button.dart';

class CockpitMapHeader extends StatelessWidget {
  final bool isTracking;
  final MapTileStyle tileStyle;
  final VoidCallback onCycleTileStyle;
  final VoidCallback onOpenOfflineSheet;
  final VoidCallback? onExpandFullScreen;

  const CockpitMapHeader({
    super.key,
    required this.isTracking,
    required this.tileStyle,
    required this.onCycleTileStyle,
    required this.onOpenOfflineSheet,
    this.onExpandFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Row(
        children: [
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.panel.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: isTracking ? AppColors.red.withValues(alpha: 0.4) : AppColors.panelBorderBright,
                    ),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isTracking ? AppColors.red : AppColors.tertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isTracking ? 'REC GRABANDO' : 'GPS LISTO',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isTracking ? AppColors.red : AppColors.textPrimary,
                              letterSpacing: 0.05 * 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          CockpitMapGlassButton(
            icon: MapTileService.getStyleIcon(tileStyle),
            tooltip: MapTileService.getStyleName(tileStyle),
            onTap: onCycleTileStyle,
          ),
          const SizedBox(width: 6),
          CockpitMapGlassButton(
            icon: Icons.download_for_offline_rounded,
            tooltip: 'Descargar mapas offline',
            onTap: onOpenOfflineSheet,
          ),
          if (onExpandFullScreen != null) ...[
            const SizedBox(width: 6),
            CockpitMapGlassButton(
              icon: Icons.fullscreen_rounded,
              tooltip: 'Pantalla completa HUD',
              onTap: onExpandFullScreen!,
            ),
          ],
        ],
      ),
    );
  }
}

