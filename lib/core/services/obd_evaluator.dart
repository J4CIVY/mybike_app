import '../models/battery_diagnostics_models.dart';
import '../proto/bike_log.dart';

class ObdEvaluator {
  ObdEvaluator._();

  static List<ObdDiagnosticItem> evaluate({
    required int errorCode,
    BikeLogMsg? telemetry,
    BatteryLogMsg? battery,
    required double packVoltage,
    required bool hasLiveTelemetry,
  }) {
    if (!hasLiveTelemetry) {
      return const [
        ObdDiagnosticItem(
          id: 1,
          name: 'Controlador de Potencia (DRV)',
          code: 'VESC-FAULT-03',
          isHealthy: true,
          severity: 'Esperando',
          description: 'Sin conexión — Esperando telemetría de la moto.',
          recommendation: 'Conecta la moto por Bluetooth para diagnosticar etapas MOSFET.',
        ),
        ObdDiagnosticItem(
          id: 2,
          name: 'Protección Sobrecorriente',
          code: 'VESC-FAULT-04',
          isHealthy: true,
          severity: 'Esperando',
          description: 'Sin conexión — Esperando telemetría de la moto.',
          recommendation: 'Conecta la moto para diagnosticar corriente del inversor.',
        ),
        ObdDiagnosticItem(
          id: 3,
          name: 'Temperatura Inversor ECU',
          code: 'VESC-TEMP-FET',
          isHealthy: true,
          severity: 'Esperando',
          description: 'Sin conexión — Esperando telemetría de la moto.',
          recommendation: 'Conecta la moto para monitorear temperatura de la ECU.',
        ),
        ObdDiagnosticItem(
          id: 4,
          name: 'Temperatura del Motor',
          code: 'VESC-TEMP-MOT',
          isHealthy: true,
          severity: 'Esperando',
          description: 'Sin conexión — Esperando telemetría de la moto.',
          recommendation: 'Conecta la moto para monitorear temperatura del motor.',
        ),
        ObdDiagnosticItem(
          id: 5,
          name: 'Voltaje Bajo / Descarga Profunda',
          code: 'VESC-FAULT-02',
          isHealthy: true,
          severity: 'Esperando',
          description: 'Sin conexión — Esperando telemetría de la moto.',
          recommendation: 'Conecta la moto para medir voltaje del pack.',
        ),
        ObdDiagnosticItem(
          id: 6,
          name: 'Sobretensión Eléctrica',
          code: 'VESC-FAULT-01',
          isHealthy: true,
          severity: 'Esperando',
          description: 'Sin conexión — Esperando telemetría de la moto.',
          recommendation: 'Conecta la moto para verificar voltaje de bus y recup.',
        ),
        ObdDiagnosticItem(
          id: 7,
          name: 'Sensor de Posición / Encoder Rotor',
          code: 'VESC-FAULT-ENC',
          isHealthy: true,
          severity: 'Esperando',
          description: 'Sin conexión — Esperando telemetría de la moto.',
          recommendation: 'Conecta la moto para comprobar señal del encoder.',
        ),
        ObdDiagnosticItem(
          id: 8,
          name: 'Sensor Térmico de Celdas (BMS NTC)',
          code: 'BMS-TEMP-NTC',
          isHealthy: true,
          severity: 'Esperando',
          description: 'Sin conexión — Esperando telemetría de la moto.',
          recommendation: 'Conecta la moto para monitorear sensores NTC.',
        ),
      ];
    }

    final bool isDrvFault = errorCode == 3;
    final bool isOverCurrent = errorCode == 4 || errorCode == 18;
    final bool isEcuOverTemp = errorCode == 5 || (telemetry != null && telemetry.ecu > 75.0);
    final bool isMotorOverTemp = errorCode == 6 || (telemetry != null && telemetry.motor > 85.0);
    final bool isOverVoltage = errorCode == 1;
    final bool isUnderVoltage = errorCode == 2 || (packVoltage > 0.0 && packVoltage < 65.0);
    final bool isBmsOverTemp = battery != null && battery.ntcs.any((t) => t > 55.0);
    final bool isSensorFault = errorCode == 11 || errorCode == 12 || errorCode == 13 ||
        errorCode == 20 || errorCode == 21 || errorCode == 22;

    return [
      ObdDiagnosticItem(
        id: 1,
        name: 'Controlador de Potencia (DRV)',
        code: 'VESC-FAULT-03',
        isHealthy: !isDrvFault,
        severity: isDrvFault ? 'Urgente' : 'Normal',
        description: isDrvFault
            ? 'Falla de hardware en el circuito excitador MOSFET (DRV830x). El inversor se protegió para evitar cortocircuito.'
            : 'Módulo excitador MOSFET operando normalmente con voltajes de compuerta estables.',
        recommendation: isDrvFault
            ? 'Apaga la moto inmediatamente y contacta a ARPHA o un taller aliado BSKMT.'
            : 'Etapa de potencia en perfecto estado.',
      ),
      ObdDiagnosticItem(
        id: 2,
        name: 'Protección Sobrecorriente',
        code: 'VESC-FAULT-04',
        isHealthy: !isOverCurrent,
        severity: isOverCurrent ? 'Urgente' : 'Normal',
        description: isOverCurrent
            ? 'La corriente de descarga instantánea superó el límite absoluto del inversor (>350A).'
            : 'Corriente dentro de los límites seguros y de diseño.',
        recommendation: isOverCurrent
            ? 'Detén la moto y espera 2 minutos. Evita aceleraciones bruscas en pendientes muy empinadas con sobrepeso.'
            : 'Consumo de corriente nominal óptimo.',
      ),
      ObdDiagnosticItem(
        id: 3,
        name: 'Temperatura Inversor ECU',
        code: 'VESC-TEMP-FET',
        isHealthy: !isEcuOverTemp,
        severity: isEcuOverTemp ? 'Advertencia' : 'Normal',
        description: isEcuOverTemp
            ? 'Temperatura de la ECU superior al límite seguro (${telemetry?.ecu.toStringAsFixed(1) ?? "80"}°C). Potencia limitada por seguridad.'
            : 'Temperatura de la ECU en rango ideal (${telemetry?.ecu.toStringAsFixed(1) ?? "30"}°C). Disipación efectiva.',
        recommendation: isEcuOverTemp
            ? 'Reduce la velocidad y deja reposar la moto 10-15 minutos en un lugar fresco.'
            : 'Disipación térmica de la ECU excelente.',
      ),
      ObdDiagnosticItem(
        id: 4,
        name: 'Temperatura del Motor',
        code: 'VESC-TEMP-MOT',
        isHealthy: !isMotorOverTemp,
        severity: isMotorOverTemp ? 'Advertencia' : 'Normal',
        description: isMotorOverTemp
            ? 'El sensor térmico detectó temperatura elevada en el embobinado del motor (${telemetry?.motor.toStringAsFixed(1) ?? "85"}°C).'
            : 'Temperatura del motor en rango óptimo (${telemetry?.motor.toStringAsFixed(1) ?? "32"}°C).',
        recommendation: isMotorOverTemp
            ? 'Permite que el motor se enfríe antes de continuar una ruta exigente.'
            : 'Motor y transmisión en excelente estado térmico.',
      ),
      ObdDiagnosticItem(
        id: 5,
        name: 'Voltaje Bajo / Descarga Profunda',
        code: 'VESC-FAULT-02',
        isHealthy: !isUnderVoltage,
        severity: isUnderVoltage ? 'Advertencia' : 'Normal',
        description: isUnderVoltage
            ? 'Voltaje de la batería por debajo del umbral de corte (${packVoltage.toStringAsFixed(1)}V). Modo ahorro activado.'
            : 'Voltaje estable (${packVoltage.toStringAsFixed(1)}V), sin caída de tensión anormal.',
        recommendation: isUnderVoltage
            ? 'Conecta la moto al cargador lo antes posible. Evita mantenerla descargada al 0%.'
            : 'Suministro de energía estable y saludable.',
      ),
      ObdDiagnosticItem(
        id: 6,
        name: 'Sobretensión Eléctrica',
        code: 'VESC-FAULT-01',
        isHealthy: !isOverVoltage,
        severity: isOverVoltage ? 'Urgente' : 'Normal',
        description: isOverVoltage
            ? 'Voltaje de bus por encima del límite máximo (>98V), usualmente por freno regenerativo con batería al 100%.'
            : 'Voltaje de bus dentro de márgenes de seguridad garantizados.',
        recommendation: isOverVoltage
            ? 'Evita frenado regenerativo continuo en descensos cuando la batería esté al 100% de carga.'
            : 'Sistema de regulación de bus funcionando correctamente.',
      ),
      ObdDiagnosticItem(
        id: 7,
        name: 'Sensor de Posición / Encoder Rotor',
        code: 'VESC-FAULT-ENC',
        isHealthy: !isSensorFault,
        severity: isSensorFault ? 'Urgente' : 'Normal',
        description: isSensorFault
            ? 'Pérdida de señal o amplitud irregular de ángulo en el sensor encoder del motor.'
            : 'Señal FOC perfectamente sincronizada con los polos magnéticos del rotor.',
        recommendation: isSensorFault
            ? 'Revisa el conector del encoder y el cableado del sensor del motor.'
            : 'Sensor de rotación preciso y calibrado.',
      ),
      ObdDiagnosticItem(
        id: 8,
        name: 'Sensor Térmico de Celdas (BMS NTC)',
        code: 'BMS-TEMP-NTC',
        isHealthy: !isBmsOverTemp,
        severity: isBmsOverTemp ? 'Urgente' : 'Normal',
        description: isBmsOverTemp
            ? 'Los sensores térmicos NTC detectaron sobrecalentamiento en las celdas de batería (>55°C).'
            : 'Temperatura de celdas homogénea dentro del rango óptimo para máxima vida útil.',
        recommendation: isBmsOverTemp
            ? '¡PELIGRO! Apaga la moto de inmediato. No conectes el cargador mientras persista la temperatura alta.'
            : 'Ambiente térmico del pack de celdas óptimo.',
      ),
    ];
  }
}

