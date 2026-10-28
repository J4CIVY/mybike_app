import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../core/ble/ble_logger.dart';
import '../../../ui/app_theme.dart';

class LabResultView extends StatelessWidget {
  final LabIoResult result;

  const LabResultView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final r = result;
    final color = r.ok ? AppColors.tertiary : Colors.redAccent;
    final lines = <String>[
      '[${r.op}] ${r.ok ? 'OK' : 'ERROR'} · ${r.elapsedMs}ms',
      if (r.error != null) 'error: ${r.error}',
      if (r.payload.isNotEmpty) 'raw (${r.payload.length}B): ${BleLogger.hex(r.payload, maxBytes: 64)}',
      if (r.decrypted != null && r.decrypted!.isNotEmpty)
        'dec (${r.decrypted!.length}B): ${BleLogger.hex(r.decrypted!, maxBytes: 64)}',
      if (r.decrypted != null && r.decrypted!.isNotEmpty && BleLogger.tryUtf8(r.decrypted!) != null)
        'text: "${BleLogger.tryUtf8(r.decrypted!)}"',
      if (r.decrypted == null && r.text != null && r.text!.isNotEmpty && r.op == 'read')
        'text: "${r.text}"',
      if (r.parsed != null && r.parsed!.isNotEmpty)
        'parsed: ${r.parsed}',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        lines.join('\n'),
        style: GoogleFonts.jetBrainsMono(fontSize: 10.5, height: 1.5, color: AppColors.textPrimary),
      ),
    );
  }
}

