class Gatt {
  Gatt._();

  // Services
  static const dashboardService = 'cf6900a7-4520-4a4c-977c-82979e8baccf';
  static const authService = '10cb0217-ff02-4474-a1ef-6fd88b5bdaea';
  static const infoService = 'd4905f67-8931-4faa-8c61-86ec7490f3c5';
  static const otaService = '5b6d1069-a0bc-4875-ba5b-fdc94647d918';
  static const programmingService = 'f7e2c8a1-3d5b-4906-9e1f-8c0a2b4d6e8f';
  static const chargingService = '8a2b0d00-9c52-4f5a-9d3e-1f7a0c4b6e21';

  // Auth Characteristics
  static const appAuthChar = 'c8eaf27b-9fb7-4bc3-b11a-bf68c97b1b1f';
  static const authorizationChar = '5e9a2c71-0b3d-4f86-a1c2-7d4e8f0b9a63';
  static const onOffBikeChar = '4cb05df8-9c3a-4d7e-9b2f-8e1a3c6d5b41';
  static const legacyAppAuthChar = '4cb05df8-9c3a-4d7e-9b2f-8e1a3c6d5b41';
  static const authFeatureFlagChar = '91e84eb0-dea0-436f-a157-f21d89443b32';

  // Dashboard Characteristics
  static const dashboardCharacteristic = '6d2eb205-6f9b-4ecf-bb1b-a5fad127c66c';
  static const bikeLogCharacteristic = '018e6a6f-4bda-7b07-8586-1298248a8d5c';
  static const batteryLogCharacteristic = '84c7be0b-7619-45c1-a503-95f4ff8736ed';

  // Info Characteristics
  static const firmwareVersion = 'd1da175e-b1b5-4248-8f36-98c9482b8d24';
  static const bikeSerial = '44e2bde6-9cd5-4159-9d43-a3e3f4e9c737';
  static const currentTimeChar = '44e2bde6-9cd5-4159-9d43-a3e3f4e9c737';
  static const timeSyncChar = '44e2bde6-9cd5-4159-9d43-a3e3f4e9c737';
  static const deviceSerialChar = '041d5a06-e35f-42d3-92c8-0d421186d2f3';
  static const sessionUuid = '87efab0d-9e32-4ab8-8916-ed7cb72d819a';
  static const powerSwitchChar = '350d9a82-b3f3-4213-bdda-6403be495f53';
  static const findBikeChar = '350d9a82-b3f3-4213-bdda-6403be495f53';
  static const beepScanChar = '87efab0d-9e32-4ab8-8916-ed7cb72d819a';
  static const powerProtectedChar = 'eec8fd7f-4709-441a-a838-b9eb3066ede4';

  // OTA Characteristics
  @Deprecated('Pertenece al servicio OTA')
  static const beepMainChar = 'e0b2b4b4-4b1e-4f3e-8f1e-6b3e4b4b4b4b';
  static const otaChar1 = '68311857-4f93-4060-a42d-16da35a5843c';
  static const otaChar2 = '07765f94-d850-4e87-a2cf-6bae5d9a0b67';
  static const otaChar3 = '4244dedb-7b6b-4774-9525-d37fde1c67da';

  // Settings & Master Config
  static const speedLimitChar = '0a19a49a-23bc-45ab-b2e9-4bf31665c76b';
  static const eceModeChar = '3b56ac38-60fb-40f8-a42c-fa09e0714e44';
  static const grabModeChar = 'a1d8e7c4-5b3f-4902-8a6e-9c0d2f1e3b4a';
  static const idlingTurnOffChar = '69c79762-9dd3-413e-9aaf-bdd147563c93';
  static const distanceChar = '5d681587-c268-4bd3-9560-66ec79dbfdc8';
  static const powerOnOffChar = '7f13fe5c-1971-4fec-97fd-f90e16cf8c28';
  static const lockBikeChar = '7f13fe5c-1971-4fec-97fd-f90e16cf8c28';

  // Advertencia de seguridad: alternar este flag pausa las tareas VESC/CAN en el firmware
  static const vescProgrammingChar = 'b0ca953d-46db-4451-b457-b81696d4e3ae';

  static const turnOffBmsChar = '1f4108ad-8a70-4165-87d0-88e16f433758';
  static const resetBleChar = 'a23df519-5279-4fdc-87ef-9b9e65b4a31f';
  static const addCardChar = 'c75ebe03-ea2f-4c0e-a720-1e7112a72d81';
  static const bikeNameChar = '460a5bc5-a5f5-4968-b548-dc218935245e';
  static const bikeModelChar = '4aae98e9-90b5-492f-8180-9538fa2c843d';
  static const fwNameChar = '88c30d2c-f80f-43f8-b0cb-fc1e4ae49be9';
  static const vescSnapshotChar = '35a9b4f6-e5f5-405b-9b08-ada85d78cc12';
  static const boardManifestChar = '73d50009-ed01-4bb1-bdc2-e89b725a91db';
  static const logBufferStatsChar = '2c73e84e-0150-4be2-928c-dee3e8e21b52';
  static const chargingProfileChar = '8a2b0d10-9c52-4f5a-9d3e-1f7a0c4b6e21';

  // Operating Constants
  static const bikeName = 'dat.bik3';
  static const androidMtu = 517;
  static const dashboardPollMs = 700;
  static const hmacTagLen = 4;
  static const authStatusOk = 0x01;
  static const defaultPairingToken = 'c97eb99d-c695-4b5f-8a99-7b24ff2a7980';
  static const defaultPassword = '58607';
}
