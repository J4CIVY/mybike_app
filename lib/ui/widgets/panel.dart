import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Tarjeta nivel 1 con borde hairline, fondo claro y sombra difusa.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final bool hasActiveHalo;
  final VoidCallback? onTap;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.borderRadius = 20,
    this.hasActiveHalo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.panel,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? (hasActiveHalo ? AppColors.secondary : AppColors.panelBorder),
          width: 1,
        ),
        boxShadow: hasActiveHalo
            ? [
                ...AppColors.cardShadow,
                AppColors.activeHalo,
              ]
            : AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

