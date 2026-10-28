import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';
import 'lab_result_view.dart';

class LabCustomTesterCard extends StatelessWidget {
  final TextEditingController uuidController;
  final TextEditingController inputController;
  final bool hex;
  final bool busy;
  final bool connected;
  final LabIoResult? lastResult;
  final VoidCallback onToggleHex;
  final void Function(String op) onRunOp;

  const LabCustomTesterCard({
    super.key,
    required this.uuidController,
    required this.inputController,
    required this.hex,
    required this.busy,
    required this.connected,
    required this.lastResult,
    required this.onToggleHex,
    required this.onRunOp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textDim.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CARACTERÍSTICA PERSONALIZADA (Fuera de catálogo)',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: uuidController,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'UUID completo o primeros 8 hex',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onToggleHex,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: hex ? AppColors.secondary.withValues(alpha: 0.25) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.textDim.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    hex ? 'HEX' : 'TXT',
                    style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: inputController,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Payload (texto/HEX)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: connected && !busy ? () => onRunOp('read') : null,
                  child: const Text('LEER', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: connected && !busy ? () => onRunOp('write_plain') : null,
                  child: const Text('ESCRIBIR PLAIN', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FilledButton(
                  onPressed: connected && !busy ? () => onRunOp('write_protected') : null,
                  child: const Text('ESCRIBIR PROTECTED', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
          if (lastResult != null) ...[
            const SizedBox(height: 8),
            LabResultView(result: lastResult!),
          ],
        ],
      ),
    );
  }
}

