import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/proto/bike_log.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/gauge.dart';
import '../../../ui/widgets.dart';
import 'dashboard_metrics_row.dart';
import 'dashboard_power_badge.dart';

class DashboardGaugeWithSpeed extends StatelessWidget {
  final BikeLogMsg msg;
  final double gaugeSize;

  const DashboardGaugeWithSpeed({
    super.key,
    required this.msg,
    required this.gaugeSize,
  });

  @override
  Widget build(BuildContext context) {
    return SpeedGauge(
      size: gaugeSize,
      speed: msg.speed,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            msg.speed.toStringAsFixed(1),
            style: GoogleFonts.spaceGrotesk(
              fontSize: (gaugeSize * 0.25).clamp(42.0, 56.0),
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'KM / H',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textDim,
              fontSize: (gaugeSize * 0.05).clamp(11.0, 13.0),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.08 * 12,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSpeedGaugeCard extends StatelessWidget {
  final BikeLogMsg msg;
  final double powerKw;
  final bool isRecup;
  final bool isDraw;

  const DashboardSpeedGaugeCard({
    super.key,
    required this.msg,
    required this.powerKw,
    required this.isRecup,
    required this.isDraw,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      borderRadius: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gaugeSize = (constraints.maxWidth * 0.62).clamp(180.0, 230.0);
          return Column(
            children: [
              DashboardGaugeWithSpeed(msg: msg, gaugeSize: gaugeSize),
              const SizedBox(height: 6),
              DashboardPowerBadge(powerKw: powerKw, isRecup: isRecup, isDraw: isDraw),
              const SizedBox(height: 14),
              DashboardMetricsRow(msg: msg),
            ],
          );
        },
      ),
    );
  }
}

