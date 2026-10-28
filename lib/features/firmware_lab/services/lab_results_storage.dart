import 'dart:convert';
import 'dart:io';

import '../../../core/ble/ble_logger.dart';
import '../lab_catalog.dart';
import '../models/lab_ui_state.dart';

class LabResultsStorage {
  File? _resultsFile;

  Future<File> getFile() async {
    if (_resultsFile != null) return _resultsFile!;
    final dir = await BleLogger.dirPath();
    return _resultsFile = File('$dir/firmware_lab_results.jsonl');
  }

  Future<({Map<String, int> counts, Map<String, Map<String, dynamic>> lastPerTest})> loadHistory() async {
    final counts = <String, int>{'pass': 0, 'fail': 0, 'skip': 0};
    final lastPerTest = <String, Map<String, dynamic>>{};
    try {
      final f = await getFile();
      if (!await f.exists()) return (counts: counts, lastPerTest: lastPerTest);
      for (final line in await f.readAsLines()) {
        if (line.trim().isEmpty) continue;
        try {
          final rec = jsonDecode(line) as Map<String, dynamic>;
          final id = rec['test_id'] as String?;
          if (id != null) lastPerTest[id] = rec;
        } catch (_) {}
      }
      for (final rec in lastPerTest.values) {
        final v = rec['verdict'] as String?;
        if (v != null && counts.containsKey(v)) counts[v] = counts[v]! + 1;
      }
    } catch (_) {}
    return (counts: counts, lastPerTest: lastPerTest);
  }

  Future<void> saveVerdict({
    required LabCharTest test,
    required LabTestUiState uiState,
  }) async {
    final v = uiState.verdict;
    if (v == null) return;
    final r = uiState.last;
    final dec = r?.decrypted;
    final rec = {
      'ts': DateTime.now().toIso8601String(),
      'test_id': test.id,
      'name': test.name,
      'uuid': test.uuid,
      'op': r?.op ?? '',
      'input': uiState.input.text,
      'input_hex': uiState.isHex,
      'verdict': v,
      'note': uiState.note.text.trim(),
      'last_raw': r != null && r.payload.isNotEmpty ? BleLogger.hex(r.payload, maxBytes: 48) : '',
      'last_dec': dec != null && dec.isNotEmpty ? BleLogger.hex(dec, maxBytes: 48) : '',
      'last_error': r?.error ?? '',
      'prediction': uiState.selectedPreset >= 0 && uiState.selectedPreset < test.presets.length
          ? test.presets[uiState.selectedPreset].prediction
          : test.readExpect,
    };
    BleLogger.instance.event('lab_verdict', Map<String, dynamic>.from(rec));
    try {
      final f = await getFile();
      await f.create(recursive: true);
      await f.writeAsString('${jsonEncode(rec)}\n', mode: FileMode.append);
    } catch (_) {}
  }
}

