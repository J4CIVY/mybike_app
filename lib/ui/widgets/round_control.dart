import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';

/// Control de acción rápida tipo dock/pill con icono y etiqueta.
class RoundControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  final Color? activeColor;

  const RoundControl({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = activeColor ?? AppColors.primary;
    return Column(
      children: [
        Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: enabled ? onTap : null,
              child: Container(
                width: 58,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.panel,
                  border: Border.all(
                    color: enabled
                        ? effectiveColor.withValues(alpha: 0.4)
                        : AppColors.panelBorder,
                    width: 1.2,
                  ),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: enabled ? effectiveColor : AppColors.textDim,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: enabled ? AppColors.textPrimary : AppColors.textDim,
            ),
          ),
        ),
      ],
    );
  }
}

