import 'dart:math';
import '../proto/bike_log.dart';

class ChargingStatusReport {
  final bool isCharging;
  final String stageName;
  final int stage;
  final int powerWatts;
  final double? gridVoltageRms;
  final bool isGridUnstable;
  final int? fetTemp;
  final bool isFetOverheat;
  final Duration etaTotal;
  final Duration eta80;
  final Duration boostRemaining;
  final String profileName;
  final double energyChargedKwh;
  final int targetSocLimit;

  const ChargingStatusReport({
    required this.isCharging,
    required this.stageName,
    required this.stage,
    required this.powerWatts,
    required this.gridVoltageRms,
    required this.isGridUnstable,
    required this.fetTemp,
    required this.isFetOverheat,
    required this.etaTotal,
    required this.eta80,
    required this.boostRemaining,
    required this.profileName,
    required this.energyChargedKwh,
    this.targetSocLimit = 80,
  });
}

class ChargingRouterService {
  ChargingRouterService._();

  static ChargingStatusReport analyzeCharging({
    BikeLogMsg? telemetry,
    int targetLimit = 80,
  }) {
    final charger = telemetry?.charging;
    final isCharging = charger != null || (telemetry != null && telemetry.phase > 0.5);

    final power = charger?.power ??
        (isCharging && telemetry != null && telemetry.voltage > 0
            ? (telemetry.voltage * telemetry.phase.abs()).round()
            : 0);

    final double? vin = (charger != null && charger.vinRms > 0) ? charger.vinRms.toDouble() : null;
    final isGridUnstable = vin != null && (vin < 190.0 || vin > 255.0);
    final int? fetTemp = (charger != null && charger.fetTemp > 0) ? charger.fetTemp : null;
    final isFetHot = fetTemp != null && fetTemp > 65;

    final stage = charger?.stage ?? (isCharging ? 2 : 0);
    final stageName = switch (stage) {
      0 => 'No conectado',
      1 => 'Iniciando cargador',
      2 => isCharging
          ? 'Cargando batería (Corriente ${telemetry?.phase.abs().toStringAsFixed(1) ?? "--"}A)'
          : 'Carga rápida Boost',
      3 => 'Carga de protección (CV)',
      4 => 'Carga completa 100% (Mantenimiento)',
      5 => 'Desconexión segura / Error de carga',
      _ => 'Cargando',
    };

    final profileName = switch (charger?.profile ?? 0) {
      1 => 'Carga Ultra-Rápida (SuperBoost 4kW)',
      2 => 'Carga nocturna protegida (Eco Night)',
      _ => isCharging ? 'Cargador estándar AC' : 'Sin carga',
    };

    final currentPercent = telemetry?.percent ?? 0;
    final totalEtaSec = charger?.etaSec ?? _estimateEtaSeconds(currentPercent, 100, power);
    final eta80Sec = _estimateEtaSeconds(currentPercent, targetLimit, power);
    final boostSec = charger?.boostLeftSec ?? 0;

    final energyKwh = (power > 0 && charger != null)
        ? (power * charger.stageSec) / 3600000.0
        : 0.0;

    return ChargingStatusReport(
      isCharging: isCharging,
      stageName: stageName,
      stage: stage,
      powerWatts: power,
      gridVoltageRms: vin,
      isGridUnstable: isGridUnstable,
      fetTemp: fetTemp,
      isFetOverheat: isFetHot,
      etaTotal: Duration(seconds: max(0, totalEtaSec)),
      eta80: Duration(seconds: max(0, eta80Sec)),
      boostRemaining: Duration(seconds: max(0, boostSec)),
      profileName: profileName,
      energyChargedKwh: energyKwh,
      targetSocLimit: targetLimit,
    );
  }

  static int _estimateEtaSeconds(int currentPct, int targetPct, int powerWatts) {
    if (currentPct >= targetPct) return 0;
    final pwr = powerWatts > 200 ? powerWatts : 1200;
    final neededPct = targetPct - currentPct;
    final neededWh = neededPct * 70.0;
    final hours = (neededWh / (pwr * 0.92));
    return (hours * 3600).round();
  }
}
