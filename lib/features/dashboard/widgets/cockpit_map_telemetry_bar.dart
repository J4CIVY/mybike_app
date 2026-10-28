import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../ui/app_theme.dart';

class CockpitMapTelemetryBar extends StatelessWidget {
  final double currentSpeedKmh;
  final LatLng? myLocation;
  final int routePointsCount;

  const CockpitMapTelemetryBar({
    super.key,
    required this.currentSpeedKmh,
    required this.myLocation,
    required this.routePointsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 10,
      right: 10,
      bottom: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.panel.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.panelBorderBright),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Flexible(
                  flex: 4,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentSpeedKmh.toStringAsFixed(0),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: currentSpeedKmh > 0 ? AppColors.primary : AppColors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'km/h',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  flex: 6,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.secondary),
                        const SizedBox(width: 3),
                        Text(
                          myLocation != null
                              ? '${myLocation!.latitude.toStringAsFixed(4)}°, ${myLocation!.longitude.toStringAsFixed(4)}°'
                              : '$routePointsCount puntos GPS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

