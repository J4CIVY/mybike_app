import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';
import '../../../ui/widgets.dart';

class LogFileTile extends StatelessWidget {
  final File file;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onShare;

  const LogFileTile({
    super.key,
    required this.file,
    required this.isSelected,
    required this.onTap,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: 14,
        borderColor: isSelected ? AppColors.secondary : null,
        hasActiveHalo: isSelected,
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.article_rounded : Icons.article_outlined,
              color: isSelected ? AppColors.primary : AppColors.textDim,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.uri.pathSegments.last,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB · '
                    '${file.statSync().modified.toLocal().toString().substring(0, 19)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded, size: 18),
              color: AppColors.primary,
              onPressed: onShare,
            ),
          ],
        ),
      ),
    );
  }
}

