import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/ble/ble_controller.dart';
import '../lab_catalog.dart';
import '../models/lab_ui_state.dart';
import '../widgets/lab_risk_dialog.dart';

class LabRunner {
  static List<int>? parseInput(String raw, bool hex) {
    var s = raw.trim();
    if (s == '__NOW__') {
      final n = DateTime.now();
      s = '${n.hour * 3600 + n.minute * 60 + n.second}';
    }
    if (s.isEmpty) return hex ? <int>[] : <int>[];
    if (!hex) return s.codeUnits;
    s = s.replaceAll(' ', '').replaceAll('0x', '').toLowerCase();
    if (s.length % 2 != 0 || !RegExp(r'^[0-9a-f]*$').hasMatch(s)) return null;
    return [for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)];
  }

  static Future<LabIoResult?> runOp({
    required BuildContext context,
    required BleController ble,
    required bool connected,
    required LabCharTest test,
    required LabTestUiState uiState,
    required String op,
    required bool autoReadBack,
    required void Function(String msg) onToast,
  }) async {
    if (uiState.busy) return null;
    if (!connected) {
      onToast('Vehículo no conectado — no es posible ejecutar la prueba.');
      return null;
    }

    List<int>? data;
    if (op != 'read') {
      data = parseInput(uiState.input.text, uiState.isHex);
      if (data == null) {
        onToast('Entrada HEX inválida para ${test.shortId}');
        return null;
      }
      if (!await LabRiskDialog.confirm(context, test, op == 'read' ? 'lectura' : 'escritura')) return null;
    }

    uiState.busy = true;
    try {
      LabIoResult r;
      if (op == 'read') {
        r = await ble.labRead(test.uuid, testId: test.id);
      } else {
        final plain = (uiState.modeOverride ?? test.writeMode) == LabWriteMode.plain;
        r = plain
            ? await ble.labWritePlain(test.uuid, data!, testId: test.id)
            : await ble.labWriteProtected(test.uuid, data!, testId: test.id);
        if (autoReadBack && r.ok && test.canRead) {
          await Future.delayed(const Duration(milliseconds: 200));
          return await ble.labRead(test.uuid, testId: test.id);
        }
      }
      return r;
    } finally {
      uiState.busy = false;
    }
  }

  static Future<LabIoResult?> runCustom({
    required BleController ble,
    required bool connected,
    required String uuid,
    required String input,
    required bool hex,
    required String op,
    required void Function(String msg) onToast,
  }) async {
    final cleanUuid = uuid.trim().toLowerCase();
    if (cleanUuid.isEmpty) {
      onToast('Ingresa el UUID de la característica a probar.');
      return null;
    }
    if (!connected) {
      onToast('Vehículo no conectado.');
      return null;
    }
    List<int>? data;
    if (op != 'read') {
      data = parseInput(input, hex);
      if (data == null) {
        onToast('Entrada HEX inválida.');
        return null;
      }
    }
    return op == 'read'
        ? await ble.labRead(cleanUuid, testId: 'custom')
        : (op == 'write_plain'
            ? await ble.labWritePlain(cleanUuid, data!, testId: 'custom')
            : await ble.labWriteProtected(cleanUuid, data!, testId: 'custom'));
  }
}

