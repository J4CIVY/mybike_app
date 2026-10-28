import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class DashboardPowerControls extends StatelessWidget {
  final bool powerBusy;
  final bool isFindingBike;
  final double speed;
  final VoidCallback onTurnOn;
  final VoidCallback onTurnOff;
  final VoidCallback onToggleFindBike;

  const DashboardPowerControls({
    super.key,
    required this.powerBusy,
    required this.isFindingBike,
    required this.speed,
    required this.onTurnOn,
    required this.onTurnOff,
    required this.onToggleFindBike,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      borderRadius: 16,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.power_settings_new_rounded, size: 18),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'ENCENDER MOTO',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              onPressed: powerBusy ? null : onTurnOn,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: speed > 0.5 ? AppColors.textDim : AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(speed > 0.5 ? Icons.shield_rounded : Icons.power_off_rounded, size: 18),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  speed > 0.5 ? 'EN MARCHA' : 'APAGAR MOTO',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              onPressed: powerBusy ? null : onTurnOff,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: isFindingBike ? AppColors.amber : AppColors.panelSecondary,
              foregroundColor: isFindingBike ? Colors.black : AppColors.primary,
              padding: const EdgeInsets.all(11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isFindingBike ? AppColors.amber : AppColors.panelBorder),
              ),
            ),
            tooltip: isFindingBike ? 'Silenciar pito' : 'Localizar moto (Pito)',
            icon: Icon(
              isFindingBike ? Icons.notifications_active_rounded : Icons.volume_up_rounded,
              size: 19,
            ),
            onPressed: onToggleFindBike,
          ),
        ],
      ),
    );
  }
}

