import '../models/lab_models.dart';

final labCatalogTelemetry = <LabCharTest>[
  // ================= F. AUTENTICACIÓN =================
  const LabCharTest(
    id: 'app_auth',
    name: 'APP_AUTH contador (c8eaf27b)',
    uuid: 'c8eaf27b-9fb7-4bc3-b11a-bf68c97b1b1f',
    category: 'AUTENTICACIÓN / HANDSHAKE (ALTO RIESGO)',
    readExpect: '4 bytes counter LE — incrementa en cada autenticación.',
    risk: LabRisk.danger,
    evidence: 'GATT: token 12B ASCII, lectura 4B counter',
    verifyHint: 'Solo lectura. Escritura inválida desincroniza la sesión.',
  ),
  const LabCharTest(
    id: 'authorization',
    name: 'AUTHORIZATION nonce (5e9a2c71)',
    uuid: '5e9a2c71-0b3d-4f86-a1c2-7d4e8f0b9a63',
    category: 'AUTENTICACIÓN / HANDSHAKE (ALTO RIESGO)',
    readExpect: '16 bytes = 15B nonce + 1B status (01 = aceptado).',
    risk: LabRisk.danger,
    evidence: 'Handshake de sesión de seguridad',
    verifyHint: 'Solo lectura de verificación.',
  ),
  const LabCharTest(
    id: 'unknown_91e84eb0',
    name: 'Bandera de autenticación 91e84eb0',
    uuid: '91e84eb0-dea0-436f-a157-f21d89443b32',
    category: 'AUTENTICACIÓN / HANDSHAKE (ALTO RIESGO)',
    readExpect: 'Protected read → 1 byte estático 0x01.',
    presets: [
      LabPreset('Leer', '', false, 'Retorna 01 estático.'),
    ],
    risk: LabRisk.safe,
    evidence: 'Protected Read dec "01"',
    observed: 'Confirmado en pruebas de laboratorio.',
    verifyHint: 'Solo lectura.',
  ),
  const LabCharTest(
    id: 'legacy_app_auth',
    name: 'LEGACY_APP_AUTH (4cb05df8)',
    uuid: '4cb05df8-9c3a-4d7e-9b2f-8e1a3c6d5b41',
    category: 'AUTENTICACIÓN / HANDSHAKE (ALTO RIESGO)',
    readExpect: 'Protected read → 12 bytes por sesión.',
    presets: [
      LabPreset('Leer', '', false, 'Descifra 12B de datos de sesión.'),
    ],
    risk: LabRisk.caution,
    evidence: 'Protected Read 12B auth data',
    verifyHint: 'Solo lectura, no escribir.',
  ),

  // ================= G. TABLERO / REGISTROS =================
  const LabCharTest(
    id: 'dashboard',
    name: 'Telemetría de tablero (6d2eb205)',
    uuid: '6d2eb205-6f9b-4ecf-bb1b-a5fad127c66c',
    category: 'TABLERO / REGISTROS (lectura cifrada)',
    readExpect: '45B cifrados → clave de sesión → protobuf: ODO, velocidad, corriente, V, SoC, temps.',
    presets: [
      LabPreset('Leer telemetría actual', '', false, 'Descifra cuadro de instrumentos en vivo.'),
    ],
    risk: LabRisk.safe,
    evidence: 'Polling continuo de 700ms en tablero',
    observed: 'Lectura verificada en carretera.',
    verifyHint: 'Verificar valores coherentes con el estado del vehículo.',
  ),
  const LabCharTest(
    id: 'bike_log',
    name: 'Registro del vehículo 108B (018e6a6f)',
    uuid: '018e6a6f-4bda-7b07-8586-1298248a8d5c',
    category: 'TABLERO / REGISTROS (lectura cifrada)',
    readExpect: '108B cifrados → descifrado protobuf: nombre, modelo, serial.',
    presets: [
      LabPreset('Leer', '', false, 'Descifra datos de identificación.'),
    ],
    risk: LabRisk.safe,
    evidence: 'LAB PASS · registros de prueba',
    observed: 'Protobuf con serial y modelo.',
    verifyHint: 'Solo lectura.',
  ),
  const LabCharTest(
    id: 'battery_log',
    name: 'Registro de batería 207B (84c7be0b)',
    uuid: '84c7be0b-7619-45c1-a503-95f4ff8736ed',
    category: 'TABLERO / REGISTROS (lectura cifrada)',
    readExpect: '207B cifrados → protobuf batería: V, I, celdas individuales, temperaturas.',
    presets: [
      LabPreset('Leer diagnóstico de batería', '', false, 'Muestra voltaje y estado de celdas.'),
    ],
    risk: LabRisk.safe,
    evidence: 'Módulo de diagnóstico de batería',
    observed: 'Valores concordantes con mediciones directas.',
    verifyHint: 'Comparar con pantalla de batería.',
  ),

  // ================= H. OTA / VESC =================
  const LabCharTest(
    id: 'vesc_char',
    name: 'Telemetría VESC (35a9b4f6)',
    uuid: '35a9b4f6-e5f5-405b-9b08-ada85d78cc12',
    category: 'OTA / VESC (NO escribir sin control)',
    readExpect: 'Protected read → 12 bytes = 3 x float32 LE: corriente motor, voltaje, duty cycle.',
    risk: LabRisk.safe,
    evidence: 'GHIDRA FUN_40156db0 empaqueta 3 flotantes',
    observed: 'Lectura de 3 flotantes verificado.',
    verifyHint: 'Leer y desempaquetar 3 floats de 32 bits.',
  ),
  const LabCharTest(
    id: 'ota_service',
    name: 'Servicio OTA (68311857)',
    uuid: '68311857-4f93-4060-a42d-16da35a5843c',
    category: 'OTA / VESC (NO escribir sin control)',
    readExpect: 'Solo lectura de diagnóstico para comprobar presencia de servicio.',
    presets: [
      LabPreset('Lectura de estado', '', false, 'Verifica presencia de características OTA.'),
    ],
    risk: LabRisk.danger,
    evidence: 'FAST_OTA_SERVICE + MAINPCB_FIRMWARE',
    observed: 'Canal de actualización de firmware de tarjetas.',
    verifyHint: 'NO emitir escrituras no supervisadas para evitar fallos de arranque.',
  ),
];

