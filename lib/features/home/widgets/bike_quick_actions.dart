import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';
import '../../../ui/geely_icons.dart';

class BikeQuickActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;
  final Color? activeBorderColor;

  const BikeQuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor,
    this.activeBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? (activeColor ?? const Color(0xFFEFF6FF)) : const Color(0xFFF8FAFC),
              border: Border.all(
                color: active ? (activeBorderColor ?? const Color(0xFFBFDBFE)) : const Color(0xFFF1F5F9),
                width: 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: (activeBorderColor ?? const Color(0xFF2563EB)).withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class BikeQuickActions extends StatelessWidget {
  final bool isLocked;
  final bool isBikeOn;
  final bool isFindingBike;
  final VoidCallback onQuickLockToggle;
  final VoidCallback onQuickPowerToggle;
  final VoidCallback onQuickFindBike;
  final VoidCallback onQuickSyncTime;
  final VoidCallback onOpenRemoteControls;

  const BikeQuickActions({
    super.key,
    required this.isLocked,
    required this.isBikeOn,
    required this.isFindingBike,
    required this.onQuickLockToggle,
    required this.onQuickPowerToggle,
    required this.onQuickFindBike,
    required this.onQuickSyncTime,
    required this.onOpenRemoteControls,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                BikeQuickActionButton(
                  icon: isLocked
                      ? GeelyIcons.lock(color: const Color(0xFFEF4444), size: 24)
                      : GeelyIcons.lockOpen(color: BskmtColors.crimson, size: 24),
                  label: isLocked ? 'Desbloquear' : 'Bloqueo Antirrobo',
                  onTap: onQuickLockToggle,
                  active: isLocked,
                  activeColor: const Color(0xFFFEF2F2),
                  activeBorderColor: const Color(0xFFFECACA),
                ),
                BikeQuickActionButton(
                  icon: Icon(
                    Icons.power_settings_new_rounded,
                    color: isBikeOn ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    size: 24,
                  ),
                  label: isBikeOn ? 'Apagar Moto' : 'Encender Moto',
                  onTap: onQuickPowerToggle,
                  active: isBikeOn,
                  activeColor: const Color(0xFFF0FDF4),
                  activeBorderColor: const Color(0xFFBBF7D0),
                ),
                BikeQuickActionButton(
                  icon: isFindingBike
                      ? const Icon(Icons.volume_off_rounded, color: Color(0xFFEF4444), size: 24)
                      : GeelyIcons.findBike(color: BskmtColors.crimson, size: 24),
                  label: isFindingBike ? 'Silenciar' : 'Localizar',
                  onTap: onQuickFindBike,
                  active: isFindingBike,
                  activeColor: const Color(0xFFFEF2F2),
                  activeBorderColor: const Color(0xFFFECACA),
                ),
                BikeQuickActionButton(
                  icon: GeelyIcons.clock(color: const Color(0xFF0F172A), size: 24),
                  label: 'Sincronizar Hora',
                  onTap: onQuickSyncTime,
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
          InkWell(
            onTap: onOpenRemoteControls,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ajustes rápidos y seguridad antirrobo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

