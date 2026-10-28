import 'package:flutter/material.dart';

import '../../../core/proto/bike_log.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class DashboardMetricsRow extends StatelessWidget {
  final BikeLogMsg msg;

  const DashboardMetricsRow({
    super.key,
    required this.msg,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MetricTile(
            icon: Icons.battery_charging_full_rounded,
            label: 'BATERÍA (${msg.percent}%)',
            value: msg.kmLeft.toStringAsFixed(0),
            unit: 'km',
            valueColor: AppColors.primary,
            accentColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: MetricTile(
            icon: Icons.electric_bolt_rounded,
            label: 'VOLTAJE',
            value: msg.voltage > 0 ? msg.voltage.toStringAsFixed(1) : '—',
            unit: 'V',
            valueColor: AppColors.textPrimary,
            accentColor: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: MetricTile(
            icon: Icons.route_rounded,
            label: 'ODÓMETRO TOTAL',
            value: msg.odo.toStringAsFixed(0),
            unit: 'km',
            accentColor: AppColors.tertiary,
          ),
        ),
      ],
    );
  }
}

