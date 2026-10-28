import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';

class CockpitMapGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? iconColor;
  final bool isActive;

  const CockpitMapGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.iconColor,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFEFF6FF) : AppColors.panel.withValues(alpha: 0.92),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.panelBorderBright,
              width: 1,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              icon,
              color: iconColor ?? (isActive ? AppColors.primary : AppColors.textDim),
              size: 16,
            ),
            tooltip: tooltip,
            onPressed: onTap,
          ),
        ),
      ),
    );
  }
}

