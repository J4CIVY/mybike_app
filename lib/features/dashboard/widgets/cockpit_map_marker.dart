import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';

Color getContinuousSpeedColor(double speedKmh) {
  if (speedKmh <= 15.0) {
    final t = (speedKmh / 15.0).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFF06B6D4), const Color(0xFF10B981), t)!;
  } else if (speedKmh <= 35.0) {
    final t = ((speedKmh - 15.0) / 20.0).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFF10B981), const Color(0xFF0EA5E9), t)!;
  } else if (speedKmh <= 55.0) {
    final t = ((speedKmh - 35.0) / 20.0).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFF59E0B), const Color(0xFFF97316), t)!;
  } else {
    final t = ((speedKmh - 55.0) / 30.0).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFF97316), const Color(0xFFEF4444), t)!;
  }
}

class CockpitMapMarker extends StatelessWidget {
  final double speedKmh;
  final double heading;

  const CockpitMapMarker({
    super.key,
    required this.speedKmh,
    required this.heading,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: (heading * math.pi) / 180.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D2563EB),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.navigation_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

