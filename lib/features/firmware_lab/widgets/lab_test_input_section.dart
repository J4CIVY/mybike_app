import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';
import '../lab_catalog.dart';
import '../models/lab_ui_state.dart';

class LabTestInputSection extends StatelessWidget {
  final LabCharTest test;
  final LabTestUiState uiState;
  final VoidCallback onToggleHex;
  final ValueChanged<LabWriteMode> onSelectWriteMode;
  final ValueChanged<int> onSelectPreset;

  const LabTestInputSection({
    super.key,
    required this.test,
    required this.uiState,
    required this.onToggleHex,
    required this.onSelectWriteMode,
    required this.onSelectPreset,
  });

  @override
  Widget build(BuildContext context) {
    final t = test;
    final s = uiState;
    final defaultPlain = (s.modeOverride ?? t.writeMode) == LabWriteMode.plain;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (t.presets.any((p) => p.data.isNotEmpty)) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < t.presets.length; i++)
                if (t.presets[i].data.isNotEmpty)
                  ChoiceChip(
                    label: Text(t.presets[i].label, style: GoogleFonts.plusJakartaSans(fontSize: 10.5)),
                    selected: s.selectedPreset == i,
                    onSelected: (_) => onSelectPreset(i),
                  ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: s.input,
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Payload a enviar (texto/HEX)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onToggleHex,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: s.isHex ? AppColors.secondary.withValues(alpha: 0.25) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.textDim.withValues(alpha: 0.4)),
                ),
                child: Text(s.isHex ? 'HEX' : 'TXT', style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      labelPadding: EdgeInsets.zero,
                      label: Center(child: Text('PROT', style: GoogleFonts.spaceGrotesk(fontSize: 9.5))),
                      selected: !defaultPlain,
                      onSelected: (_) => onSelectWriteMode(LabWriteMode.protected),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ChoiceChip(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      labelPadding: EdgeInsets.zero,
                      label: Center(child: Text('PLAIN', style: GoogleFonts.spaceGrotesk(fontSize: 9.5))),
                      selected: defaultPlain,
                      onSelected: (_) => onSelectWriteMode(LabWriteMode.plain),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

