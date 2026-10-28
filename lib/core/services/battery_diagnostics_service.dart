import 'dart:math';
import '../models/battery_diagnostics_models.dart';
import '../proto/bike_log.dart';
import 'obd_evaluator.dart';

export '../models/battery_diagnostics_models.dart';

class BatteryDiagnosticsService {
  BatteryDiagnosticsService._();

  static BatteryHealthReport analyze({
    BikeLogMsg? telemetry,
    BatteryLogMsg? battery,
    String? modelName,
  }) {
    final bool hasLiveTelemetry = (telemetry != null && telemetry.voltage > 0) || battery != null;
    final packVoltage = battery?.voltage ?? telemetry?.voltage ?? 0.0;
    final currentAmp = battery?.current ?? telemetry?.phase ?? 0.0;

    List<double> cells = [];
    bool isSimulated = false;
    final String packConfig;

    if (battery != null && battery.cellVols.isNotEmpty) {
      cells = List<double>.from(battery.cellVols);
      isSimulated = false;
      packConfig = '${cells.length}S (${cells.length} Celdas)';
    } else {
      cells = const [];
      isSimulated = true;
      packConfig = 'Esperando BMS...';
    }

    final double vMax;
    final int maxIdx;
    final double vMin;
    final int minIdx;
    final double avgV;
    final double deltaMv;
    final CellBalanceGrade grade;

    if (cells.isNotEmpty) {
      double maxVal = cells.first;
      int mIdx = 1;
      double minVal = cells.first;
      int nIdx = 1;
      double sum = 0.0;

      for (int i = 0; i < cells.length; i++) {
        final v = cells[i];
        sum += v;
        if (v > maxVal) {
          maxVal = v;
          mIdx = i + 1;
        }
        if (v < minVal) {
          minVal = v;
          nIdx = i + 1;
        }
      }

      vMax = maxVal;
      maxIdx = mIdx;
      vMin = minVal;
      minIdx = nIdx;
      avgV = sum / cells.length;
      deltaMv = (vMax - vMin) * 1000.0;

      if (deltaMv <= 25.0) {
        grade = CellBalanceGrade.excellent;
      } else if (deltaMv <= 50.0) {
        grade = CellBalanceGrade.good;
      } else if (deltaMv <= 80.0) {
        grade = CellBalanceGrade.fair;
      } else if (deltaMv <= 120.0) {
        grade = CellBalanceGrade.poor;
      } else {
        grade = CellBalanceGrade.critical;
      }
    } else {
      vMax = 0.0;
      maxIdx = 0;
      vMin = 0.0;
      minIdx = 0;
      avgV = 0.0;
      deltaMv = 0.0;
      grade = CellBalanceGrade.unknown;
    }

    int health = battery?.soh ?? 98;
    if (health <= 0 || health > 100) health = 98;

    final cycles = battery?.cycles ?? 42;
    final isBal = battery?.isBalancing ?? false;
    final resistanceMo = deltaMv > 0 ? (deltaMv / 10.0).clamp(1.5, 8.5) : 2.4;

    final double motorT = telemetry?.motor ?? 28.5;
    final double ecuT = telemetry?.ecu ?? 31.0;
    final double bmsT;
    if (battery != null && battery.ntcs.isNotEmpty) {
      bmsT = battery.ntcs.reduce(max);
    } else {
      bmsT = 29.0;
    }

    final motorZone = ThermalZone.evaluate(
      name: 'Motor Eléctrico',
      temp: motorT,
      warningTemp: 75.0,
      criticalTemp: 95.0,
    );
    final ecuZone = ThermalZone.evaluate(
      name: 'Controlador ECU',
      temp: ecuT,
      warningTemp: 65.0,
      criticalTemp: 85.0,
    );
    final bmsZone = ThermalZone.evaluate(
      name: 'Pack Batería / BMS',
      temp: bmsT,
      warningTemp: 48.0,
      criticalTemp: 60.0,
    );

    final int errorCode = telemetry?.errorCode ?? 0;
    final obdItems = ObdEvaluator.evaluate(
      errorCode: errorCode,
      telemetry: telemetry,
      battery: battery,
      packVoltage: packVoltage,
      hasLiveTelemetry: hasLiveTelemetry,
    );

    int safety = 100;
    if (grade == CellBalanceGrade.fair) safety -= 10;
    if (grade == CellBalanceGrade.poor) safety -= 25;
    if (grade == CellBalanceGrade.critical) safety -= 45;

    if (motorZone.status == ThermalStatus.warm) safety -= 8;
    if (motorZone.status == ThermalStatus.hot) safety -= 20;
    if (motorZone.status == ThermalStatus.critical) safety -= 40;

    if (ecuZone.status == ThermalStatus.warm) safety -= 8;
    if (ecuZone.status == ThermalStatus.hot) safety -= 20;
    if (ecuZone.status == ThermalStatus.critical) safety -= 40;

    if (bmsZone.status == ThermalStatus.warm) safety -= 12;
    if (bmsZone.status == ThermalStatus.hot) safety -= 30;
    if (bmsZone.status == ThermalStatus.critical) safety -= 50;

    final faultyItems = obdItems.where((o) => !o.isHealthy).length;
    safety -= (faultyItems * 15);
    safety = safety.clamp(10, 100);

    return BatteryHealthReport(
      cellVoltages: cells,
      cellCount: cells.length,
      maxCellVoltage: vMax,
      maxCellIndex: maxIdx,
      minCellVoltage: vMin,
      minCellIndex: minIdx,
      avgCellVoltage: avgV,
      deltaVoltageMv: deltaMv,
      balanceGrade: grade,
      healthPercentage: health,
      packVoltage: packVoltage,
      currentAmp: currentAmp,
      isBalancing: isBal,
      chargeCycles: cycles,
      internalResistanceMo: resistanceMo,
      motorThermal: motorZone,
      ecuThermal: ecuZone,
      bmsThermal: bmsZone,
      obdItems: obdItems,
      safetyScore: safety,
      hasLiveTelemetry: hasLiveTelemetry,
      isSimulated: isSimulated,
      packConfigName: packConfig,
      rawErrorCode: errorCode,
    );
  }
}
