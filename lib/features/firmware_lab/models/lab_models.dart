enum LabRisk { safe, caution, danger }

/// Modo de escritura en característica BLE.
enum LabWriteMode { none, plain, protected }

class LabPreset {
  final String label;
  final String data;
  final bool hex;
  final String prediction;
  const LabPreset(this.label, this.data, this.hex, this.prediction);
}

class LabCharTest {
  final String id;
  final String name;
  final String uuid;
  final String category;
  final LabWriteMode writeMode;
  final bool canRead;
  final String readExpect;
  final List<LabPreset> presets;
  final LabRisk risk;
  final String evidence;
  final String? observed;
  final String verifyHint;

  const LabCharTest({
    required this.id,
    required this.name,
    required this.uuid,
    required this.category,
    this.writeMode = LabWriteMode.none,
    this.canRead = true,
    this.readExpect = '',
    this.presets = const [],
    this.risk = LabRisk.safe,
    required this.evidence,
    this.observed,
    this.verifyHint = '',
  });

  String get shortId => uuid.substring(0, 8);
}

const labCategories = [
  'AJUSTES — MASTER_CONFIG (protegido, booleano)',
  'ENERGÍA & BLOQUEO',
  'INFORMACIÓN & ESTADO (lectura)',
  'BOCINA / LOCALIZADOR / TARJETA NFC',
  'CARGA',
  'AUTENTICACIÓN / HANDSHAKE (ALTO RIESGO)',
  'TABLERO / REGISTROS (lectura cifrada)',
  'OTA / VESC (NO escribir sin control)',
];

const kLabSettingsBool = 'Handler analiza BOOLEANO: payload[0] == ASCII \'1\' (0x31) '
    '? ACTIVADO : DESACTIVADO — cualquier otro valor se interpreta como DESACTIVADO. '
    'Read retorna RAW u8 (00/01), NO ASCII.';

