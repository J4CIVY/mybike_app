import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/battery_diagnostics_service.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class CellVoltagesChart extends StatefulWidget {
  final BatteryHealthReport report;

  const CellVoltagesChart({
    super.key,
    required this.report,
  });

  @override
  State<CellVoltagesChart> createState() => _CellVoltagesChartState();
}

class _CellVoltagesChartState extends State<CellVoltagesChart> {
  int? _selectedCellIndex;

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final cells = report.cellVoltages;
    final hasCells = cells.isNotEmpty;
    final minV = hasCells ? (report.minCellVoltage - 0.05).clamp(2.5, 4.2) : 2.5;
    final maxV = hasCells ? (report.maxCellVoltage + 0.05).clamp(minV + 0.05, 4.3) : 4.2;

    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 0.8),
                ),
                child: Text(
                  report.packConfigName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (hasCells && _selectedCellIndex != null && _selectedCellIndex! < cells.length)
                Flexible(
                  child: Text(
                    'Celda #${_selectedCellIndex! + 1}: ${cells[_selectedCellIndex!].toStringAsFixed(3)} V',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (hasCells)
                Text(
                  'Toque una celda para ver',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDim),
                )
              else
                Text(
                  'Esperando datos BMS...',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDim),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (!hasCells)
            Container(
              height: 120,
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.panelSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.panelBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.developer_board_off_rounded, color: AppColors.textDim, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'Aún no se reciben voltajes individuales por celda del BMS vía Bluetooth.\nLa gráfica se dibujará automáticamente en cuanto se reciba la telemetría.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.textDim,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(cells.length, (idx) {
                  final v = cells[idx];
                  final normalized = ((v - minV) / (maxV - minV)).clamp(0.08, 1.0);
                  final isLowest = (idx + 1) == report.minCellIndex;
                  final isHighest = (idx + 1) == report.maxCellIndex;
                  final isSelected = _selectedCellIndex == idx;

                  final Color barColor;
                  if (isLowest && report.deltaVoltageMv > 60) {
                    barColor = AppColors.error;
                  } else if (isHighest) {
                    barColor = AppColors.primary;
                  } else if (isSelected) {
                    barColor = AppColors.secondary;
                  } else {
                    barColor = AppColors.primary.withValues(alpha: 0.55);
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCellIndex = (_selectedCellIndex == idx) ? null : idx;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isSelected || isLowest || isHighest)
                              Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: barColor,
                                ),
                              ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 110 * normalized,
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    border: isSelected
                                        ? Border.all(color: Colors.white, width: 1.5)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${idx + 1}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textDim,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegend(AppColors.primary, 'Celda máxima'),
              const SizedBox(width: 14),
              _buildChartLegend(
                report.deltaVoltageMv > 60 ? AppColors.error : AppColors.amber,
                'Celda mínima',
              ),
              const SizedBox(width: 14),
              _buildChartLegend(AppColors.primary.withValues(alpha: 0.55), 'Celda estándar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDim),
        ),
      ],
    );
  }
}

