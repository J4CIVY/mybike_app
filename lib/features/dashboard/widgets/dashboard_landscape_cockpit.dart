import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../core/proto/bike_log.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';
import 'dashboard_diagnostics_panel.dart';
import 'dashboard_hardware_info.dart';
import 'dashboard_metrics_row.dart';
import 'dashboard_power_badge.dart';
import 'dashboard_power_controls.dart';
import 'dashboard_speed_gauge_card.dart';
import 'dashboard_top_indicators.dart';
import 'dashboard_trip_panel.dart';

class DashboardLandscapeCockpit extends StatelessWidget {
  final BleState ble;
  final BikeLogMsg msg;
  final TripData trip;
  final double powerKw;
  final bool isRecup;
  final bool isDraw;
  final bool isEncrypted;
  final int activeTab;
  final ValueChanged<int> onTabChanged;
  final bool powerBusy;
  final VoidCallback onTurnOn;
  final VoidCallback onTurnOff;
  final VoidCallback onToggleFindBike;
  final VoidCallback onExpandFullScreen;
  final VoidCallback onOpenBatteryDiagnostics;
  final VoidCallback onTryRestoreLastBike;
  final Widget syncFooter;

  const DashboardLandscapeCockpit({
    super.key,
    required this.ble,
    required this.msg,
    required this.trip,
    required this.powerKw,
    required this.isRecup,
    required this.isDraw,
    required this.isEncrypted,
    required this.activeTab,
    required this.onTabChanged,
    required this.powerBusy,
    required this.onTurnOn,
    required this.onTurnOff,
    required this.onToggleFindBike,
    required this.onExpandFullScreen,
    required this.onOpenBatteryDiagnostics,
    required this.onTryRestoreLastBike,
    required this.syncFooter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 48,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 6, 14),
            child: Column(
              children: [
                DashboardTopIndicators(msg: msg),
                const SizedBox(height: 8),
                Expanded(
                  child: Panel(
                    padding: const EdgeInsets.all(8),
                    borderRadius: 18,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = (constraints.maxHeight * 0.72).clamp(110.0, 180.0);
                        return Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DashboardGaugeWithSpeed(msg: msg, gaugeSize: size),
                                const SizedBox(height: 6),
                                DashboardPowerBadge(powerKw: powerKw, isRecup: isRecup, isDraw: isDraw),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DashboardPowerControls(
                  powerBusy: powerBusy,
                  isFindingBike: ble.isFindingBike,
                  speed: msg.speed,
                  onTurnOn: onTurnOn,
                  onTurnOff: onTurnOff,
                  onToggleFindBike: onToggleFindBike,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 52,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(6, 4, 14, 24),
            children: [
              if (ble.phase == BlePhase.reconnecting || ble.phase == BlePhase.disconnected) ...[
                NoticeBanner(
                  color: ble.phase == BlePhase.reconnecting ? AppColors.amber : AppColors.error,
                  text: ble.message ?? 'Conexión BLE perdida — reconectando automáticamente…',
                  trailing: ble.phase == BlePhase.disconnected
                      ? TextButton(
                          onPressed: onTryRestoreLastBike,
                          child: Text(
                            'RECONECTAR',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
              ],
              DashboardMetricsRow(msg: msg),
              const SizedBox(height: 10),
              _buildTabSwitcher(),
              const SizedBox(height: 10),
              if (activeTab == 0)
                DashboardTripPanel(
                  trip: trip,
                  msg: msg,
                  onExpandFullScreen: onExpandFullScreen,
                )
              else
                DashboardDiagnosticsPanel(
                  msg: msg,
                  onOpenBatteryDiagnostics: onOpenBatteryDiagnostics,
                ),
              const SizedBox(height: 10),
              DashboardHardwareInfo(msg: msg),
              const SizedBox(height: 12),
              syncFooter,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return Row(
      children: [
        Expanded(
          child: _tabButton(
            index: 0,
            icon: Icons.route_rounded,
            label: 'TELEMETRÍA & RUTA',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tabButton(
            index: 1,
            icon: Icons.health_and_safety_rounded,
            label: 'TEMPERATURAS & OBD',
          ),
        ),
      ],
    );
  }

  Widget _tabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = activeTab == index;
    return InkWell(
      borderRadius: BorderRadius.circular(9999),
      onTap: () => onTabChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.panel,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.panelBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.primary : AppColors.textDim,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : AppColors.textDim,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

