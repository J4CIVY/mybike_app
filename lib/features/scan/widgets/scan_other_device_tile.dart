import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class ScanOtherDeviceTile extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onTap;

  const ScanOtherDeviceTile({
    super.key,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rawName = result.advertisementData.advName.isNotEmpty
        ? result.advertisementData.advName
        : result.device.platformName;
    final name = rawName.isEmpty ? '(Sin nombre)' : rawName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Panel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: 14,
        onTap: onTap,
        child: Row(
          children: [
            const Icon(Icons.bluetooth_rounded, size: 20, color: AppColors.textDim),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${result.device.remoteId.str} · ${result.rssi} dBm',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textDim),
          ],
        ),
      ),
    );
  }
}

