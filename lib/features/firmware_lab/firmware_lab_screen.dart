// Laboratorio de Firmware (LAB) — validación y pruebas BLE con el vehículo.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ble/ble_controller.dart';
import '../../ui/app_theme.dart';
import 'lab_catalog.dart';
import 'models/lab_ui_state.dart';
import 'services/lab_results_storage.dart';
import 'services/lab_runner.dart';
import 'widgets/lab_custom_tester_card.dart';
import 'widgets/lab_filter_row.dart';
import 'widgets/lab_status_card.dart';
import 'widgets/lab_test_expansion_tile.dart';

class FirmwareLabScreen extends ConsumerStatefulWidget {
  const FirmwareLabScreen({super.key});

  @override
  ConsumerState<FirmwareLabScreen> createState() => _FirmwareLabScreenState();
}

class _FirmwareLabScreenState extends ConsumerState<FirmwareLabScreen> {
  final _storage = LabResultsStorage();
  final _ui = <String, LabTestUiState>{};
  final _verdictCounts = <String, int>{'pass': 0, 'fail': 0, 'skip': 0};
  String _filter = 'all';
  bool _autoReadBack = true;

  final _customUuid = TextEditingController();
  final _customInput = TextEditingController();
  bool _customHex = false;
  LabIoResult? _customLast;
  bool _customBusy = false;
  Timer? _noteDebounce;

  LabTestUiState _stateOf(String id) => _ui.putIfAbsent(id, LabTestUiState.new);
  late final BleController _ble;

  @override
  void initState() {
    super.initState();
    _ble = ref.read(bleProvider.notifier);
    _ble.setLabMode(true);
    _loadHistory();
  }

  @override
  void dispose() {
    _ble.setLabMode(false);
    _noteDebounce?.cancel();
    for (final u in _ui.values) {
      u.dispose();
    }
    _customUuid.dispose();
    _customInput.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final res = await _storage.loadHistory();
    if (!mounted) return;
    setState(() {
      _verdictCounts.addAll(res.counts);
      for (final e in res.lastPerTest.entries) {
        final s = _stateOf(e.key);
        s.verdict = e.value['verdict'] as String?;
        if (e.value['note'] is String && (e.value['note'] as String).isNotEmpty) {
          s.note.text = e.value['note'] as String;
        }
      }
    });
  }

  Future<void> _saveVerdict(LabCharTest t) async {
    final s = _stateOf(t.id);
    if (s.verdict == null) return;
    await _storage.saveVerdict(test: t, uiState: s);
    _verdictCounts.update(s.verdict!, (x) => x + 1, ifAbsent: () => 1);
    if (mounted) setState(() {});
  }

  Future<void> _shareResults() async {
    try {
      final f = await _storage.getFile();
      if (!await f.exists() || await f.length() == 0) {
        _toast('No hay resultados disponibles para exportar.');
        return;
      }
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], text: 'Resultados LAB BSKMT'));
    } catch (e) {
      _toast('Error al compartir: $e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.amber));
  }

  Future<void> _runOp(LabCharTest t, String op) async {
    final s = _stateOf(t.id);
    final connected = ref.read(bleProvider).phase == BlePhase.connected;
    final res = await LabRunner.runOp(
      context: context,
      ble: ref.read(bleProvider.notifier),
      connected: connected,
      test: t,
      uiState: s,
      op: op,
      autoReadBack: _autoReadBack,
      onToast: _toast,
    );
    if (res != null) s.last = res;
    if (mounted) setState(() {});
  }

  Future<void> _runCustom(String op) async {
    if (_customBusy) return;
    final connected = ref.read(bleProvider).phase == BlePhase.connected;
    setState(() => _customBusy = true);
    try {
      final res = await LabRunner.runCustom(
        ble: ref.read(bleProvider.notifier),
        connected: connected,
        uuid: _customUuid.text,
        input: _customInput.text,
        hex: _customHex,
        op: op,
        onToast: _toast,
      );
      if (res != null) _customLast = res;
    } finally {
      _customBusy = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);
    final connected = ble.phase == BlePhase.connected;

    final shown = labCatalog.where((t) {
      final v = _stateOf(t.id).verdict;
      return _filter == 'all' ||
          (_filter == 'pending' && v == null) ||
          (_filter == 'pass' && v == 'pass') ||
          (_filter == 'fail' && v == 'fail');
    }).toList();

    final grouped = <String, List<LabCharTest>>{};
    for (final t in shown) {
      grouped.putIfAbsent(t.category, () => []).add(t);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          '🧪 LABORATORIO DE FIRMWARE BSKMT',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            tooltip: 'Exportar resultados (JSONL)',
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            onPressed: _shareResults,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
        children: [
          LabStatusCard(
            ble: ble,
            connected: connected,
            verdictCounts: _verdictCounts,
            autoReadBack: _autoReadBack,
            onToggleAutoReadBack: (v) => setState(() => _autoReadBack = v),
            onSniffAll: () async {
              _toast('Escaneando todas las características legibles…');
              await ref.read(bleProvider.notifier).sniffAllCharacteristics();
            },
          ),
          const SizedBox(height: 12),
          LabCustomTesterCard(
            uuidController: _customUuid,
            inputController: _customInput,
            hex: _customHex,
            busy: _customBusy,
            connected: connected,
            lastResult: _customLast,
            onToggleHex: () => setState(() => _customHex = !_customHex),
            onRunOp: _runCustom,
          ),
          const SizedBox(height: 18),
          LabFilterRow(
            filter: _filter,
            verdictCounts: _verdictCounts,
            onSelectFilter: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 8),
          for (final cat in labCategories)
            if (grouped.containsKey(cat)) ...[
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Text(
                  cat,
                  style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDim),
                ),
              ),
              for (final t in grouped[cat]!) ...[
                LabTestExpansionTile(
                  test: t,
                  uiState: _stateOf(t.id),
                  connected: connected,
                  onToggleHex: () => setState(() => _stateOf(t.id).isHex = !_stateOf(t.id).isHex),
                  onSelectWriteMode: (m) => setState(() => _stateOf(t.id).modeOverride = m),
                  onSelectPreset: (i) => setState(() {
                    final s = _stateOf(t.id);
                    s.selectedPreset = i;
                    s.input.text = t.presets[i].data;
                    s.isHex = t.presets[i].hex;
                  }),
                  onRunOp: (op) => _runOp(t, op),
                  onSelectVerdict: (v) {
                    setState(() => _stateOf(t.id).verdict = v);
                    _saveVerdict(t);
                  },
                  onNoteChanged: (_) {
                    _noteDebounce?.cancel();
                    _noteDebounce = Timer(const Duration(milliseconds: 1200), () => _saveVerdict(t));
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
        ],
      ),
    );
  }
}
