import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

class BikeTripBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const BikeTripBadge({
    super.key,
    required this.icon,
    required this.label,
    this.color = const Color(0xFF64748B),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class BikeTripHistoryItem extends StatelessWidget {
  final String title;
  final String time;
  final String distance;
  final String avgSpeed;
  final String batteryUsed;
  final String co2Saved;
  final bool isRecent;
  final bool hasGps;

  const BikeTripHistoryItem({
    super.key,
    required this.title,
    required this.time,
    required this.distance,
    required this.avgSpeed,
    required this.batteryUsed,
    required this.co2Saved,
    this.isRecent = false,
    this.hasGps = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecent ? const Color(0xFFFECACA) : const Color(0xFFF1F5F9),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isRecent ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.two_wheeler_rounded,
                  size: 18,
                  color: isRecent ? BskmtColors.crimson : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (hasGps)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              'GPS',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                distance,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              BikeTripBadge(icon: Icons.speed_rounded, label: avgSpeed),
              const SizedBox(width: 8),
              BikeTripBadge(
                icon: Icons.battery_std_rounded,
                label: batteryUsed,
                color: const Color(0xFF059669),
              ),
              const SizedBox(width: 8),
              BikeTripBadge(
                icon: Icons.eco_rounded,
                label: '-$co2Saved CO₂',
                color: const Color(0xFF16A34A),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver Ruta',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: BskmtColors.crimson,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: BskmtColors.crimson,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
