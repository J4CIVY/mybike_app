// Dat Bike GATT profile — UUID đã verify qua review độc lập (2026-10-14).
//
// Nguồn: docs/ble_session_protocol.md §5 (đặc tả hoàn chỉnh) +
// gatt_table event từ capture xe thật + đối chiếu mã nguồn decompile.
// Vai trò Service vs Characteristic đã sửa theo đúng thực tế.

class Gatt {
  Gatt._();

  // ==================== SERVICES ====================

  /// Service dashboard — telemetry protobuf (poll, không notify).
  static const dashboardService = 'cf6900a7-4520-4a4c-977c-82979e8baccf';

  /// Service xác thực — nonce auth + pairingToken + on/off bike.
  static const authService = '10cb0217-ff02-4474-a1ef-6fd88b5bdaea';

  /// Service thông tin xe (18 chars) — fw version, serial, session UUID.
  static const infoService = 'd4905f67-8931-4faa-8c61-86ec7490f3c5';

  /// Service OTA — truyền firmware (chars writeNoResp).
  /// KHÔNG phải BEEP_SCAN như bản đồ JS cũ ghi sai.
  static const otaService = '5b6d1069-a0bc-4875-ba5b-fdc94647d918';

  /// Service lập trình VESC.
  static const programmingService = 'f7e2c8a1-3d5b-4906-9e1f-8c0a2b4d6e8f';

  // ==================== CHARACTERISTICS (Auth Service) ====================
  // Vai trò ĐÃ SỬA theo btsnoop capture app gốc 2026-10-14 16:16 (máy Samsung):
  // doc cũ ghi ngược hoàn toàn vai trò của 2 char này.

  /// APP_AUTH_CHAR (c8eaf27b) — nhận app-token 12 ký tự ASCII (ví dụ
  /// "5bMO8m3wF9q3" trong capture), đọc trả 4 byte counter.
  /// Firmware handler: onWriteAppAuth.
  static const appAuthChar = 'c8eaf27b-9fb7-4bc3-b11a-bf68c97b1b1f';

  /// AUTHORIZATION_CHAR (5e9a2c71) — char NONCE/STATUS chính của handshake:
  /// đọc 16 byte = 15B nonce + 1B status (0x00 = chưa auth, 0x01 = chấp nhận),
  /// ghi 16 byte HMAC auth response. Firmware handler: onWriteAuthentication.
  static const authorizationChar = '5e9a2c71-0b3d-4f86-a1c2-7d4e8f0b9a63';

  /// ON_OFF_BIKE_CHAR (4cb05df8) — app gốc KHÔNG ghi char này trong capture;
  /// lệnh bật/tắt nguồn thật là plain '1'/'0' vào powerSwitchChar.
  static const onOffBikeChar = '4cb05df8-9c3a-4d7e-9b2f-8e1a3c6d5b41';

  // ==================== CHARACTERISTICS (Dashboard Service) ====================

  /// DASHBOARD_CHAR — Poll đọc telemetry protobuf (1s/lần, không notify).
  /// Payload mã hoá cho tới khi có session key.
  static const dashboardCharacteristic = '6d2eb205-6f9b-4ecf-bb1b-a5fad127c66c';

  /// BIKE_LOG_CHAR — Log phụ 108 byte (mã hoá).
  static const bikeLogCharacteristic = '018e6a6f-4bda-7b07-8586-1298248a8d5c';

  /// BATTERY_LOG_CHAR — Log 207 byte (mã hoá).
  /// KHÔNG phải DASHBOARD_SERVICE như bản đồ JS cũ ghi sai.
  static const batteryLogCharacteristic = '84c7be0b-7619-45c1-a503-95f4ff8736ed';

  // ==================== CHARACTERISTICS (Info Service) ====================

  /// Firmware version — đọc "1.14.0" plain text (cần link đã bond/mã hoá:
  /// chưa bond sẽ bị ErrorRsp 0x05 Insufficient Authentication).
  static const firmwareVersion = 'd1da175e-b1b5-4248-8f36-98c9482b8d24';

  /// Kênh xác thực PIN trong Handshake và Đồng bộ giờ Taplo xe (BIKE_SERIAL / CURRENT_TIME)
  /// - Trong Handshake: nhận Protected Write mang mã PIN xe (pw.codeUnits).
  /// - Sau khi kết nối: nhận Protected Write mang chuỗi số giây UTC để đặt giờ Taplo.
  static const bikeSerial = '44e2bde6-9cd5-4159-9d43-a3e3f4e9c737';
  static const currentTimeChar = '44e2bde6-9cd5-4159-9d43-a3e3f4e9c737';
  static const timeSyncChar = '44e2bde6-9cd5-4159-9d43-a3e3f4e9c737';

  /// Serial xe thật (Device/Frame Serial từ getCharDeviceSerialUuid)
  static const deviceSerialChar = '041d5a06-e35f-42d3-92c8-0d421186d2f3';

  /// SESSION_UUID (87efab0d) — app gốc GHI chuỗi uuid token 36B ASCII lên đây
  /// ngay sau protected-write password (doc cũ ghi "không tham gia" là sai).
  static const sessionUuid = '87efab0d-9e32-4ab8-8916-ed7cb72d819a';

  /// POWER_SWITCH_CHAR — Ghi '1' (0x31) bật nguồn, '0' (0x30) tắt nguồn xe.
  /// Quan sát trực tiếp trên capture Samsung HCI (Write #11 handle 0x0038).
  static const powerSwitchChar = '350d9a82-b3f3-4213-bdda-6403be495f53';

  /// Cảnh báo: 350d9a82 là char công tắc nguồn xe (powerSwitchChar).
  /// TUYỆT ĐỐI KHÔNG ghi nhấp nháy 1/0 vào đây để tìm xe vì sẽ gây đóng ngắt nguồn xe liên tục.
  /// Còi xe thật sự nằm trong Beep/Alert Service (5b6d1069).
  @Deprecated('350d9a82 là công tắc nguồn, không phải còi xe. Tránh nhấp nháy gây hỏng relay xe.')
  static const findBikeChar = '350d9a82-b3f3-4213-bdda-6403be495f53';

  /// BEEP_SCAN / FIND BIKE — app gốc 4.5.0 ghi '1'/'0' ASCII lên ĐÚNG char này
  /// để bật/tắt còi tìm xe (bundle L468568: findBike→'1', stopFindBike→'0').
  /// Char multi-purpose: nhận session token UUID lúc handshake, '1'/'0' khi đã
  /// có session (giải mã config module, task-memory id 46).
  static const beepScanChar = '87efab0d-9e32-4ab8-8916-ed7cb72d819a';

  /// POWER_PROTECTED_CHAR — Protected write cho công tắc nguồn xe (handle 0x003a).
  static const powerProtectedChar = 'eec8fd7f-4709-441a-a838-9eb3066ede4';

  // ==================== CHARACTERISTICS (Alert / Beep / OTA Service) ====================

  /// Characteristic Read/Write chính của Alert/Beep Service (handle 0x0043).
  @Deprecated('Không phải char còi. Còi thật = beepScanChar (87efab0d).')
  static const beepMainChar = 'e0b2b4b4-4b1e-4f3e-8f1e-6b3e4b4b4b4b';

  static const otaChar1 = '68311857-4f93-4060-a42d-16da35a5843c';
  static const otaChar2 = '07765f94-d850-4e87-a2cf-6bae5d9a0b67';
  static const otaChar3 = '4244dedb-7b6b-4774-9525-d37fde1c67da';

  // ==================== MASTER_CONFIG SERVICE (f7e2c8a1) — SETTINGS THẬT ====================
  // Firmware có handler thật (BLEBikeMasterConfig.cpp) — ghi dạng PROTECTED
  // write (đều nằm trong PROTECTED_WRITE_CHARS của app gốc).

  /// Giới hạn tốc độ THẬT bởi firmware (onWriteSpeedLimit @fw 0x3f413308).
  static const speedLimitChar = '0a19a49a-23bc-45ab-b2e9-4bf31665c76b';

  /// Chế độ ECE (Energy Capture & Efficiency).
  static const eceModeChar = '3b56ac38-60fb-40f8-a42c-fa09e0714e44';

  /// Chế độ Grab (xe chạy dịch vụ).
  static const grabModeChar = 'a1d8e7c4-5b3f-4902-8a6e-9c0d2f1e3b4a';

  /// Tự tắt xe khi đỗ (idling turn-off).
  static const idlingTurnOffChar = '69c79762-9dd3-413e-9aaf-bdd147563c93';

  /// Tự bật/tắt xe theo khoảng cách BLE: 0=Tắt, 1=Gần, 2=Vừa, 3=Xa hơn
  /// (firmware setDistanceLimit — XE tự xử lý, chính xác hơn RSSI của app).
  static const distanceChar = '5d681587-c268-4bd3-9560-66ec79dbfdc8';

  /// Khóa xe vật lý (firmware: "Locking bike", chặn khi xe đang bật).
  static const lockBikeChar = 'b0ca953d-46db-4451-b457-b81696d4e3ae';

  /// Tắt hẳn BMS (đỗ lâu — tiết kiệm pin sâu).
  static const turnOffBmsChar = '1f4108ad-8a70-4165-87d0-88e16f433758';

  /// Factory reset cài đặt BLE của xe.
  static const resetBleChar = 'a23df519-5279-4fdc-87ef-9b9e65b4a31f';

  /// Đăng ký thẻ NFC mới (RfidCardManager: "Adding new card...", card1/card2).
  static const addCardChar = 'c75ebe03-ea2f-4c0e-a720-1e7112a72d81';

  /// Tên xe (firmware: "Set new name: %s").
  static const bikeNameChar = '460a5bc5-a5f5-4968-b548-dc218935245e';

  /// Model xe ("Model from flash").
  static const bikeModelChar = '4aae98e9-90b5-492f-8180-9538fa2c843d';

  /// UUID char còi HIỆN TẠI của xe — cấu hình được (firmware: setBeepUUID,
  /// "Set new beepUUID: %s"). Đọc để biết phải ghi '1' vào char nào.
  static const beepUuidChar = '88c30d2c-f80f-43f8-b0cb-fc1e4ae49be9';

  /// Chọn profile sạc: 0=Standard, 1=Fast, 2=Boost (service 8a2b0d00).
  static const chargingProfileChar = '8a2b0d10-9c52-4f5a-9d3e-1f7a0c4b6e21';

  // ==================== OPERATING CONSTANTS ====================

  /// Tên BLE xe quảng bá (kể cả biến thể: 'Dat Bike Quantum S1').
  static const bikeName = 'dat.bik3';

  /// MTU tối đa Android.
  static const androidMtu = 517;

  /// Chu kỳ poll dashboard (ms) — app gốc poll ~650-700ms/lần (từ btsnoop).
  static const dashboardPollMs = 700;

  /// HMAC tag length (bytes) — 4 bytes = 32 bits.
  static const hmacTagLen = 4;

  /// Status byte của nonce 16B trên AUTHORIZATION_CHAR: 0x00 = chưa xác thực,
  /// 0x01 = xe đã chấp nhận response.
  static const authStatusOk = 0x01;

  /// Pairing token THẬT — crack từ firmware xe 2026-10-19 (mainPcb-1.14.0,
  /// blob obfuscate @DROM 0x3f413174 XOR keystream
  /// SHA256(key64 0x779e77defb3e5a4b LE ‖ blockIdx)). Chuỗi nhúng cứng trong
  /// firmware = token chung cho mọi xe chạy fw 1.14.0; server /attest cấp
  /// đúng chuỗi này. Xác thực bằng 3 cặp (nonce→response) của btsnoop thật.
  static const defaultPairingToken =
      'c97eb99d-c695-4b5f-8a99-7b24ff2a7980';

  /// Password mặc định theo capture (app gốc protected-write "58607" lên
  /// bikeSerial khi handshake với xe Quantum S1 B4:3A:45:D3:F3:35) — PIN
  /// thật do chủ xe đặt, chỉnh trong UI nếu khác.
  static const defaultPassword = '58607';
}
