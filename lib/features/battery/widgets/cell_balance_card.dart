import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/battery_diagnostics_service.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class CellBalanceCard extends StatelessWidget {
  final BatteryHealthReport report;

  const CellBalanceCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final hasCells = report.cellCount > 0;
    final gradeColor = switch (report.balanceGrade) {
      CellBalanceGrade.unknown => AppColors.secondary,
      CellBalanceGrade.excellent => AppColors.tertiary,
      CellBalanceGrade.good => AppColors.secondary,
      CellBalanceGrade.fair => AppColors.amber,
      CellBalanceGrade.poor => const Color(0xFFF97316),
      CellBalanceGrade.critical => AppColors.error,
    };

    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DESVIACIÓN MÁXIMA (ΔV)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.06 * 11,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        hasCells ? report.deltaVoltageMv.toStringAsFixed(1) : '--',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: gradeColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'mV',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              StatusPill(
                label: report.balanceGrade.label.toUpperCase(),
                color: gradeColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.balanceGrade.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.panelBorder, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasCells ? 'Celda más alta (#${report.maxCellIndex})' : 'Celda más alta',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasCells ? '${report.maxCellVoltage.toStringAsFixed(3)} V' : '-- V',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (report.deltaVoltageMv > 80 ? AppColors.error : AppColors.amber)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (report.deltaVoltageMv > 80 ? AppColors.error : AppColors.amber)
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasCells ? 'Celda más baja (#${report.minCellIndex})' : 'Celda más baja',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: report.deltaVoltageMv > 80 ? AppColors.error : AppColors.amber,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasCells ? '${report.minCellVoltage.toStringAsFixed(3)} V' : '-- V',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.panelSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.panelBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voltaje prom. celda',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDim,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasCells ? '${report.avgCellVoltage.toStringAsFixed(3)} V' : '-- V',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

