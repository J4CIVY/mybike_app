import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mybike_app/core/models/bskmt_models.dart';
import '../../../ui/app_theme.dart';

class GarageMotorcycleCard extends StatelessWidget {
  final BskmtMotorcycle moto;
  final bool isSelected;
  final VoidCallback onSelect;

  const GarageMotorcycleCard({
    super.key,
    required this.moto,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.two_wheeler_rounded,
                        color: isSelected ? AppColors.primary : AppColors.textDim,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${moto.brand} ${moto.modelLine}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Placa: ${moto.plate} • Año: ${moto.year}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: AppColors.textDim,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ACTIVA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: onSelect,
                    child: Text(
                      'Seleccionar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Odómetro Registrado',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDim),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${moto.currentOdometerKm.round()} km',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                _docStatusBadge(
                  title: 'SOAT',
                  days: moto.daysUntilSoat,
                  verified: moto.isRuntVerified,
                ),
                _docStatusBadge(
                  title: 'RTM',
                  days: moto.daysUntilRtm,
                  verified: moto.isRuntVerified,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _docStatusBadge({
    required String title,
    required int? days,
    required bool verified,
  }) {
    final Color badgeColor;
    final String label;

    if (days == null) {
      badgeColor = AppColors.textMuted;
      label = '$title: Sin fecha';
    } else if (days < 0) {
      badgeColor = AppColors.error;
      label = '$title: VENCIDO';
    } else if (days <= 15) {
      badgeColor = AppColors.amber;
      label = '$title: $days d';
    } else {
      badgeColor = AppColors.tertiary;
      label = '$title: Al día';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (verified)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.verified_rounded, size: 12, color: AppColors.tertiary),
            ),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

