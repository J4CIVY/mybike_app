import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/app_theme.dart';
import '../lab_catalog.dart';
import '../models/lab_ui_state.dart';
import 'lab_info_box.dart';
import 'lab_result_view.dart';
import 'lab_test_input_section.dart';

class LabTestExpansionTile extends StatelessWidget {
  final LabCharTest test;
  final LabTestUiState uiState;
  final bool connected;
  final VoidCallback onToggleHex;
  final ValueChanged<LabWriteMode> onSelectWriteMode;
  final ValueChanged<int> onSelectPreset;
  final void Function(String op) onRunOp;
  final ValueChanged<String> onSelectVerdict;
  final ValueChanged<String> onNoteChanged;

  const LabTestExpansionTile({
    super.key,
    required this.test,
    required this.uiState,
    required this.connected,
    required this.onToggleHex,
    required this.onSelectWriteMode,
    required this.onSelectPreset,
    required this.onRunOp,
    required this.onSelectVerdict,
    required this.onNoteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = test;
    final s = uiState;
    final canWrite = t.writeMode != LabWriteMode.none;
    final preset = s.selectedPreset >= 0 && s.selectedPreset < t.presets.length
        ? t.presets[s.selectedPreset]
        : null;
    final riskColor = t.risk == LabRisk.danger
        ? Colors.redAccent
        : t.risk == LabRisk.caution
        ? AppColors.amber
        : AppColors.tertiary;
    final riskLabel = t.risk == LabRisk.danger
        ? 'PELIGRO'
        : t.risk == LabRisk.caution
        ? 'PRECAUCIÓN'
        : 'SEGURO';

    final verdictIcon = s.verdict == 'pass'
        ? const Icon(
            Icons.check_circle_rounded,
            color: AppColors.tertiary,
            size: 18,
          )
        : s.verdict == 'fail'
        ? const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 18)
        : s.verdict == 'skip'
        ? const Icon(
            Icons.skip_next_rounded,
            color: AppColors.textDim,
            size: 18,
          )
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: s.verdict == 'fail'
              ? Colors.redAccent.withValues(alpha: 0.5)
              : s.verdict == 'pass'
              ? AppColors.tertiary.withValues(alpha: 0.4)
              : AppColors.textDim.withValues(alpha: 0.25),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Row(
              children: [
                if (t.name.contains('⭐'))
                  const Text('⭐', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    t.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ?verdictIcon,
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '${t.shortId} · $riskLabel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  color: riskColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '📎 ${t.evidence}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.textDim,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (t.readExpect.isNotEmpty)
                LabInfoBox(
                  title: 'PREDICCIÓN AL LEER',
                  body: t.readExpect,
                  color: AppColors.amber,
                  icon: Icons.visibility_rounded,
                ),
              if (preset != null) ...[
                const SizedBox(height: 6),
                LabInfoBox(
                  title: 'PREDICCIÓN: ${preset.label}',
                  body: preset.prediction,
                  color: AppColors.amber,
                  icon: Icons.science_rounded,
                ),
              ],
              if (t.observed != null) ...[
                const SizedBox(height: 6),
                LabInfoBox(
                  title: 'OBSERVADO EN PRUEBAS',
                  body: t.observed!,
                  color: AppColors.tertiary,
                  icon: Icons.history_rounded,
                ),
              ],
              if (t.verifyHint.isNotEmpty) ...[
                const SizedBox(height: 6),
                LabInfoBox(
                  title: 'MÉTODO DE VERIFICACIÓN',
                  body: t.verifyHint,
                  color: AppColors.secondary,
                  icon: Icons.checklist_rounded,
                ),
              ],
              const SizedBox(height: 10),
              if (canWrite)
                LabTestInputSection(
                  test: t,
                  uiState: s,
                  onToggleHex: onToggleHex,
                  onSelectWriteMode: onSelectWriteMode,
                  onSelectPreset: onSelectPreset,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (t.canRead)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: connected && !s.busy
                            ? () => onRunOp('read')
                            : null,
                        icon: s.busy
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 15),
                        label: Text(
                          'LEER',
                          style: GoogleFonts.spaceGrotesk(fontSize: 11),
                        ),
                      ),
                    ),
                  if (t.canRead && canWrite) const SizedBox(width: 8),
                  if (canWrite)
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: t.risk == LabRisk.danger
                              ? Colors.redAccent
                              : null,
                        ),
                        onPressed: connected && !s.busy
                            ? () => onRunOp('write')
                            : null,
                        icon: s.busy
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_rounded, size: 15),
                        label: Text(
                          'ESCRIBIR',
                          style: GoogleFonts.spaceGrotesk(fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
              if (s.last != null) ...[
                const SizedBox(height: 8),
                LabResultView(result: s.last!),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: s.verdict == 'pass'
                            ? AppColors.tertiary.withValues(alpha: 0.18)
                            : null,
                        side: BorderSide(
                          color: AppColors.tertiary.withValues(
                            alpha: s.verdict == 'pass' ? 0.8 : 0.35,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      onPressed: () => onSelectVerdict('pass'),
                      child: Text(
                        '✅ CORRECTO',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: s.verdict == 'fail'
                            ? Colors.redAccent.withValues(alpha: 0.18)
                            : null,
                        side: BorderSide(
                          color: Colors.redAccent.withValues(
                            alpha: s.verdict == 'fail' ? 0.8 : 0.35,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      onPressed: () => onSelectVerdict('fail'),
                      child: Text(
                        '❌ ERROR',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: s.verdict == 'skip'
                            ? AppColors.textDim.withValues(alpha: 0.18)
                            : null,
                        side: BorderSide(
                          color: AppColors.textDim.withValues(
                            alpha: s.verdict == 'skip' ? 0.8 : 0.35,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      onPressed: () => onSelectVerdict('skip'),
                      child: Text(
                        '⏭ OMITIR',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          color: AppColors.textDim,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (s.verdict == 'pass' || s.verdict == 'fail') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: s.note,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5),
                  maxLines: 2,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: s.verdict == 'fail'
                        ? '¿Cómo reaccionó la moto? (obligatorio para calibrar predicciones)'
                        : 'Notas adicionales (opcional)',
                  ),
                  onChanged: onNoteChanged,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
