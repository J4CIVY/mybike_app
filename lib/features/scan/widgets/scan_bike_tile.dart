import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class ScanBikeTile extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onTap;

  const ScanBikeTile({
    super.key,
    required this.result,
    required this.onTap,
  });

  String _rssiBars(int rssi) {
    if (rssi >= -55) return '▂▄▆█';
    if (rssi >= -70) return '▂▄▆_';
    if (rssi >= -85) return '▂▄__';
    return '▂___';
  }

  @override
  Widget build(BuildContext context) {
    final rawName = result.advertisementData.advName.isNotEmpty
        ? result.advertisementData.advName
        : result.device.platformName;
    final name = rawName.isEmpty ? '(Sin nombre)' : rawName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.electric_moped_rounded, color: AppColors.secondary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _rssiBars(result.rssi),
                        style: const TextStyle(
                          color: AppColors.tertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${result.rssi} dBm · ${result.device.remoteId.str}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

