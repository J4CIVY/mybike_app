enum CellBalanceGrade {
  unknown('Esperando telemetría BMS', 'Aún no se reciben los datos detallados de voltaje por celda desde la moto.'),
  excellent('Excelente', 'Diferencia de voltaje mínima, celdas perfectamente equilibradas.'),
  good('Bueno', 'Batería bien balanceada, rendimiento óptimo de carga y descarga.'),
  fair('Aceptable (Seguimiento)', 'Ligero desbalance entre celdas; se recomienda carga completa para equilibrar BMS.'),
  poor('Desbalance Alto', 'Desbalance considerable entre celdas (>80mV), conectar al cargador.'),
  critical('CRÍTICO / ALERTA', 'Riesgo grave de caída de tensión (>120mV), ¡evite aceleraciones bruscas!');

  final String label;
  final String description;
  const CellBalanceGrade(this.label, this.description);
}

enum ThermalStatus {
  cool('Óptima', 0xFF10B981),
  normal('Normal', 0xFF0EA5E9),
  warm('Tibia', 0xFFF59E0B),
  hot('Caliente', 0xFFF97316),
  critical('Peligro', 0xFFEF4444);

  final String label;
  final int colorValue;
  const ThermalStatus(this.label, this.colorValue);
}

class ThermalZone {
  final String name;
  final double temperature;
  final double warningTemp;
  final double criticalTemp;
  final ThermalStatus status;

  const ThermalZone({
    required this.name,
    required this.temperature,
    required this.warningTemp,
    required this.criticalTemp,
    required this.status,
  });

  factory ThermalZone.evaluate({
    required String name,
    required double temp,
    required double warningTemp,
    required double criticalTemp,
  }) {
    final ThermalStatus status;
    if (temp <= 0) {
      status = ThermalStatus.cool;
    } else if (temp <= 35) {
      status = ThermalStatus.cool;
    } else if (temp < warningTemp - 10) {
      status = ThermalStatus.normal;
    } else if (temp < warningTemp) {
      status = ThermalStatus.warm;
    } else if (temp < criticalTemp) {
      status = ThermalStatus.hot;
    } else {
      status = ThermalStatus.critical;
    }

    return ThermalZone(
      name: name,
      temperature: temp,
      warningTemp: warningTemp,
      criticalTemp: criticalTemp,
      status: status,
    );
  }
}

class ObdDiagnosticItem {
  final int id;
  final String name;
  final String code;
  final bool isHealthy;
  final String severity; // 'Normal', 'Advertencia', 'Urgente'
  final String description;
  final String recommendation;

  const ObdDiagnosticItem({
    required this.id,
    required this.name,
    required this.code,
    required this.isHealthy,
    required this.severity,
    required this.description,
    required this.recommendation,
  });
}

class BatteryHealthReport {
  final List<double> cellVoltages;
  final int cellCount;
  final double maxCellVoltage;
  final int maxCellIndex;
  final double minCellVoltage;
  final int minCellIndex;
  final double avgCellVoltage;
  final double deltaVoltageMv;
  final CellBalanceGrade balanceGrade;
  final int healthPercentage;
  final double packVoltage;
  final double currentAmp;
  final bool isBalancing;
  final int chargeCycles;
  final double internalResistanceMo;
  final ThermalZone motorThermal;
  final ThermalZone ecuThermal;
  final ThermalZone bmsThermal;
  final List<ObdDiagnosticItem> obdItems;
  final int safetyScore;
  final bool hasLiveTelemetry;
  final bool isSimulated;
  final String packConfigName;
  final int rawErrorCode;

  const BatteryHealthReport({
    required this.cellVoltages,
    required this.cellCount,
    required this.maxCellVoltage,
    required this.maxCellIndex,
    required this.minCellVoltage,
    required this.minCellIndex,
    required this.avgCellVoltage,
    required this.deltaVoltageMv,
    required this.balanceGrade,
    required this.healthPercentage,
    required this.packVoltage,
    required this.currentAmp,
    required this.isBalancing,
    required this.chargeCycles,
    required this.internalResistanceMo,
    required this.motorThermal,
    required this.ecuThermal,
    required this.bmsThermal,
    required this.obdItems,
    required this.safetyScore,
    this.hasLiveTelemetry = false,
    this.isSimulated = false,
    this.packConfigName = 'Esperando BMS...',
    this.rawErrorCode = 0,
  });
}

