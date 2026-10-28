import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart' show TripGpsPoint;
import '../../../ui/app_theme.dart';
import 'trip_route_utils.dart';

class TripRoutePlaybackBar extends StatelessWidget {
  final List<TripGpsPoint> routePoints;
  final int currentIndex;
  final bool isPlaying;
  final double playbackSpeed;
  final bool followBike;
  final ValueChanged<int> onSeekTo;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onCyclePlaybackSpeed;
  final VoidCallback onToggleFollowBike;

  const TripRoutePlaybackBar({
    super.key,
    required this.routePoints,
    required this.currentIndex,
    required this.isPlaying,
    required this.playbackSpeed,
    required this.followBike,
    required this.onSeekTo,
    required this.onTogglePlayPause,
    required this.onCyclePlaybackSpeed,
    required this.onToggleFollowBike,
  });

  @override
  Widget build(BuildContext context) {
    final hasPoints = routePoints.isNotEmpty;
    final currentPoint = hasPoints ? routePoints[currentIndex.clamp(0, routePoints.length - 1)] : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.panel.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.panelBorderBright),
            boxShadow: AppColors.modalShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentPoint != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            currentPoint.speedKmh.toStringAsFixed(0),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: currentPoint.speedKmh > 0 ? AppColors.primary : AppColors.textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'km/h',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDim,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: TripRouteUtils.getContinuousSpeedColor(currentPoint.speedKmh).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: TripRouteUtils.getContinuousSpeedColor(currentPoint.speedKmh).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              TripRouteUtils.getSpeedLabel(currentPoint.speedKmh),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: TripRouteUtils.getContinuousSpeedColor(currentPoint.speedKmh),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${currentPoint.timestamp.hour.toString().padLeft(2, '0')}:${currentPoint.timestamp.minute.toString().padLeft(2, '0')}:${currentPoint.timestamp.second.toString().padLeft(2, '0')}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Punto ${currentIndex + 1}/${routePoints.length}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (hasPoints)
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.surfaceContainer,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.15),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: currentIndex.toDouble().clamp(0, math.max(1.0, (routePoints.length - 1).toDouble())),
                    min: 0,
                    max: math.max(1.0, (routePoints.length - 1).toDouble()),
                    onChanged: (val) => onSeekTo(val.round()),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: onToggleFollowBike,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: followBike ? const Color(0xFFEFF6FF) : AppColors.panelSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: followBike ? AppColors.primary : AppColors.panelBorderBright,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.navigation_rounded,
                            size: 13,
                            color: followBike ? AppColors.primary : AppColors.textDim,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Seguir moto',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: followBike ? AppColors.primary : AppColors.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay_rounded, color: AppColors.textDim, size: 20),
                    tooltip: 'Inicio',
                    onPressed: () => onSeekTo(0),
                  ),
                  GestureDetector(
                    onTap: onTogglePlayPause,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onCyclePlaybackSpeed,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.panelSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.panelBorderBright),
                      ),
                      child: Text(
                        '${playbackSpeed.toStringAsFixed(0)}x',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: AppColors.textDim, size: 20),
                    tooltip: 'Fin',
                    onPressed: () => onSeekTo(routePoints.length - 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

