import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';

class BikeHeaderBar extends StatelessWidget {
  final String bikeDisplayName;
  final bool connected;
  final List<dynamic> documentAlerts;
  final VoidCallback onTapSwitcher;
  final VoidCallback? onTapScan;
  final VoidCallback onTapDashboard;
  final VoidCallback onTapLogs;
  final VoidCallback onTapLab;

  const BikeHeaderBar({
    super.key,
    required this.bikeDisplayName,
    required this.connected,
    required this.documentAlerts,
    required this.onTapSwitcher,
    this.onTapScan,
    required this.onTapDashboard,
    required this.onTapLogs,
    required this.onTapLab,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTapSwitcher,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: const [
                            BoxShadow(color: Color(0x180F172A), blurRadius: 4, offset: Offset(0, 1)),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/bike_logo_3d.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.two_wheeler_rounded, size: 18, color: BskmtColors.crimson),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          bikeDisplayName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.swap_horiz_rounded, size: 18, color: BskmtColors.crimson),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Velocímetro Cockpit HUD',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.speed_rounded, size: 21, color: Color(0xFF0F172A)),
              onPressed: onTapDashboard,
            ),
            IconButton(
              tooltip: 'Registros Bluetooth',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.receipt_long_rounded, size: 20, color: Color(0xFF6366F1)),
              onPressed: onTapLogs,
            ),
            IconButton(
              tooltip: 'Laboratorio de Diagnóstico',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.science_rounded, size: 20, color: Color(0xFF8B5CF6)),
              onPressed: onTapLab,
            ),
            const SizedBox(width: 2),
            InkWell(
              onTap: onTapScan,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: connected ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                      size: 15,
                      color: connected ? BskmtColors.crimson : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      connected ? 'Online' : 'Offline',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: connected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (documentAlerts.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Alerta Garaje Virtual: ${documentAlerts.first['alert'] ?? 'Documento vehicular próximo a vencer'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

