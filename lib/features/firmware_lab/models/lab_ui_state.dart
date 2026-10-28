import 'package:flutter/material.dart';
import 'package:mybike_app/core/ble/ble_controller.dart';
import 'lab_models.dart';

class LabTestUiState {
  final input = TextEditingController();
  bool isHex = false;
  LabWriteMode? modeOverride;
  int selectedPreset = -1;
  LabIoResult? last;
  bool busy = false;
  String? verdict;
  final note = TextEditingController();

  void dispose() {
    input.dispose();
    note.dispose();
  }
}
