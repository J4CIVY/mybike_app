import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

class TripRouteStartEndPin extends StatelessWidget {
  final String label;
  final bool isStart;

  const TripRouteStartEndPin({super.key, required this.label, required this.isStart});

  @override
  Widget build(BuildContext context) {
    final color = isStart ? AppColors.tertiary : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class TripRouteMyLocationMarker extends StatelessWidget {
  const TripRouteMyLocationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
        ),
      ],
    );
  }
}

