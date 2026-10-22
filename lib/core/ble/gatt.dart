import 'package:mybike_app/core/security/secure_key_manager.dart';

class Gatt {
  Gatt._();

  static const dashboardService = 'cf6900a7-4520-4a4c-977c-82979e8baccf';

  static const authService = '10cb0217-ff02-4474-a1ef-6fd88b5bdaea';

  static const infoService = 'd4905f67-8931-4faa-8c61-86ec7490f3c5';

  static const otaService = '5b6d1069-a0bc-4875-ba5b-fdc94647d918';

  static const programmingService = 'f7e2c8a1-3d5b-4906-9e1f-8c0a2b4d6e8f';

  static const appAuthChar = 'c8eaf27b-9fb7-4bc3-b11a-bf68c97b1b1f';

  static const authorizationChar = '5e9a2c71-0b3d-4f86-a1c2-7d4e8f0b9a63';

  static const onOffBikeChar = '4cb05df8-9c3a-4d7e-9b2f-8e1a3c6d5b41';

  static const dashboardCharacteristic = '6d2eb205-6f9b-4ecf-bb1b-a5fad127c66c';

  static const bikeLogCharacteristic = '018e6a6f-4bda-7b07-8586-1298248a8d5c';

  static const batteryLogCharacteristic = '84c7be0b-7619-45c1-a503-95f4ff8736ed';

  static const firmwareVersion = 'd1da175e-b1b5-4248-8f36-98c9482b8d24';

  static const bikeSerial = '44e2bde6-9cd5-4159-9d43-a3e3f4e9c737';

  static const sessionUuid = '87efab0d-9e32-4ab8-8916-ed7cb72d819a';

  static const powerSwitchChar = '350d9a82-b3f3-4213-bdda-6403be495f53';

  static const findBikeChar = '350d9a82-b3f3-4213-bdda-6403be495f53';

  static const powerProtectedChar = 'eec8fd7f-4709-441a-a838-b9eb3066ede4';

  static const beepMainChar = 'e0b2b4b4-4b1e-4f3e-8f1e-6b3e4b4b4b4b';

  static const otaChar1 = '68311857-4f93-4060-a42d-16da35a5843c';
  static const otaChar2 = '07765f94-d850-4e87-a2cf-6bae5d9a0b67';
  static const otaChar3 = '4244dedb-7b6b-4774-9525-d37fde1c67da';

  static const bikeName = 'dat.bik3';

  static const androidMtu = 517;

  static const dashboardPollMs = 700;

  static const hmacTagLen = 4;

  static const authStatusOk = 0x01;

  static String get defaultPairingToken => SecureKeyManager.defaultPairingToken;

  static String get defaultPassword => SecureKeyManager.defaultPassword;
}
