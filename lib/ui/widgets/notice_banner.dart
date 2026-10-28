import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Banner de notificación con borde ligero y color semántico.
class NoticeBanner extends StatelessWidget {
  final Color color;
  final String text;
  final Widget? trailing;

  const NoticeBanner({
    super.key,
    required this.color,
    required this.text,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.3,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

