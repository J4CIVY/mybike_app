import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

class BikeTelemetryCard extends StatelessWidget {
  final String kmLeftDisplay;
  final bool hasTelemetry;
  final bool isSideStandDown;
  final String drivingModeShort;
  final int percent;
  final String percentDisplay;
  final String statusText;

  const BikeTelemetryCard({
    super.key,
    required this.kmLeftDisplay,
    required this.hasTelemetry,
    required this.isSideStandDown,
    required this.drivingModeShort,
    required this.percent,
    required this.percentDisplay,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              kmLeftDisplay,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 54,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                color: const Color(0xFF0F172A),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'km',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const Spacer(),
            if (hasTelemetry) ...[
              if (isSideStandDown) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.report_problem_rounded,
                        size: 13,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PATA ABAJO',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  'MODO $drivingModeShort',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: BskmtColors.crimson,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 17,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 4),
                Text(
                  hasTelemetry
                      ? '$percentDisplay% Batería ($kmLeftDisplay km)'
                      : '--% Batería (Sin conexión)',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: BskmtColors.crimson,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '270 km Máx',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.swap_horiz_rounded,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: hasTelemetry && percent > 0 ? percent : 1,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: hasTelemetry
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: hasTelemetry ? (100 - percent).clamp(5, 100).toInt() : 1,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: hasTelemetry
                      ? BskmtColors.crimson
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          statusText,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
