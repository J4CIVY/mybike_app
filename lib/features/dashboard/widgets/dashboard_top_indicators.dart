import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/proto/bike_log.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class DashboardTopIndicators extends StatelessWidget {
  final BikeLogMsg msg;

  const DashboardTopIndicators({
    super.key,
    required this.msg,
  });

  String _stateName(BikeState s) => switch (s) {
        BikeState.off => 'APAGADA',
        BikeState.standBy => 'STANDBY',
        BikeState.parking => 'PARKING',
        BikeState.drive => 'DRIVE',
        BikeState.super_ => 'SPORT',
        BikeState.cruiseControl => 'CRUISE',
        BikeState.reverse => 'REVERSA',
        BikeState.lock => 'BLOQUEADA',
        BikeState.turtle => 'MODO ECO (TORTUGA)',
      };

  Color _stateColor(BikeState s) => switch (s) {
        BikeState.super_ => AppColors.secondary,
        BikeState.drive => AppColors.primary,
        BikeState.parking => AppColors.amber,
        BikeState.off || BikeState.lock => AppColors.error,
        _ => AppColors.textDim,
      };

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: msg.left ? AppColors.primary.withValues(alpha: 0.15) : AppColors.panelSecondary,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: msg.left ? AppColors.primary : AppColors.panelBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: 13, color: msg.left ? AppColors.primary : AppColors.textDim),
                const SizedBox(width: 4),
                Text(
                  'IZQ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: msg.left ? AppColors.primary : AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: msg.parking
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.amber),
                            const SizedBox(width: 5),
                            Text(
                              'PATA ABAJO',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: AppColors.amber,
                              ),
                            ),
                          ],
                        ),
                      )
                    : StatusPill(
                        label: _stateName(msg.state),
                        color: _stateColor(msg.state),
                        pulse: msg.state == BikeState.drive,
                      ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: msg.right ? AppColors.primary.withValues(alpha: 0.15) : AppColors.panelSecondary,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: msg.right ? AppColors.primary : AppColors.panelBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DER',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: msg.right ? AppColors.primary : AppColors.textDim,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 13, color: msg.right ? AppColors.primary : AppColors.textDim),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

