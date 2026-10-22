// BLE controller — kết nối ổn định cho Phase 1.
//
// Chiến lược ổn định (khắc phục điểm yếu của app gốc):
// - Nhớ xe kết nối lần cuối (shared_preferences) → tự kết nối lại khi mở app.
// - Nghe connectionState → khi đứt ngoài ý muốn, tự reconnect với backoff
//   2→4→8→16→30s, tối đa 5 lần.
// - Sau 2 lần reconnect fail liên tiếp: nghi bond mismatch → removeBond()
//   rồi thử lại (app gốc bắt user vào Settings xoá bond thủ công).
// - MTU 517 re-request mỗi lần kết nối (chunk 244 byte như app gốc).

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../proto/bike_log.dart';
import '../services/foreground_service.dart';
import '../session/bike_session_crypto.dart';
import '../utils/kalman_filter.dart';
import 'ble_logger.dart';
import 'ble_permissions.dart';
import 'gatt.dart';

enum BlePhase { idle, scanning, connecting, connected, reconnecting, disconnected }

class BikeTelemetry {
  final BikeLogMsg? bike;
  final DateTime at;
  BikeTelemetry(this.bike, this.at);
}

class TripData {
  final double distanceKm;
  final Duration duration;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int usedPercent;
  final double powerKw;

  const TripData({
    this.distanceKm = 0.0,
    this.duration = Duration.zero,
    this.avgSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.usedPercent = 0,
    this.powerKw = 0.0,
  });

  TripData copyWith({
    double? distanceKm,
    Duration? duration,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    int? usedPercent,
    double? powerKw,
  }) =>
      TripData(
        distanceKm: distanceKm ?? this.distanceKm,
        duration: duration ?? this.duration,
        avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
        maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
        usedPercent: usedPercent ?? this.usedPercent,
        powerKw: powerKw ?? this.powerKw,
      );
}

class BleState {
  final BlePhase phase;
  final BluetoothDevice? device;
  final String? bikeName;
  final int reconnectAttempt;
  final String? message;
  final bool dashboardEncrypted; // decode liên tục thất bại → cần handshake
  final List<BluetoothCharacteristic> characteristics;
  final bool isAuthorized;
  final Uint8List? sessionKey;
  final BikeLogMsg? lastTelemetry;
  final BatteryLogMsg? lastBattery;
  final bool isFindingBike;
  final TripData trip;
  final bool autoLockWalkAway;
  final bool antiForgetAlert;
  final int autoLockDistance; // 0: Gần (~-75dBm), 1: Vừa (~-85dBm), 2: Xa (~-92dBm)
  final int antiForgetDistance; // 0: Gần (~-75dBm), 1: Vừa (~-85dBm), 2: Xa (~-92dBm)
  final int? rssi;
  final int? filteredRssi;
  final DateTime? lastTimeSynced;
  final int findBikePattern; // 0: Tiêu chuẩn, 1: Nhịp đôi, 2: Báo động
  final int recupLevel; // 0: Nhẹ, 1: Tiêu chuẩn, 2: Mạnh (One-pedal)
  final int throttleResponse; // 0: Êm ái, 1: Tiêu chuẩn, 2: Thể thao
  final int speedLimitMode; // 0: Không giới hạn, 1: 50 km/h, 2: 30 km/h
  final String? frameSerial;

  const BleState({
    required this.phase,
    this.device,
    this.bikeName,
    this.reconnectAttempt = 0,
    this.message,
    this.dashboardEncrypted = false,
    this.characteristics = const [],
    this.isAuthorized = false,
    this.sessionKey,
    this.lastTelemetry,
    this.lastBattery,
    this.isFindingBike = false,
    this.trip = const TripData(),
    this.autoLockWalkAway = false,
    this.antiForgetAlert = true,
    this.autoLockDistance = 1,
    this.antiForgetDistance = 1,
    this.rssi,
    this.filteredRssi,
    this.lastTimeSynced,
    this.findBikePattern = 0,
    this.recupLevel = 1,
    this.throttleResponse = 1,
    this.speedLimitMode = 0,
    this.frameSerial,
  });

  BleState copyWith({
    BlePhase? phase,
    BluetoothDevice? device,
    String? bikeName,
    int? reconnectAttempt,
    String? message,
    bool? dashboardEncrypted,
    List<BluetoothCharacteristic>? characteristics,
    bool? isAuthorized,
    Uint8List? sessionKey,
    BikeLogMsg? lastTelemetry,
    BatteryLogMsg? lastBattery,
    bool? isFindingBike,
    TripData? trip,
    bool? autoLockWalkAway,
    bool? antiForgetAlert,
    int? autoLockDistance,
    int? antiForgetDistance,
    int? rssi,
    int? filteredRssi,
    DateTime? lastTimeSynced,
    int? findBikePattern,
    int? recupLevel,
    int? throttleResponse,
    int? speedLimitMode,
    String? frameSerial,
  }) =>
      BleState(
        phase: phase ?? this.phase,
        device: device ?? this.device,
        bikeName: bikeName ?? this.bikeName,
        reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
        message: message,
        dashboardEncrypted: dashboardEncrypted ?? this.dashboardEncrypted,
        characteristics: characteristics ?? this.characteristics,
        isAuthorized: isAuthorized ?? this.isAuthorized,
        sessionKey: sessionKey ?? this.sessionKey,
        lastTelemetry: lastTelemetry ?? this.lastTelemetry,
        lastBattery: lastBattery ?? this.lastBattery,
        isFindingBike: isFindingBike ?? this.isFindingBike,
        trip: trip ?? this.trip,
        autoLockWalkAway: autoLockWalkAway ?? this.autoLockWalkAway,
        antiForgetAlert: antiForgetAlert ?? this.antiForgetAlert,
        autoLockDistance: autoLockDistance ?? this.autoLockDistance,
        antiForgetDistance: antiForgetDistance ?? this.antiForgetDistance,
        rssi: rssi ?? this.rssi,
        filteredRssi: filteredRssi ?? this.filteredRssi,
        lastTimeSynced: lastTimeSynced ?? this.lastTimeSynced,
        findBikePattern: findBikePattern ?? this.findBikePattern,
        recupLevel: recupLevel ?? this.recupLevel,
        throttleResponse: throttleResponse ?? this.throttleResponse,
        speedLimitMode: speedLimitMode ?? this.speedLimitMode,
        frameSerial: frameSerial ?? this.frameSerial,
      );
}

class BleController extends Notifier<BleState> {
  static const _kLastBikeId = 'last_bike_id';
  static const _kBikePassword = 'bike_password'; // password đã self-register
  static const _kLastBikeName = 'last_bike_name';
  static const _maxReconnect = 5;
  static const _backoff = [2, 4, 8, 16, 30]; // giây

  StreamSubscription? _connSub;
  StreamSubscription? _notifySub;
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  BluetoothCharacteristic? _dashChar;
  BluetoothCharacteristic? _batteryChar;
  int _batteryPollCounter = 0;
  bool _manualDisconnect = false;
  bool _reconnectPending = false;
  int _reconnectAttempts = 0;
  int _failStreak = 0;
  int _decodeFailStreak = 0;
  int _plainLogCount = 0;

  // Keepalive — chu trình 1,2s của app gốc (log vendor 13/10):
  //   WRITE 16B auth response -> WRITE 12B password -> READ nonce moi.
  // Giu session song KHONG can the NFC + re-derive sessionKey moi chu ky
  // (firmware derive lai + reset writeCounter tai moi auth write hop le).
  Timer? _keepaliveTimer;
  Uint8List? _lastAuthNonce15;
  String _activePassword = '';
  int _keepaliveCount = 0;
  bool _keepaliveBusy = false;
  bool _establishBusy = false; // mutex: 1 handshake/lúc — chống double-flow
  bool _restoreBusy = false; // mutex: 1 restore/lúc — chống khởi động song song
  bool _isCommandBusy = false; // mutex: chống gửi dồn dập nhiều lệnh tới BMS
  DateTime? _lastCommandCompletedAt; // mốc hoàn tất lệnh trước (cooldown bus CAN/BMS)

  /// KEEPALIVE TẮT MẶC ĐỊNH (2026-10-20): bản log 13h49 giữ được session
  /// khi tháo thẻ CHỈ với poll dashboard 700ms — không cần chu trình auth
  /// 1,2s. Keepalive (thêm ở bản e+) là nghi phạm làm đứt link: nếu trả lời
  /// nonce cũ (do lần đọc nào đó xoay nonce) xe coi là vi phạm bảo mật.
  /// Bật lại = true nếu cần thử nghiệm.
  static const enableKeepalive = false;
  bool _recoveryDisconnect = false; // disconnect trong recovery: ĐỪNG đóng logger
  Uint8List? _sessionKey;
  int _writeCounter = 0;

  final _telemetry = StreamController<BikeTelemetry>.broadcast();

  static const _kAutoLockWalkAway = 'auto_lock_walk_away';
  static const _kAntiForgetAlert = 'anti_forget_alert';
  static const _kAutoLockDistance = 'auto_lock_distance';
  static const _kAntiForgetDistance = 'anti_forget_distance';
  static const _kFindBikePattern = 'find_bike_pattern';
  static const _kRecupLevel = 'recup_level';
  static const _kThrottleResponse = 'throttle_response';
  static const _kSpeedLimitMode = 'speed_limit_mode';

  final _rssiKalman = KalmanFilter1D(processNoise: 0.008, measurementNoise: 4.0);
  double? _smoothedRssi;
  int _autoLockCounter = 0;
  int _antiForgetCounter = 0;
  bool _walkUpTriggered = false;

  double? _tripStartOdo;
  DateTime? _tripStartTime;
  int? _tripStartPercent;
  double _tripMaxSpeed = 0.0;
  double _tripSpeedSum = 0.0;
  int _tripSpeedSamples = 0;

  @override
  BleState build() {
    ref.onDispose(_teardown);
    _initSavedBike();
    return const BleState(phase: BlePhase.idle);
  }

  void _initSavedBike() async {
    final prefs = await _prefs;
    final savedName = prefs.getString(_kLastBikeName);
    final savedId = prefs.getString(_kLastBikeId);
    final autoLock = prefs.getBool(_kAutoLockWalkAway) ?? false;
    final antiForget = prefs.getBool(_kAntiForgetAlert) ?? true;
    final autoLockDist = prefs.getInt(_kAutoLockDistance) ?? 1;
    final antiForgetDist = prefs.getInt(_kAntiForgetDistance) ?? 1;
    final findBikePat = prefs.getInt(_kFindBikePattern) ?? 0;
    final recup = prefs.getInt(_kRecupLevel) ?? 1;
    final throttle = prefs.getInt(_kThrottleResponse) ?? 1;
    final speedLimit = prefs.getInt(_kSpeedLimitMode) ?? 0;
    state = state.copyWith(
      bikeName: (savedId != null && savedName != null) ? savedName : state.bikeName,
      autoLockWalkAway: autoLock,
      antiForgetAlert: antiForget,
      autoLockDistance: autoLockDist,
      antiForgetDistance: antiForgetDist,
      findBikePattern: findBikePat,
      recupLevel: recup,
      throttleResponse: throttle,
      speedLimitMode: speedLimit,
    );
    // Tự động kết nối ngay khi mở app nếu đã từng kết nối xe trước đó
    if (savedId != null && savedId.isNotEmpty) {
      unawaited(tryRestoreLastBike());
    }
  }

  Future<void> setFindBikePattern(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(_kFindBikePattern, val);
    state = state.copyWith(findBikePattern: val);
  }

  /// Lưu hồ sơ mức phanh tái sinh RECUP cá nhân trên ứng dụng.
  /// LƯU Ý: Firmware v1.14.0 hiện tại chưa hỗ trợ ghi cấu hình RECUP qua BLE xuống xe.
  Future<void> setRecupLevel(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(_kRecupLevel, val);
    state = state.copyWith(recupLevel: val);
    BleLogger.instance.event('driver_profile_recup_set_local', {'level': val});
  }

  /// Lưu hồ sơ độ nhạy tay ga cá nhân trên ứng dụng.
  /// LƯU Ý: Firmware v1.14.0 hiện tại chưa hỗ trợ ghi cấu hình bướm ga qua BLE xuống xe.
  Future<void> setThrottleResponse(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(_kThrottleResponse, val);
    state = state.copyWith(throttleResponse: val);
    BleLogger.instance.event('driver_profile_throttle_set_local', {'response': val});
  }

  /// Lưu hồ sơ giới hạn tốc độ khuyến nghị cá nhân trên ứng dụng.
  /// CẢNH BÁO: Firmware v1.14.0 KHÔNG hỗ trợ khóa tốc độ xe từ Bluetooth!
  /// Cài đặt này chỉ mang tính tham khảo trên giao diện và KHÔNG hãm tốc độ thực tế của xe.
  Future<void> setSpeedLimitMode(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(_kSpeedLimitMode, val);
    state = state.copyWith(speedLimitMode: val);
    BleLogger.instance.event('driver_profile_speed_mode_set_local', {'mode': val});
  }

  Future<String?> readDeviceSerial() async {
    final dev = _device;
    if (dev == null || state.phase != BlePhase.connected) return null;
    final c = _findCharacteristic(Gatt.deviceSerialChar);
    if (c == null) return null;
    try {
      final raw = await c.read();
      // Loại bỏ null bytes (\x00) và các ký tự điều khiển (control chars/newline)
      final serial = utf8
          .decode(raw, allowMalformed: true)
          .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '')
          .trim();
      BleLogger.instance.event('device_serial_read', {'serial': serial});
      if (serial.isNotEmpty) {
        state = state.copyWith(frameSerial: serial);
        return serial;
      }
      return null;
    } catch (e) {
      BleLogger.instance.event('device_serial_read_err', {'error': '$e'});
      return null;
    }
  }

  Future<void> setAutoLockWalkAway(bool val) async {
    final prefs = await _prefs;
    await prefs.setBool(_kAutoLockWalkAway, val);
    state = state.copyWith(autoLockWalkAway: val);
  }

  Future<void> setAntiForgetAlert(bool val) async {
    final prefs = await _prefs;
    await prefs.setBool(_kAntiForgetAlert, val);
    state = state.copyWith(antiForgetAlert: val);
  }

  Future<void> setAutoLockDistance(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(_kAutoLockDistance, val);
    state = state.copyWith(autoLockDistance: val);
  }

  Future<void> setAntiForgetDistance(int val) async {
    final prefs = await _prefs;
    await prefs.setInt(_kAntiForgetDistance, val);
    state = state.copyWith(antiForgetDistance: val);
  }

  void resetTrip() {
    _tripStartOdo = state.lastTelemetry?.odo;
    _tripStartTime = DateTime.now();
    _tripStartPercent = state.lastTelemetry?.percent;
    _tripMaxSpeed = 0.0;
    _tripSpeedSum = 0.0;
    _tripSpeedSamples = 0;
    state = state.copyWith(
      trip: TripData(powerKw: state.trip.powerKw),
    );
  }

  Stream<BikeTelemetry> get telemetry => _telemetry.stream;

  BluetoothDevice? get _device => state.device;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ------------------------------------------------------------------
  // Kết nối
  // ------------------------------------------------------------------

  Future<void> connect(BluetoothDevice device, {String? name}) async {
    if (state.phase == BlePhase.connected &&
        state.isAuthorized &&
        state.device?.remoteId == device.remoteId) {
      return;
    }
    _manualDisconnect = false;
    _writeCounter = 0;
    _cancelReconnect();
    state = BleState(phase: BlePhase.connecting, device: device, bikeName: name);
    unawaited(ForegroundService.start(
      title: 'Dat Bike',
      text: 'Đang kết nối với ${name ?? device.platformName}...',
    ));
    await BleLogger.instance.startSession();
    BleLogger.instance.event('connect_start', {
      'device_id': device.remoteId.str,
      'name': name ?? device.platformName,
    });
    // Auth bị từ chối sau kill-app: xe giữ session-lock một khoảng ngắn
    // (quan sát thực tế: còn khoá ở +10s, mở ở +35s). DÒ DẦY mỗi 3s (15 vòng
    // ≈ 45s) để vào ngay khoảnh khắc xe mở khoá — app gốc cũng chỉ nhanh vì
    // nối lại liên tục.
    var recovered = false;
    for (var cycle = 1; cycle <= 5 && !recovered; cycle++) {
      if (cycle > 1) {
        state = state.copyWith(
          phase: BlePhase.reconnecting,
          message: 'Xe giữ khoá phiên sau lần kết nối bị đứt — đang thử lại '
              '($cycle/5, mỗi 3s)...',
        );
        BleLogger.instance
            .event('auth_recovery_wait', {'cycle': cycle, 'delay_s': 3});
        _manualDisconnect = true; // chặn reconnect scheduler đua
        _recoveryDisconnect = true; // giữ logger sống
        try {
          await device.disconnect();
        } catch (_) {}
        await Future.delayed(const Duration(seconds: 3));
        _recoveryDisconnect = false;
        _manualDisconnect = false;
      }
      var ok = false;
      try {
        ok = await _establish(device);
      } catch (_) {
        ok = false;
      }
      if (ok) {
        await _saveLastBike(device, name);
        _watchConnection(device);
        state = state.copyWith(phase: BlePhase.connected, message: null);
        unawaited(ForegroundService.start(
          title: 'Dat Bike: ${state.bikeName ?? device.platformName}',
          text: 'Đã kết nối Bluetooth — Sẵn sàng điều khiển',
        ));
        _failStreak = 0;
        recovered = true;
      }
    }
    if (recovered) return;
    try {
      await _establish(device);
      await _saveLastBike(device, name);
      _watchConnection(device);
      state = state.copyWith(phase: BlePhase.connected, message: null);
      unawaited(ForegroundService.start(
        title: 'Dat Bike: ${state.bikeName ?? device.platformName}',
        text: 'Đã kết nối Bluetooth — Sẵn sàng điều khiển',
      ));
      _failStreak = 0;
    } catch (e) {
      BleLogger.instance.event('connect_failed', {'error': '$e'});
      state = state.copyWith(
          phase: BlePhase.disconnected, message: 'Kết nối thất bại: $e');
      unawaited(ForegroundService.stop());
      rethrow;
    }
  }

  Future<bool> _establish(BluetoothDevice device) async {
    // Mutex: nếu một handshake đang chạy (recovery loop đua với reconnect
    // scheduler…), không chạy chồng — log 19:02 cho thấy 2 flow song song
    // đăng ký 2 password khác nhau làm session key loạn hoàn toàn.
    if (_establishBusy) {
      BleLogger.instance.event('establish_skipped', {'reason': 'busy'});
      return state.isAuthorized;
    }
    _establishBusy = true;
    try {
      return await _establishInner(device);
    } finally {
      _establishBusy = false;
    }
  }

  Future<void> _connectWithCachePrime(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // 1. Kiểm tra nếu thiết bị đã được kết nối ở cấp độ OS (Android/iOS)
    final alreadyConnected = FlutterBluePlus.connectedDevices
        .any((d) => d.remoteId == device.remoteId);
    if (alreadyConnected) {
      try {
        await device.connect(
          license: License.nonprofit,
          timeout: const Duration(seconds: 4),
          autoConnect: false,
        );
        return;
      } catch (_) {}
    }

    // 2. Chờ adapter Bluetooth bật nếu vừa mở app
    try {
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        await FlutterBluePlus.adapterState
            .where((s) => s == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 4));
      }
    } catch (_) {}

    // 3. Scan nhanh có RemoteId để làm mới BLE cache và connection window của Android
    try {
      if (!FlutterBluePlus.isScanningNow) {
        StreamSubscription? scanSub;
        final completer = Completer<void>();
        scanSub = FlutterBluePlus.scanResults.listen((results) {
          if (results.any((r) => r.device.remoteId == device.remoteId)) {
            if (!completer.isCompleted) completer.complete();
          }
        });
        await FlutterBluePlus.startScan(
          withRemoteIds: [device.remoteId.str],
          timeout: const Duration(seconds: 3),
          androidScanMode: AndroidScanMode.lowLatency,
        );
        await completer.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () {},
        );
        await scanSub.cancel();
      }
    } catch (_) {
    } finally {
      if (FlutterBluePlus.isScanningNow) {
        try {
          await FlutterBluePlus.stopScan();
        } catch (_) {}
      }
    }

    // 4. Kết nối trực tiếp sau khi cache đã được làm mới
    await device.connect(
      license: License.nonprofit,
      timeout: timeout,
      autoConnect: false,
    );
  }

  Future<bool> _establishInner(BluetoothDevice device) async {
    await _connectWithCachePrime(device);
    BleLogger.instance.event('connected', {'device_id': device.remoteId.str});
    _writeCounter = 0;
    final mtu = await device.requestMtu(Gatt.androidMtu);
    BleLogger.instance.event('mtu', {'mtu': mtu});

    final services = await device.discoverServices();

    // BẢNG GATT ĐẦY ĐỦ — dữ liệu vàng để hoàn thiện bản đồ UUID.
    final gattTable = <Map<String, Object?>>[];
    for (final service in services) {
      gattTable.add({
        'service': service.uuid.str128.toLowerCase(),
        'characteristics': [
          for (final c in service.characteristics)
            {
              'uuid': c.uuid.str128.toLowerCase(),
              'properties': [
                if (c.properties.read) 'read',
                if (c.properties.write) 'write',
                if (c.properties.writeWithoutResponse) 'writeNoResp',
                if (c.properties.notify) 'notify',
                if (c.properties.indicate) 'indicate',
              ],
            },
        ],
      });
    }
    BleLogger.instance.event('gatt_table', {'services': gattTable});

    // expose cho AuthProbe / Phase 2
    final allChars = <BluetoothCharacteristic>[];
    for (final s in services) {
      allChars.addAll(s.characteristics);
    }
    state = state.copyWith(device: device, characteristics: allChars);

    // Đọc firmware version — char duy nhất app gốc đọc trước handshake.
    // Xe yêu cầu link đã bond/mã hoá: chưa bond sẽ bị err 0x05/137
    // (Insufficient Authentication) — thấy rõ trong btsnoop máy Samsung.
    for (final service in services) {
      for (final c in service.characteristics) {
        if (c.uuid.str128.toLowerCase() != Gatt.firmwareVersion.toLowerCase()) {
          continue;
        }
        try {
          final value = await c.read();
          BleLogger.instance.event('char_read', {
            'uuid': Gatt.firmwareVersion,
            'len': value.length,
            'hex': BleLogger.hex(value),
            'utf8': BleLogger.tryUtf8(value),
          });
        } catch (e) {
          BleLogger.instance.event('char_read_error', {
            'uuid': Gatt.firmwareVersion,
            'error': '$e',
          });
          if (_isAuthError(e)) {
            await _ensureBonded(device, reason: 'fw char bị err auth');
            try {
              final value = await c.read();
              BleLogger.instance.event('char_read', {
                'uuid': Gatt.firmwareVersion,
                'len': value.length,
                'hex': BleLogger.hex(value),
                'utf8': BleLogger.tryUtf8(value),
              });
            } catch (_) {}
          }
        }
      }
    }

    // Tự động kích hoạt bắt tay xác thực phiên xe (Phase 1 + 2) ngay khi kết nối
    await authenticateSession(targetDevice: device);

    // Dashboard — ĐÃ XÁC MINH TRÊN XE THẬT: characteristic 6d2eb205 chỉ có
    // read/write, KHÔNG có notify. App gốc POLL đọc định kỳ
    // (DASHBOARD_REFRESH_INTERVAL), không subscribe.
    for (final service in services) {
      if (service.uuid.str128.toLowerCase() != Gatt.dashboardService) continue;
      for (final c in service.characteristics) {
        if (c.uuid.str128.toLowerCase() != Gatt.dashboardCharacteristic) continue;
        _dashChar = c;
        if (c.properties.notify) {
          // phòng xa: firmware tương lai thêm notify thì dùng notify
          await c.setNotifyValue(true);
          BleLogger.instance.event('notify_subscribed', {
            'uuid': c.uuid.str128.toLowerCase(),
          });
          _notifySub?.cancel();
          _notifySub = c.lastValueStream.listen((List<int> raw) {
            BleLogger.instance.event('notify', {
              'uuid': c.uuid.str128.toLowerCase(),
              'len': raw.length,
              'hex': BleLogger.hex(raw),
            });
            _handleDashboardPayload(raw);
          });
        }
      }
    }

    // Poll 1 giây/lần (giữ GATT sống + nhận telemetry). Blob mã hoá trước
    // handshake là hành vi xe gốc — cờ dashboardEncrypted báo lên UI.
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
        Duration(milliseconds: Gatt.dashboardPollMs), (_) => _pollDashboard());
    await _pollDashboard(); // đọc ngay 1 lần
    return state.isAuthorized;
  }

  Future<void> _pollDashboard() async {
    final c = _dashChar;
    if (c == null || state.phase != BlePhase.connected) return;
    // Watchdog: nếu đã xác thực mà keepalive chưa chạy (bất kỳ path nào làm
    // nó tắt/lỡ start) → tự khởi động lại. Đây là linh kiện giữ kết nối
    // không thẻ — phải luôn sống khi session sống.
    if (enableKeepalive &&
        state.isAuthorized &&
        _keepaliveTimer == null &&
        _activePassword.isNotEmpty &&
        _lastAuthNonce15 != null) {
      BleLogger.instance.event('keepalive_watchdog_restart', {});
      _startKeepalive();
    }
    try {
      final raw = await c.read();
      _handleDashboardPayload(raw);
    } catch (e) {
      BleLogger.instance.event('poll_error', {'error': '$e'});
    }

    // Định kỳ đọc Battery Log (207 byte) mỗi 3 chu kỳ đo
    _batteryPollCounter++;
    if (_batteryPollCounter >= 3) {
      _batteryPollCounter = 0;
      unawaited(fetchBatteryDetails());
    }

    try {
      final dev = _device;
      if (dev != null) {
        final curRssi = await dev.readRssi();
        final filtered = _rssiKalman.filter(curRssi.toDouble());
        _smoothedRssi = filtered;
        state = state.copyWith(
          rssi: curRssi,
          filteredRssi: filtered.round(),
        );
        _checkAutoLockAndAlert();
      }
    } catch (_) {}
  }

  void _checkAutoLockAndAlert() {
    if (_smoothedRssi == null) return;
    final isBikeOn = state.lastTelemetry?.isBikeOn == true;
    final speed = state.lastTelemetry?.speed ?? 0.0;

    // 1. Tự động khóa khi rời xa (Walk-away Auto-Lock):
    // Cự ly: 0 (Gần: -80 dBm), 1 (Vừa: -88 dBm - Mặc định tối ưu), 2 (Xa: -94 dBm)
    if (state.autoLockWalkAway && isBikeOn && speed <= 0.5) {
      const thresholds = [-80, -88, -94];
      final threshold = thresholds[state.autoLockDistance.clamp(0, 2)];
      if (_smoothedRssi! <= threshold) {
        _autoLockCounter++;
        // Tín hiệu phải giữ liên tục yếu qua 3 chu kỳ đo (~3s) với bộ lọc Kalman để tránh khóa nhầm
        if (_autoLockCounter >= 3) {
          _autoLockCounter = 0;
          BleLogger.instance.event('auto_lock_triggered', {
            'smoothed_rssi': _smoothedRssi,
            'threshold': threshold,
          });
          unawaited(turnOffBike());
        }
      } else {
        _autoLockCounter = 0;
      }
    } else {
      _autoLockCounter = 0;
    }

    // 2. Walk-Up Proximity: Khi bước lại gần (> -65 dBm) -> thông báo sẵn sàng
    if (_smoothedRssi! > -65.0) {
      if (!_walkUpTriggered) {
        _walkUpTriggered = true;
        BleLogger.instance.event('walk_up_ready', {'rssi': _smoothedRssi});
        state = state.copyWith(
          message: '👋 Đã lại gần xe! Sẵn sàng vận hành.',
        );
      }
    } else if (_smoothedRssi! < -75.0) {
      // Tái vũ trang cờ khi đã rời xa hơn -75 dBm
      _walkUpTriggered = false;
    }

    // 3. Cảnh báo quên tắt xe khi rời xa (Anti-Forget Alert):
    if (state.antiForgetAlert && isBikeOn) {
      const alertThresholds = [-80, -88, -94];
      final threshold = alertThresholds[state.antiForgetDistance.clamp(0, 2)];
      if (_smoothedRssi! <= threshold) {
        _antiForgetCounter++;
        if (_antiForgetCounter == 3) {
          BleLogger.instance.event('anti_forget_alert_triggered', {
            'smoothed_rssi': _smoothedRssi,
            'threshold': threshold,
          });
          state = state.copyWith(
            message: '⚠️ CẢNH BÁO: Bạn đang rời xa nhưng xe vẫn đang BẬT nguồn!',
          );
        }
      } else {
        _antiForgetCounter = 0;
      }
    } else {
      _antiForgetCounter = 0;
    }
  }
  /// Kiểm tra dữ liệu telemetry có nằm trong giới hạn vật lý hợp lý của xe không.
  /// Nếu giải mã sai key (keystream rác), IEEE 754 float sẽ sinh ra số vô lý (NaN, âm, 10^30,...).
  bool _isTelemetrySane(BikeLogMsg msg) {
    if (msg.speed.isNaN || msg.speed < 0 || msg.speed > 250) return false;
    if (msg.odo.isNaN || msg.odo < 0 || msg.odo > 500000) return false;
    if (msg.voltage.isNaN || msg.voltage < 10 || msg.voltage > 130) return false;
    if (msg.percent < 0 || msg.percent > 100) return false;
    if (msg.kmLeft.isNaN || msg.kmLeft < 0 || msg.kmLeft > 500) return false;
    return true;
  }

  /// Kiểm tra xem gói tin thô sau khi giải mã với sessionKey có phải struct hợp lệ không.
  bool _isValidTelemetry(Uint8List sessionKey, List<int> raw) {
    if (raw.length < 4) return false;
    try {
      final decrypted = BikeSessionCrypto.decryptProtectedRead(
        sessionKey: sessionKey,
        characteristicUuid: Gatt.dashboardCharacteristic,
        response: raw,
      );
      if (decrypted.length >= 41) {
        final m = decodeDashboardStruct(decrypted);
        return _isTelemetrySane(m);
      }
    } catch (_) {}
    return false;
  }

  BluetoothCharacteristic? _findCharacteristic(String uuid) {
    final clean = uuid.toLowerCase().replaceAll('-', '');
    for (final c in state.characteristics) {
      if (c.uuid.str128.toLowerCase().replaceAll('-', '') == clean) return c;
    }
    return null;
  }

  void _handleBatteryPayload(List<int> raw) {
    if (raw.isEmpty) return;
    Uint8List payload = Uint8List.fromList(raw);

    // 1. Thử decode trực tiếp (Plain Protobuf hoặc JSON UTF-8) như app gốc Dat Bike (Br.d)
    try {
      final directMsg = decodeBatteryLogMsg(payload);
      if (directMsg.cellVols.isNotEmpty || directMsg.voltage > 0) {
        state = state.copyWith(lastBattery: directMsg);
        BleLogger.instance.event('battery_log_received_plain', {
          'voltage': directMsg.voltage,
          'current': directMsg.current,
          'cells': directMsg.cellVols.length,
          'balancing': directMsg.balancing,
          'protection': directMsg.protection,
        });
        return;
      }
    } catch (_) {}

    // 2. Nếu payload bị mã hoá session key (Protected Read) -> Thực hiện giải mã
    if (_sessionKey != null) {
      try {
        final decrypted = BikeSessionCrypto.decryptProtectedRead(
          sessionKey: _sessionKey!,
          characteristicUuid: Gatt.batteryLogCharacteristic,
          response: raw,
        );
        if (decrypted.isNotEmpty) {
          final bMsg = decodeBatteryLogMsg(decrypted);
          state = state.copyWith(lastBattery: bMsg);
          BleLogger.instance.event('battery_log_received_decrypted', {
            'voltage': bMsg.voltage,
            'current': bMsg.current,
            'cells': bMsg.cellVols.length,
            'balancing': bMsg.balancing,
            'protection': bMsg.protection,
          });
          return;
        }
      } catch (e) {
        BleLogger.instance.event('battery_decode_err', {'error': '$e'});
      }
    }
  }

  /// Đọc dữ liệu chi tiết Battery Log (207 byte) từ xe
  Future<void> fetchBatteryDetails() async {
    final dev = _device;
    if (dev == null || state.phase != BlePhase.connected) return;
    _batteryChar ??= _findCharacteristic(Gatt.batteryLogCharacteristic);
    final bChar = _batteryChar;
    if (bChar == null) return;
    try {
      final raw = await bChar.read();
      _handleBatteryPayload(raw);
    } catch (e) {
      BleLogger.instance.event('battery_read_err', {'error': '$e'});
    }
  }

  void _handleDashboardPayload(List<int> raw) {
    // Piggyback chẩn đoán vào chính event này (luôn chạy): plain = hex sau
    // giải mã, dk = tóm tắt decode dạng string — None nếu chưa có key.
    String? plainHex;
    Uint8List payloadToDecode = Uint8List.fromList(raw);
    if (_sessionKey != null) {
      try {
        final decrypted = BikeSessionCrypto.decryptProtectedRead(
          sessionKey: _sessionKey!,
          characteristicUuid: Gatt.dashboardCharacteristic,
          response: raw,
        );
        if (decrypted.isNotEmpty) {
          payloadToDecode = decrypted;
          plainHex = BleLogger.hex(decrypted, maxBytes: 96);
        }
      } catch (_) {}
    }

    String? dk;
    try {
      // 6d2eb205 = struct thô 41B (không phải protobuf) — decode struct;
      // nếu sau này char đổi sang protobuf thật thì fallback tự động.
      final msg = (payloadToDecode.length >= 36)
          ? decodeDashboardStruct(payloadToDecode)
          : decodeBikeLogMsg(payloadToDecode);

      // Kiểm tra tính hợp lý của Telemetry trước khi cập nhật state
      if (!_isTelemetrySane(msg)) {
        _decodeFailStreak++;
        BleLogger.instance.event('dashboard_insane_telemetry', {
          'streak': _decodeFailStreak,
          'speed': msg.speed,
          'odo': msg.odo,
          'volts': msg.voltage,
          'percent': msg.percent,
        });
        if (_decodeFailStreak >= 3) {
          state = state.copyWith(dashboardEncrypted: true);
          // Session key bị lệch với xe -> tự động re-authenticate để đồng bộ lại trong nền
          if (state.phase == BlePhase.connected && !_establishBusy && _device != null) {
            BleLogger.instance.event('session_resync_triggered', {'reason': 'telemetry_corrupted'});
            unawaited(authenticateSession(targetDevice: _device));
          }
        }
        return;
      }

      _decodeFailStreak = 0;
      if (state.dashboardEncrypted) {
        state = state.copyWith(dashboardEncrypted: false);
      }
      dk = 'st=${msg.state.name} sp=${msg.speed} odo=${msg.odo} '
          'km=${msg.kmLeft} ecu=${msg.ecu} mot=${msg.motor} '
          'fw=${msg.version} model=${msg.model}';

      // Cập nhật máy tính chuyến đi (Trip Computer) & Công suất tức thời
      _tripStartTime ??= DateTime.now();
      if (_tripStartOdo == null && msg.odo > 0) _tripStartOdo = msg.odo;
      if (_tripStartPercent == null && msg.percent > 0) _tripStartPercent = msg.percent;

      final dist = (msg.odo > 0 && _tripStartOdo != null)
          ? max(0.0, msg.odo - _tripStartOdo!)
          : state.trip.distanceKm;
      final dur = DateTime.now().difference(_tripStartTime!);
      if (msg.speed > _tripMaxSpeed) _tripMaxSpeed = msg.speed;
      if (msg.speed > 0.5) {
        _tripSpeedSum += msg.speed;
        _tripSpeedSamples++;
      }
      final avgSpd = _tripSpeedSamples > 0 ? (_tripSpeedSum / _tripSpeedSamples) : 0.0;
      final usedPct = (_tripStartPercent != null && msg.percent > 0)
          ? max(0, _tripStartPercent! - msg.percent)
          : 0;
      final pKw = (msg.voltage > 0) ? ((msg.voltage * msg.phase) / 1000.0) : 0.0;

      final currentTrip = TripData(
        distanceKm: dist,
        duration: dur,
        avgSpeedKmh: avgSpd,
        maxSpeedKmh: _tripMaxSpeed,
        usedPercent: usedPct,
        powerKw: pKw,
      );

      String? autoSerial = state.frameSerial;
      if (autoSerial == null && msg.frame.isNotEmpty) {
        final clean = msg.frame.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '').trim();
        if (clean.isNotEmpty) autoSerial = clean;
      }

      state = state.copyWith(lastTelemetry: msg, trip: currentTrip, frameSerial: autoSerial);
      _telemetry.add(BikeTelemetry(msg, DateTime.now()));
    } catch (e) {
      _decodeFailStreak++;
      dk = 'parse_fail: $e';
      if (_decodeFailStreak >= 3) {
        state = state.copyWith(dashboardEncrypted: true);
      }
    }

    final n = _plainLogCount++;
    final detail = n < 3 || n % 20 == 0;
    BleLogger.instance.event('dashboard_payload', {
      'len': raw.length,
      'hex': detail ? BleLogger.hex(raw, maxBytes: 64) : null,
      'plain': detail ? plainHex : null,
      'dk': detail ? dk : null,
    });
  }

  /// Tự kết nối lại xe lần trước khi mở app.
  Future<bool> tryRestoreLastBike() async {
    if (_restoreBusy) return state.phase == BlePhase.connected;
    if (state.phase == BlePhase.connected || state.phase == BlePhase.connecting) return true;
    _restoreBusy = true;
    try {
      final prefs = await _prefs;
      final id = prefs.getString(_kLastBikeId);
      if (id == null || id.isEmpty) {
        return false;
      }
      if (state.phase == BlePhase.connected || state.phase == BlePhase.connecting) return true;

      // Đảm bảo đủ quyền BLE trên Android
      await BlePermissions.ensure();

      // Chờ Bluetooth bật nếu vừa mở app
      try {
        if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
          state = state.copyWith(
            phase: BlePhase.connecting,
            message: 'Đang đợi Bluetooth bật…',
          );
          await FlutterBluePlus.adapterState
              .where((s) => s == BluetoothAdapterState.on)
              .first
              .timeout(const Duration(seconds: 4));
        }
      } catch (_) {}

      final name = prefs.getString(_kLastBikeName) ?? 'Xe Dat Bike';
      BluetoothDevice device = BluetoothDevice.fromId(id);
      final connectedMatch = FlutterBluePlus.connectedDevices
          .where((d) => d.remoteId.str == id)
          .firstOrNull;
      if (connectedMatch != null) {
        device = connectedMatch;
      }

      _reconnectAttempts = 0;
      state = state.copyWith(
        phase: BlePhase.connecting,
        device: device,
        bikeName: name,
        message: 'Đang kết nối với xe $name…',
      );
      try {
        final ok = await _establish(device);
        if (ok && state.isAuthorized) {
          await _saveLastBike(device, name);
          _watchConnection(device);
          state = state.copyWith(phase: BlePhase.connected, reconnectAttempt: 0, message: null);
          unawaited(ForegroundService.start(
            title: 'Dat Bike: $name',
            text: 'Đã kết nối Bluetooth — Sẵn sàng điều khiển',
          ));
          return true;
        }
      } catch (e) {
        BleLogger.instance.event('restore_attempt_failed', {'error': '$e'});
      }

      // Xe chưa ở gần hoặc chưa bật nguồn: chuyển sang reconnect loop (giới hạn tối đa 5 lần)
      _scheduleReconnect(device);
      return false;
    } finally {
      _restoreBusy = false;
    }
  }

  /// Chờ tối thiểu 800ms kể từ lần gửi lệnh trước để bảo đảm MCU và CAN bus
  /// truyền tin cậy tới BMS, không bị nghẽn mailbox hoặc rớt gói tin BMS.
  Future<void> _throttleCommand() async {
    if (_lastCommandCompletedAt != null) {
      final elapsed = DateTime.now().difference(_lastCommandCompletedAt!);
      const minInterval = Duration(milliseconds: 800);
      if (elapsed < minInterval) {
        final waitMs = minInterval.inMilliseconds - elapsed.inMilliseconds;
        BleLogger.instance.event('cmd_throttle_wait', {'wait_ms': waitMs});
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    }
  }

  /// Lệnh BẬT XE — theo flow app gốc trong btsnoop 16:16:34:
  /// plain '1' (0x31) vào POWER_SWITCH_CHAR + protected '1' vào
  /// POWER_PROTECTED_CHAR khi có session key. Chỉ gửi khi ĐÃ xác thực.
  Future<void> turnOnBike() async {
    if (_isCommandBusy) {
      throw Exception('Xe đang xử lý lệnh trước đó, vui lòng đợi 1 giây...');
    }
    await _throttleCommand();
    _isCommandBusy = true;
    try {
      await _sendPowerCommand('1', 'MỞ XE');
    } finally {
      _isCommandBusy = false;
      _lastCommandCompletedAt = DateTime.now();
    }
  }

  /// Lệnh TẮT XE — plain '0' (0x30) + protected '0'.
  Future<void> turnOffBike() async {
    if (_isCommandBusy) {
      throw Exception('Xe đang xử lý lệnh trước đó, vui lòng đợi 1 giây...');
    }
    await _throttleCommand();
    _isCommandBusy = true;
    try {
      await _sendPowerCommand('0', 'TẮT XE');
    } finally {
      _isCommandBusy = false;
      _lastCommandCompletedAt = DateTime.now();
    }
  }

  Future<void> _sendPowerCommand(String value, String label) async {
    if (!state.isAuthorized) {
      state = state.copyWith(
          message: 'Chưa xác thực phiên — xe sẽ bỏ qua lệnh $label');
      BleLogger.instance.event('power_blocked', {
        'reason': 'chưa authenticate — KHÔNG gửi (tránh xe drop link)',
      });
      throw Exception('Chưa xác thực phiên xe (bật/tắt bị chặn)');
    }

    // KHÓA AN TOÀN KHI ĐANG CHẠY:
    // Tuyệt đối không cho tắt nguồn hoặc khóa xe nếu xe đang lăn bánh (> 0.5 km/h)
    final spd = state.lastTelemetry?.speed ?? 0.0;
    if (value == '0' && spd > 0.5) {
      final warn =
          'Không thể tắt/khóa xe khi xe đang di chuyển (${spd.toStringAsFixed(1)} km/h)!';
      state = state.copyWith(message: warn);
      BleLogger.instance.event('power_command_blocked_safety', {
        'speed': spd,
        'val': value,
        'label': label,
      });
      throw Exception(warn);
    }

    bool sent = false;
    // Bước 0 theo capture app gốc: protected write lên char lệnh ĐỘNG (slot
    // sau bikeSerial, UUID xoay mỗi phiên) TRƯỚC khi bật/tắt.
    if (_sessionKey != null) {
      final dyn = _findDynamicCmdChar();
      if (dyn != null) {
        try {
          final frame = BikeSessionCrypto.buildProtectedWrite(
            sessionKey: _sessionKey!,
            counter: _writeCounter++,
            characteristicUuid: dyn.uuid.str128,
            data: value.codeUnits,
          );
          await dyn.write(frame, withoutResponse: false);
          BleLogger.instance.event('power_command', {
            'target': 'dynamicCmdChar',
            'uuid': dyn.uuid.str128,
            'val': value,
            'counter': _writeCounter - 1,
          });
          sent = true;
          // Delay 250ms giữa các packet liên tiếp để CAN bus tới BMS nhận đúng tín hiệu
          await Future.delayed(const Duration(milliseconds: 250));
        } catch (e) {
          BleLogger.instance.event('power_err',
              {'target': 'dynamicCmdChar', 'error': '$e'});
        }
      }
    }
    for (final c in state.characteristics) {
      final uuid = c.uuid.str128.toLowerCase();
      // 1. Plain write '1'/'0' vào POWER_SWITCH_CHAR (350d9a82 — Write #11
      //    handle 0x0038 trong capture, sau khi session đã establish)
      if (uuid == Gatt.powerSwitchChar.toLowerCase()) {
        try {
          await c.write(value.codeUnits, withoutResponse: false);
          BleLogger.instance.event('power_command', {'target': 'powerSwitchChar', 'val': value});
          sent = true;
          // Delay 250ms để MCU hoàn tất xử lý trước khi nhận protected write tiếp theo
          await Future.delayed(const Duration(milliseconds: 250));
        } catch (e) {
          BleLogger.instance.event('power_err', {'target': 'powerSwitchChar', 'error': '$e'});
        }
      }
      // 2. Protected write vào POWER_PROTECTED_CHAR (eec8fd7f) — counter
      //    toàn cục tiếp diễn của handshake (đúng như capture: 0,1 rồi 2,3…)
      if (uuid == Gatt.powerProtectedChar.toLowerCase() && _sessionKey != null) {
        try {
          final frame = BikeSessionCrypto.buildProtectedWrite(
            sessionKey: _sessionKey!,
            counter: _writeCounter++,
            characteristicUuid: Gatt.powerProtectedChar,
            data: value.codeUnits,
          );
          await c.write(frame, withoutResponse: false);
          BleLogger.instance.event('power_command', {
            'target': 'powerProtectedChar',
            'val': value,
            'counter': _writeCounter - 1,
            'hex': BleLogger.hex(frame),
          });
          sent = true;
          await Future.delayed(const Duration(milliseconds: 250));

          // Confirmation Write (ghi lần 2 khớp 100% btsnoop app gốc handle 0x003a):
          // Khi xe đang tắt hoặc khóa, gói 1 đánh thức MCU/hú còi, gói 2 chốt rơ-le mở nguồn ngay lần bấm đầu tiên!
          final frame2 = BikeSessionCrypto.buildProtectedWrite(
            sessionKey: _sessionKey!,
            counter: _writeCounter++,
            characteristicUuid: Gatt.powerProtectedChar,
            data: value.codeUnits,
          );
          await c.write(frame2, withoutResponse: false);
          BleLogger.instance.event('power_command_confirm', {
            'target': 'powerProtectedChar_confirm',
            'val': value,
            'counter': _writeCounter - 1,
            'hex': BleLogger.hex(frame2),
          });
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          BleLogger.instance.event('power_err', {'target': 'powerProtectedChar', 'error': '$e'});
        }
      }
    }
    if (sent) {
      state = state.copyWith(message: 'Đã gửi lệnh $label');
    } else {
      throw Exception('Không tìm thấy cổng điều khiển nguồn xe');
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _cancelReconnect();
    _stopKeepalive();
    _findBikeTimeoutTimer?.cancel();
    _findBikeTimeoutTimer = null;
    _findBikePeriodicTimer?.cancel();
    _findBikePeriodicTimer = null;
    _sessionKey = null;
    await _connSub?.cancel();
    _connSub = null;
    await _notifySub?.cancel();
    _notifySub = null;
    for (final d in FlutterBluePlus.connectedDevices) {
      try {
        await d.disconnect();
      } catch (_) {}
    }
    // watcher đã bị huỷ ở trên nên close log tại đây (flush toàn bộ buffer)
    await BleLogger.instance.close();
    unawaited(ForegroundService.stop());
    state = state.copyWith(
      phase: BlePhase.disconnected,
      isAuthorized: false,
      isFindingBike: false,
    );
  }

  /// Gửi lệnh Mở khóa xe.
  Future<String> unlockBike() async {
    final device = _device;
    if (device == null || state.phase != BlePhase.connected) {
      return 'Xe chưa được kết nối Bluetooth!';
    }
    if (_isCommandBusy) {
      return 'Xe đang bận xử lý lệnh trước, vui lòng đợi giây lát...';
    }
    try {
      await turnOnBike();
      return 'Thành công: Đã gửi lệnh MỞ XE (Power ON)!';
    } catch (e) {
      return 'Lỗi gửi lệnh mở xe: $e';
    }
  }

  /// Gửi lệnh Khóa xe.
  Future<String> lockBike() async {
    final device = _device;
    if (device == null || state.phase != BlePhase.connected) {
      return 'Xe chưa được kết nối Bluetooth!';
    }
    if (_isCommandBusy) {
      return 'Xe đang bận xử lý lệnh trước, vui lòng đợi giây lát...';
    }
    try {
      await turnOffBike();
      return 'Thành công: Đã gửi lệnh TẮT/KHÓA XE (Power OFF)!';
    } catch (e) {
      return 'Lỗi gửi lệnh tắt/khóa xe: $e';
    }
  }

  /// Đồng bộ giờ hệ thống từ điện thoại gửi thẳng vào màn hình LCD Taplo xe.
  /// Characteristic: Gatt.currentTimeChar (44e2bde6-9cd5-4159-9d43-a3e3f4e9c737).
  /// Payload format: Chuỗi ASCII số giây từ 00:00:00 theo giờ UTC (0..86399) = (utcHour * 3600) + (utcMinute * 60) + utcSecond.
  /// Chuẩn btsnoop thực tế: 23:16:22 GMT+7 -> 16:16:22 UTC -> "58582" (UTF-8 ASCII).
  /// Taplo xe dùng giá trị UTC này để hiển thị giờ địa phương chuẩn xác không bị lệch.
  /// Ghi dạng protected write nếu đã có session key, hoặc plain write.
  Future<String> syncTimeWithBike([DateTime? customTime]) async {
    final device = _device;
    if (device == null || state.phase != BlePhase.connected) {
      return 'Xe chưa được kết nối Bluetooth!';
    }

    final localTime = customTime ?? DateTime.now();
    final utcTime = localTime.toUtc();
    final totalSecondsUtc = (utcTime.hour * 3600) + (utcTime.minute * 60) + utcTime.second;
    final payload = utf8.encode(totalSecondsUtc.toString());

    final timeChar = _findCharacteristic(Gatt.currentTimeChar);
    if (timeChar == null) {
      BleLogger.instance.event('sync_time_err', {'error': 'Characteristic currentTimeChar not found'});
      return 'Không tìm thấy characteristic đồng bộ giờ trên xe!';
    }

    try {
      if (_sessionKey != null) {
        final frame = BikeSessionCrypto.buildProtectedWrite(
          sessionKey: _sessionKey!,
          counter: _writeCounter++,
          characteristicUuid: Gatt.currentTimeChar,
          data: payload,
        );
        await timeChar.write(frame, withoutResponse: false);
        BleLogger.instance.event('sync_time_success', {
          'type': 'protected',
          'secondsUtc': totalSecondsUtc,
          'timeLocal': localTime.toIso8601String(),
          'counter': _writeCounter - 1,
        });
      } else {
        await timeChar.write(payload, withoutResponse: false);
        BleLogger.instance.event('sync_time_success', {
          'type': 'plain',
          'secondsUtc': totalSecondsUtc,
          'timeLocal': localTime.toIso8601String(),
        });
      }

      state = state.copyWith(lastTimeSynced: localTime);
      final formattedTime = '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}';
      return 'Đã đồng bộ giờ $formattedTime vào màn hình xe thành công!';
    } catch (e) {
      BleLogger.instance.event('sync_time_err', {'error': '$e'});
      return 'Lỗi đồng bộ giờ vào xe: $e';
    }
  }


  Timer? _findBikeTimeoutTimer;
  Timer? _findBikePeriodicTimer;

  /// Bắt đầu tìm xe (phát tín hiệu đánh kèn/buzzer liên tục trong bãi xe) — tự dừng sau [timeout].
  Future<String> findBike({Duration timeout = const Duration(seconds: 10)}) async {
    final device = _device;
    if (device == null || state.phase != BlePhase.connected || !state.isAuthorized) {
      return 'Xe chưa được kết nối Bluetooth hoặc chưa xác thực!';
    }
    final spd = state.lastTelemetry?.speed ?? 0.0;
    if (spd > 0.5) {
      return 'Chức năng tìm xe không khả dụng khi xe đang di chuyển!';
    }

    _findBikeTimeoutTimer?.cancel();
    _findBikePeriodicTimer?.cancel();

    state = state.copyWith(isFindingBike: true, message: 'Đang thử nghiệm phát tín hiệu còi tìm xe...');
    BleLogger.instance.event('find_bike_start', {
      'timeout_s': timeout.inSeconds,
      'pattern': state.findBikePattern,
    });

    final pattern = state.findBikePattern;
    final intervalMs = switch (pattern) {
      1 => 750,  // Nhịp đôi Staccato
      2 => 450,  // Báo động dồn dập
      _ => 1100, // Tiêu chuẩn 1.1s
    };

    // Phát tiếng còi đầu tiên ngay lập tức
    await _sendFindBikeSignal('1');

    // Lặp lại phát tiếng còi theo pattern đã cấu hình
    _findBikePeriodicTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) async {
      if (!state.isFindingBike) {
        timer.cancel();
        return;
      }
      try {
        if (pattern == 1) {
          await _sendFindBikeSignal('1');
          await Future.delayed(const Duration(milliseconds: 160));
          await _sendFindBikeSignal('0');
          await Future.delayed(const Duration(milliseconds: 100));
          await _sendFindBikeSignal('1');
        } else {
          await _sendFindBikeSignal('1');
        }
      } catch (e) {
        BleLogger.instance.event('find_bike_tick_err', {'error': '$e'});
      }
    });

    _findBikeTimeoutTimer = Timer(timeout, () {
      stopFindBike();
    });
    final patName = switch (pattern) {
      1 => 'Nhịp đôi Staccato',
      2 => 'Báo động dồn dập',
      _ => 'Tiêu chuẩn',
    };
    return 'Đang thử nghiệm phát tín hiệu còi xe ($patName) trong ${timeout.inSeconds}s (Alert Service)...';
  }

  /// Dừng phát tín hiệu tìm xe.
  Future<String> stopFindBike() async {
    _findBikeTimeoutTimer?.cancel();
    _findBikeTimeoutTimer = null;
    _findBikePeriodicTimer?.cancel();
    _findBikePeriodicTimer = null;
    if (state.isFindingBike) {
      state = state.copyWith(isFindingBike: false, message: 'Đã dừng tìm xe');
      BleLogger.instance.event('find_bike_stop', {});
      try {
        await _sendFindBikeSignal('0');
      } catch (_) {}
    }
    return 'Đã dừng tìm xe.';
  }

  Future<void> _sendFindBikeSignal(String val) async {
    // Lệnh tìm xe (đánh kèn/hú còi) theo chuẩn Dat Bike:
    // 1. Characteristic chính BEEP_ACTIVE_CHAR_UUID / getCharFindBikeUuid:
    //    350d9a82-b3f3-4213-bdda-6403be495f53 trong Info Service (d4905f67).
    //    App gốc gọi makeWriter(BEEP_ACTIVE_CHAR_UUID)(device, '1') để bật còi, '0' để tắt còi.
    // 2. Alert/Beep Service (5b6d1069-a0bc-4875-ba5b-fdc94647d918):
    //    e0b2b4b4-4b1e-4f3e-8f1e-6b3e4b4b4b4b (Write có response)
    //    và các characteristic phụ (07765f94, 68311857, 46a7b351, 4244dedb).

    final dataAscii = val.codeUnits; // [0x31] ('1') hoặc [0x30] ('0')
    bool sentSuccess = false;

    // TUYỆT ĐỐI KHÔNG ghi vào 350d9a82 (powerSwitchChar) vì đây là công tắc nguồn xe!
    // Ghi thử nghiệm vào Alert / Beep Service 5b6d1069:

    // Delay nhỏ 100ms giữa các service để CAN bus/MCU xử lý êm
    await Future.delayed(const Duration(milliseconds: 100));

    // 2. Ghi thêm lên Beep / Alert Service 5b6d1069 (e0b2b4b4 và các phụ):
    for (final c in state.characteristics) {
      final uuid = c.uuid.str128.toLowerCase();
      if (uuid == Gatt.beepMainChar.toLowerCase()) {
        try {
          await c.write(dataAscii, withoutResponse: false);
          BleLogger.instance.event('find_bike_beep_main_success', {
            'target': c.uuid.str128,
            'val': val,
          });
          sentSuccess = true;
        } catch (e) {
          try {
            await c.write(dataAscii, withoutResponse: true);
            sentSuccess = true;
          } catch (_) {}
        }
      } else if (uuid == '07765f94-d850-4e87-a2cf-6bae5d9a0b67' ||
          uuid == '68311857-4f93-4060-a42d-16da35a5843c' ||
          uuid == '46a7b351-9343-4774-a306-6b533899344a' ||
          uuid == '4244dedb-7b6b-4774-9525-d37fde1c67da') {
        try {
          await c.write(dataAscii, withoutResponse: true);
          BleLogger.instance.event('find_bike_aux_success', {
            'target': c.uuid.str128,
            'val': val,
          });
        } catch (_) {}
      }
    }

    BleLogger.instance.event('find_bike_result', {
      'val': val,
      'success': sentSuccess,
    });
  }




  void _startKeepalive() {
    if (!enableKeepalive) return;
    _keepaliveTimer?.cancel();
    _keepaliveCount = 0;
    _keepaliveTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      _runKeepaliveCycle();
    });
    BleLogger.instance.event('keepalive_start', {});
  }

  void _stopKeepalive() {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
  }

  /// Mot chu ky: ghi auth response cho nonce hien hanh -> ghi password ->
  /// doc nonce moi. Xe derive lai sessionKey tai auth write (reset counter)
  /// nen app re-derive bang CHINH nonce vua tra loi roi cap nhat nonce moi.
  Future<void> _runKeepaliveCycle() async {
    if (_keepaliveBusy || !state.isAuthorized) return;
    final nonce = _lastAuthNonce15;
    final dev = _device;
    if (nonce == null || dev == null || _activePassword.isEmpty) return;
    BluetoothCharacteristic? find(String uuid) {
      for (final c in state.characteristics) {
        if (c.uuid.str128.toLowerCase() == uuid.toLowerCase()) return c;
      }
      return null;
    }

    final authChar = find(Gatt.authorizationChar);
    if (authChar == null) return;
    _keepaliveBusy = true;
    try {
      final resp = BikeSessionCrypto.computeAuthResponse(
        pairingToken: Gatt.defaultPairingToken,
        nonce15: nonce,
      );
      await authChar.write(resp, withoutResponse: false);
      final post = await authChar.read();
      _sessionKey = BikeSessionCrypto.deriveSessionKey(
        pairingToken: Gatt.defaultPairingToken,
        password: _activePassword,
        challenge: nonce,
      );
      _writeCounter = 0;
      if (post.length == 16) {
        _lastAuthNonce15 = Uint8List.fromList(post.sublist(0, 15));
      }
      _keepaliveCount++;
      if (_keepaliveCount == 1 || _keepaliveCount % 20 == 0) {
        BleLogger.instance.event('keepalive', {
          'n': _keepaliveCount,
          'answered': BleLogger.hex(nonce),
        });
      }
    } catch (e) {
      BleLogger.instance.event('keepalive_error', {'error': '$e'});
      _stopKeepalive();
    } finally {
      _keepaliveBusy = false;
    }
  }

  /// Char lệnh ĐỘNG: char đứng ngay sau bikeSerial (44e2bde6) trong info
  /// service — UUID XOAY theo phiên (14/10: ec97fdf9-0e16-cf8c…, 20/10:
  /// 7f13fe5c-…-97fd-f90e16cf8c28 — cùng đuôi '0e16cf8c28'). Capture app
  /// gốc ghi protected '0' lên char này TRƯỚC khi bật xe.
  BluetoothCharacteristic? _findDynamicCmdChar() {
    final chars = state.characteristics;
    for (var i = 0; i + 1 < chars.length; i++) {
      if (chars[i].uuid.str128.toLowerCase() == Gatt.bikeSerial.toLowerCase()) {
        final next = chars[i + 1];
        if (next.serviceUuid.str128.toLowerCase() ==
                Gatt.infoService.toLowerCase() &&
            (next.properties.write || next.properties.writeWithoutResponse)) {
          return next;
        }
      }
    }
    return null;
  }

  Uint8List _sessionKeyOf(String token, String pw, Uint8List salt) =>
      BikeSessionCrypto.deriveSessionKey(
          pairingToken: token, password: pw, challenge: salt);

  /// Quy trình xác thực phiên theo TRÌNH TỰ THẬT của app gốc (btsnoop
  /// 2026-10-14 16:16, máy Samsung — xem docs/ble_session_protocol.md).
  ///
  /// Luồng đã verify:
  ///   1. (bond nếu link chưa mã hoá — err 0x05/137)
  ///   2. Đọc 16B từ AUTHORIZATION_CHAR (5e9a2c71): 15B nonce + 1B status
  ///   3. Ghi 16B auth response lên CHÍNH char đó
  ///   4. Đọc lại — status byte 0x01 = xe chấp nhận, 0x00 = từ chối
  ///   5. deriveSessionKey với nonce mới đọc được sau khi chấp nhận
  ///   6. Protected-write password ASCII lên bikeSerial (counter 0)
  ///   7. Ghi pairingToken UTF-8 lên sessionUuid (87efab0d)
  ///   8. Protected-write password lần 2 (counter 1)
  ///
  /// ⚠️ Bước 3-4 hiện sẽ THẤT BẠI trên xe thật: công thức auth response chưa
  /// crack được (computeAuthResponse là placeholder). Flow dừng an toàn ngay
  /// khi status != 0x01 — không spam ghi, không gửi lệnh khi chưa xác thực.
  Future<bool> authenticateSession({
    BluetoothDevice? targetDevice,
    String? pairingToken,
    String? password,
    bool forceRegister = false,
  }) async {
    final chars = state.characteristics;
    if (chars.isEmpty) return false;

    final dev = targetDevice ?? state.device;

    final token = (pairingToken?.isNotEmpty ?? false)
        ? pairingToken!
        : Gatt.defaultPairingToken;
    final prefs = await _prefs;
    final stored = prefs.getString(_kBikePassword);
    final hasStoredPassword = stored != null && stored.isNotEmpty;
    // PIN ưu tiên: password truyền vào (nếu có) -> password đã lưu trong prefs -> rỗng
    final pin = (password != null && password.isNotEmpty)
        ? password
        : (hasStoredPassword ? stored : '');

    BluetoothCharacteristic? find(String uuid) {
      final clean = uuid.toLowerCase().replaceAll('-', '');
      for (final c in chars) {
        if (c.uuid.str128.toLowerCase().replaceAll('-', '') == clean) return c;
      }
      return null;
    }

    try {
      BleLogger.instance.event('auto_handshake_start', {'token': token, 'pin': pin});

      final authChar = find(Gatt.authorizationChar);
      if (authChar == null) {
        BleLogger.instance.event('auto_handshake_err',
            {'error': 'Không tìm thấy AUTHORIZATION_CHAR (5e9a2c71)'});
        return false;
      }

      // ===== BƯỚC 1 (nếu cần): bond để link được mã hoá =====
      try {
        await authChar.read();
      } catch (e) {
        if (_isAuthError(e)) {
          if (dev != null) {
            await _ensureBonded(dev, reason: 'auth char cần link mã hoá');
          }
        } else {
          rethrow;
        }
      }

      final appAuthChar = find(Gatt.appAuthChar);

      // ===== BƯỚC 1.5: Giải Challenge-Response SHA-256 trên c8eaf27b (appAuthChar) =====
      // FW 1.14.0 yêu cầu isAppVerified == 1 thì xe mới chấp nhận Phase 1 Auth (5e9a2c71).
      // Khi xe tắt/bật nguồn hoặc sau khi đứt kết nối, isAppVerified reset về 0.
      // Giải thuật chuẩn trích xuất từ bundle app gốc (hàm _fun9954) & btsnoop thật:
      //   - Xe sinh 4 bytes random challenge trên c8eaf27b.
      //   - App đọc 4 bytes: challenge = readUInt32LE(0) >> 1.
      //   - App tính SHA-256("$challenge$password") ra chuỗi hex 64 ký tự thường.
      //   - App ghi 64 bytes ASCII hex lên c8eaf27b.
      //   - Xe kiểm tra khớp với NVS password, set isAppVerified = 1 và trả ack.
      //   - Nhờ đó, bước ghi HMAC lên 5e9a2c71 tiếp theo xe sẽ chấp nhận status 0x01 mà KHÔNG CẦN QUẸT THẺ NFC!
      if (pin.isNotEmpty && appAuthChar != null && !forceRegister) {
        try {
          final challengeRaw = await appAuthChar.read();
          BleLogger.instance.event('auto_handshake_app_auth_read', {
            'hex': BleLogger.hex(challengeRaw),
            'len': challengeRaw.length,
          });
          if (challengeRaw.length >= 4) {
            final respHex = BikeSessionCrypto.computeAppAuthChallengeResponse(
              challengeRaw: challengeRaw,
              password: pin,
            );
            BleLogger.instance.event('auto_handshake_app_auth_solve', {
              'respHex': respHex,
              'candidate_pw': pin,
            });
            await appAuthChar.write(ascii.encode(respHex), withoutResponse: false);
            // Delay ngắn như capture btsnoop (~40-50ms)
            await Future.delayed(const Duration(milliseconds: 50));
            try {
              final ack = await appAuthChar.read();
              BleLogger.instance.event('auto_handshake_app_auth_ack', {
                'hex': BleLogger.hex(ack),
                'verified': ack.isNotEmpty && (ack[0] & 1) == 1,
              });
            } catch (_) {}
          }
        } catch (e) {
          BleLogger.instance.event('auto_handshake_app_auth_error', {'error': '$e'});
        }
      }

      // ===== BƯỚC 2: đọc nonce 16B (15B nonce + 1B status) =====
      final nonce1 = await authChar.read();
      BleLogger.instance.event('auto_handshake_challenge',
          {'hex': BleLogger.hex(nonce1), 'len': nonce1.length});
      if (nonce1.length != 16) {
        BleLogger.instance.event('auto_handshake_err',
            {'error': 'Nonce phải 16B, nhận ${nonce1.length}'});
        return false;
      }
      var nonce15 = Uint8List.fromList(nonce1.sublist(0, 15));
      final status1 = nonce1[15];
      BleLogger.instance.event('auto_handshake_status',
          {'status': status1, 'note': status1 == 0x01 ? 'đã auth từ trước' : 'chưa auth'});

      // ===== BƯỚC 3+4: ghi auth response, đọc lại kiểm status =====
      // QUAN TRỌNG: Ngay cả khi status1 == 0x01 (xe đã authorized từ trước hoặc sau reconnect),
      // BẮT BUỘC vẫn phải ghi HMAC response lên 5e9a2c71 (y hệt btsnoop app gốc conn2 @ 23:16:47).
      // Việc ghi này kích hoạt onWriteAuthentication của MCU xe để:
      //   1. Đồng bộ Session Key cho phiên kết nối hiện tại.
      //   2. Reset bộ đếm gói tin (writeCounter) và keystream counter của Dashboard về 0.
      // Nếu bỏ qua bước ghi này khi reconnect, app và xe sẽ lệch Session Key -> hỏng giao diện & chức năng.
      Uint8List? acceptedNonce;
      const maxAttempts = 3;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        if (attempt > 1) {
          final fresh = await authChar.read();
          BleLogger.instance.event('auto_handshake_challenge',
              {'attempt': attempt, 'hex': BleLogger.hex(fresh)});
          if (fresh.length == 16) {
            nonce15 = Uint8List.fromList(fresh.sublist(0, 15));
          }
        }
        final resp = BikeSessionCrypto.computeAuthResponse(
          pairingToken: token,
          nonce15: nonce15,
        );

        // Ghi response lên 5e9a2c71 (authChar / onWriteAuthentication).
        await authChar.write(resp, withoutResponse: false);
        BleLogger.instance.event('auto_handshake_response_sent',
            {'attempt': attempt, 'hex': BleLogger.hex(resp)});

        // Xe cần một khoảng thời gian ngắn để xử lý (capture: ~30-40ms)
        await Future.delayed(const Duration(milliseconds: 120));

        final post = await authChar.read();
        BleLogger.instance.event('auto_handshake_post_status',
            {'hex': BleLogger.hex(post)});
        if (post.length == 16 && post[15] == Gatt.authStatusOk) {
          acceptedNonce = Uint8List.fromList(post);
          break;
        }
        if (attempt < maxAttempts) {
          await Future.delayed(
              Duration(milliseconds: attempt == 1 ? 300 : 1500));
        }
      }

      if (acceptedNonce == null) {
        BleLogger.instance.event('auto_handshake_rejected', {
          'note': 'xe giữ status 0x00 — token hoặc challenge auth chưa được chấp nhận',
        });
        state = state.copyWith(
          isAuthorized: false,
          message: hasStoredPassword
              ? 'Xe từ chối xác thực (status 00) — vui lòng quẹt thẻ NFC vào xe nếu đổi điện thoại'
              : 'Xe từ chối xác thực (status 00) — vui lòng quẹt thẻ NFC vào xe để ghép nối lần đầu',
        );
        return false;
      }

      // Đảm bảo tạo bond cấp hệ thống để xe nhận diện là Owner cho các lần kết nối sau
      if (dev != null) {
        await _ensureBonded(dev, reason: 'xác thực thành công, thiết lập bond');
      }

      // ===== BƯỚC 5: chiến lược password — SELF-REGISTER như app gốc =====
      // Flow đã giải mã hoàn toàn từ btsnoop conn1 + firmware:
      //   auth(nonce1, token) → ghi password MỚI 12 ký tự lên c8eaf27b
      //   (xe lưu NVS 'password') → auth(nonce2) → xe derive sessionKey =
      //   HKDF(nonce2_15, token + password MỚI) → pin-write → điều khiển.
      // App gốc tự sinh password random mỗi khi pair/re-register — password
      // hiện tại của xe là chuỗi random không biết trước → cách duy nhất:
      // app mình TỰ ĐĂNG KÝ password của mình (đúng flow app gốc).
      final saltNonce = nonce15;
      final dash = find(Gatt.dashboardCharacteristic);
      final serialChar = find(Gatt.bikeSerial);
      int ctr(List<int> r) => r.length >= 4
          ? r[0] | (r[1] << 8) | (r[2] << 16) | (r[3] << 24)
          : -1;

      // Thử 1 pin-write + oracle; trả live?
      Future<bool> tryPassword(String label, String pw, Uint8List salt) async {
        final sk = BikeSessionCrypto.deriveSessionKey(
          pairingToken: token, password: pw, challenge: salt);
        BleLogger.instance.event('auto_handshake_try_password',
            {'candidate': label, 'key8': BleLogger.hex(sk.sublist(0, 8))});
        if (serialChar != null) {
          final frame = BikeSessionCrypto.buildProtectedWrite(
            sessionKey: sk,
            counter: _writeCounter++,
            characteristicUuid: Gatt.bikeSerial,
            data: pw.codeUnits,
          );
          await serialChar.write(frame, withoutResponse: false);
          BleLogger.instance.event('auto_handshake_pin_sent',
              {'candidate': label, 'hex': BleLogger.hex(frame)});
        }
        if (dash == null) return false;
        try {
          // Cho xe ~100ms xử lý frame vừa ghi
          await Future.delayed(const Duration(milliseconds: 100));
          final r1 = await dash.read();
          var live = _isValidTelemetry(sk, r1);
          final c1 = ctr(r1);
          var c2 = c1;
          if (!live) {
            await Future.delayed(const Duration(milliseconds: 900));
            final r2 = await dash.read();
            c2 = ctr(r2);
            live = _isValidTelemetry(sk, r2);
          }
          BleLogger.instance.event('auto_handshake_session_check',
              {'candidate': label, 'password': pw, 'counter1': c1,
               'counter2': c2, 'session_live': live,
               'telemetry_valid': live,
               // piggyback: salt + session key để decrypt payload offline
               'salt': BleLogger.hex(salt), 'sk': BleLogger.hex(sk)});
          return live;
        } catch (_) {
          return false;
        }
      }

      var live = false;
      var livePw = '';
      Uint8List? liveKey;

      // (a) Thử candidate password (pin)
      if (pin.isNotEmpty) {
        _writeCounter = 0;
        live = await tryPassword('candidate "$pin"', pin, saltNonce);
        if (!live) {
          _writeCounter = 0;
          final postNonce15 = Uint8List.fromList(acceptedNonce.sublist(0, 15));
          live = await tryPassword('candidate "$pin" (postNonce)', pin, postNonce15);
          if (live) {
            livePw = pin;
            liveKey = _sessionKeyOf(token, pin, postNonce15);
            await prefs.setString(_kBikePassword, pin);
          }
        } else if (live) {
          livePw = pin;
          liveKey = _sessionKeyOf(token, pin, saltNonce);
          await prefs.setString(_kBikePassword, pin);
        }
      }
      // (b) password đã register lần trước (prefs) nếu khác pin
      if (!live && hasStoredPassword && stored != pin) {
        _writeCounter = 0;
        live = await tryPassword('registered "$stored"', stored, saltNonce);
        if (!live) {
          _writeCounter = 0;
          final postNonce15 = Uint8List.fromList(acceptedNonce.sublist(0, 15));
          live = await tryPassword('registered "$stored" (postNonce)', stored, postNonce15);
          if (live) {
            livePw = stored;
            liveKey = _sessionKeyOf(token, stored, postNonce15);
            await prefs.setString(_kBikePassword, stored);
          }
        } else if (live) {
          livePw = stored;
          liveKey = _sessionKeyOf(token, stored, saltNonce);
          await prefs.setString(_kBikePassword, stored);
        }
      }
      // (c) SELF-REGISTER: Chỉ chạy khi CHƯA có password (lần đầu pair)
      // HOẶC khi ép buộc (forceRegister).
      // Tuyệt đối KHÔNG tự ý sinh password mới ghi đè lên xe mỗi lần reconnect,
      // vì sẽ làm mất đồng bộ NVS trên xe và khiến xe từ chối handshake.
      if (!live && (!hasStoredPassword || forceRegister) && appAuthChar != null) {
        final newPw = pin.isNotEmpty ? pin : () {
          const chars =
              'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
          final rng = Random.secure();
          return List.generate(12, (_) => chars[rng.nextInt(chars.length)]).join();
        }();
        BleLogger.instance.event('auto_handshake_register_password',
            {'new_password': newPw});
        try {
          await appAuthChar.write(newPw.codeUnits, withoutResponse: false);
          await Future.delayed(const Duration(milliseconds: 80));
          await appAuthChar.write(newPw.codeUnits, withoutResponse: false);
          await Future.delayed(const Duration(milliseconds: 80));
          try {
            final ack = await appAuthChar.read(); // 4B ack như capture
            BleLogger.instance.event('auto_handshake_register_ack',
                {'hex': BleLogger.hex(ack)});
          } catch (_) {}
        } catch (e) {
          BleLogger.instance.event('auto_handshake_register_error',
              {'error': '$e'});
        }

        // Re-auth với nonce mới → derive với password vừa đăng ký
        await Future.delayed(const Duration(milliseconds: 150));
        final nonce2 = await authChar.read();
        if (nonce2.length == 16) {
          final n2 = Uint8List.fromList(nonce2.sublist(0, 15));
          final resp2 = BikeSessionCrypto.computeAuthResponse(
              pairingToken: token, nonce15: n2);
          await authChar.write(resp2, withoutResponse: false);
          await Future.delayed(const Duration(milliseconds: 120));
          final post2 = await authChar.read();
          final ok2 = post2.length == 16 && post2[15] == Gatt.authStatusOk;
          BleLogger.instance.event('auto_handshake_reauth',
              {'post_status': BleLogger.hex(post2), 'ok': ok2});
          if (ok2) {
            if (post2.length == 16) {
              _lastAuthNonce15 = Uint8List.fromList(post2.sublist(0, 15));
            }
            final sk2 = _sessionKeyOf(token, newPw, n2);
            BleLogger.instance.event('auto_handshake_session_key', {
              'salt_nonce2': BleLogger.hex(n2),
              'session_key': BleLogger.hex(sk2),
              'password': newPw,
            });
            _writeCounter = 0;
            live = await tryPassword('self-registered', newPw, n2);
            if (live) {
              livePw = newPw;
              liveKey = _sessionKeyOf(token, newPw, n2);
              await prefs.setString(_kBikePassword, newPw);
            }
          }
        }
      }

      // Token lên 87efab0d + pin-write lần 2 nếu session sống
      if (live && liveKey != null) {
        final sessionUuidChar = find(Gatt.sessionUuid);
        if (sessionUuidChar != null) {
          await sessionUuidChar.write(token.codeUnits, withoutResponse: false);
          BleLogger.instance.event('auto_handshake_uuid_sent', {'token': token});
        }
        if (serialChar != null) {
          final frame2 = BikeSessionCrypto.buildProtectedWrite(
            sessionKey: liveKey,
            counter: _writeCounter++,
            characteristicUuid: Gatt.bikeSerial,
            data: livePw.codeUnits,
          );
          await serialChar.write(frame2, withoutResponse: false);
        }
        _sessionKey = liveKey;
        _activePassword = livePw;
        _startKeepalive();
        state = state.copyWith(
          isAuthorized: true,
          sessionKey: liveKey,
          message: 'SESSION HỢP LỆ — password '
              '"$livePw" sẵn sàng điều khiển',
        );

        // Sau khi session đã xác thực THÀNH CÔNG, đồng bộ giờ vào Taplo xe
        unawaited(syncTimeWithBike());
      } else {
        _sessionKey = null;
        _stopKeepalive();
        final msg = hasStoredPassword
            ? 'Auth Phase-1 OK nhưng session chưa hợp lệ với password đã lưu. '
              'Vui lòng quẹt thẻ NFC vào xe hoặc chọn "Quên xe" để ghép nối lại.'
            : 'Auth Phase-1 OK nhưng session chưa hợp lệ (đăng ký '
              'password mới chưa được xe chấp nhận) — gửi log để kiểm tra';
        state = state.copyWith(
          isAuthorized: false,
          sessionKey: null,
          message: msg,
        );
      }
      BleLogger.instance.event('auto_handshake_success');
      return true;
    } catch (e) {
      BleLogger.instance.event('auto_handshake_failed', {'error': '$e'});
      return false;
    }
  }

  /// Lỗi "cần mã hoá link": Android code 137 (GATT_ERROR) hoặc ATT 0x05
  /// Insufficient Authentication — app gốc gặp y hệt trong btsnoop trước khi bond.
  bool _isAuthError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('137') ||
        s.contains('insufficient') ||
        s.contains('gatt_auth') ||
        s.contains('auth_fail');
  }

  /// Bond (ghép nối+mã hoá) với xe — app gốc bond ngay sau discovery
  /// (btsnoop 16:16:15-17, bonding state 11→12). Trả về true nếu đã bond.
  Future<bool> _ensureBonded(BluetoothDevice device, {String reason = ''}) async {
    BleLogger.instance.event('bond_start', {'reason': reason});
    try {
      final currentBond = await device.bondState.first.timeout(
        const Duration(milliseconds: 1200),
        onTimeout: () => BluetoothBondState.none,
      );
      if (currentBond == BluetoothBondState.bonded) {
        BleLogger.instance.event('bond_already_bonded', {});
        return true;
      }
      await device.createBond();
      BleLogger.instance.event('bond_created', {});
      return true;
    } catch (e) {
      BleLogger.instance.event('bond_failed', {'error': '$e'});
      return false;
    }
  }


  /// Quên xe đã nhớ (unpair logic) — xoá cả bond hệ thống nếu có và xoá trạng thái.
  Future<void> forgetBike() async {
    _manualDisconnect = true;
    _cancelReconnect();
    _stopKeepalive();
    _findBikeTimeoutTimer?.cancel();
    _findBikeTimeoutTimer = null;
    _findBikePeriodicTimer?.cancel();
    _findBikePeriodicTimer = null;
    _sessionKey = null;

    final prefs = await _prefs;
    final savedId = prefs.getString(_kLastBikeId);
    final d = _device ?? (savedId != null ? BluetoothDevice.fromId(savedId) : null);
    if (d != null) {
      BleLogger.instance.event('forget_bike', {'device_id': d.remoteId.str});
      try {
        await d.removeBond();
      } catch (_) {}
      try {
        await d.disconnect();
      } catch (_) {}
    }
    for (final dev in FlutterBluePlus.connectedDevices) {
      try {
        await dev.disconnect();
      } catch (_) {}
    }

    await _connSub?.cancel();
    _connSub = null;
    await _notifySub?.cancel();
    _notifySub = null;

    await prefs.remove(_kLastBikeId);
    await prefs.remove(_kLastBikeName);
    await prefs.remove(_kBikePassword);

    await BleLogger.instance.close();
    unawaited(ForegroundService.stop());

    state = const BleState(
      phase: BlePhase.idle,
      message: 'Đã xóa thông tin xe',
      device: null,
      bikeName: null,
    );
  }

  // ------------------------------------------------------------------
  // Reconnect
  // ------------------------------------------------------------------

  void _watchConnection(BluetoothDevice device) {
    _connSub?.cancel();
    _connSub = FlutterBluePlus.events.onConnectionStateChanged.listen((e) async {
      if (e.device.remoteId != device.remoteId) return;
      if (e.connectionState == BluetoothConnectionState.disconnected) {
        BleLogger.instance.event('disconnected', {
          'device_id': device.remoteId.str,
          'manual': _manualDisconnect,
        });
        // HỦY NGAY subscription watcher để không bị trigger lặp lại khi các lệnh reconnect thất bại
        _connSub?.cancel();
        _connSub = null;

        _pollTimer?.cancel(); // hết poll spam 'device is not connected'
        _stopKeepalive();
        _notifySub?.cancel();
        _notifySub = null;
        _dashChar = null;
        _sessionKey = null;
        _writeCounter = 0;
        _decodeFailStreak = 0;
        _smoothedRssi = null;
        _rssiKalman.reset();
        _autoLockCounter = 0;
        _antiForgetCounter = 0;
        _walkUpTriggered = false;
        _batteryChar = null;
        _batteryPollCounter = 0;

        if (_manualDisconnect) {
          // Recovery-disconnect không đóng logger (log giữa chừng phải còn
          // sống để chẩn đoán) — chỉ disconnect chủ động của user mới đóng.
          if (!_recoveryDisconnect) {
            await BleLogger.instance.close();
          }
          return;
        }

        final wasBikeOn = state.lastTelemetry?.isBikeOn == true;
        _reconnectAttempts = 0;
        state = state.copyWith(
          phase: BlePhase.reconnecting,
          reconnectAttempt: 0,
          isAuthorized: false,
          sessionKey: null,
          dashboardEncrypted: false,
          message: (wasBikeOn && state.antiForgetAlert)
              ? '⚠️ CẢNH BÁO AN TOÀN: Xe vẫn đang BẬT nguồn khi ngắt kết nối! Hãy kiểm tra xe ngay.'
              : null,
        );

        _scheduleReconnect(device);
      }
    });
  }

  void _scheduleReconnect(BluetoothDevice device) {
    if (_manualDisconnect) return;
    // Android/firewall có thể bắn NHIỀU disconnect event cho 1 lần đứt —
    // nếu timer reconnect đang chờ thì bỏ qua event trùng (tránh đếm khống).
    if (_reconnectPending) {
      BleLogger.instance.event('reconnect_debounced', {});
      return;
    }
    _reconnectAttempts++;
    // Giới hạn số lần thử kết nối lại tối đa (_maxReconnect = 5 lần) theo backoff (2, 4, 8, 16, 30s)
    // Nếu sau 5 lần không tìm thấy xe, dừng quét ngầm và dừng ForegroundService để bảo toàn pin điện thoại.
    if (_reconnectAttempts > _maxReconnect) {
      _reconnectPending = false;
      _cancelReconnect();
      unawaited(ForegroundService.stop());
      state = state.copyWith(
        phase: BlePhase.disconnected,
        reconnectAttempt: _reconnectAttempts,
        message: 'Đã dừng tìm xe sau $_maxReconnect lần thử. Hãy đến gần xe và bấm "Kết nối lại".',
      );
      BleLogger.instance.event('reconnect_limit_reached', {'max': _maxReconnect});
      return;
    }

    final delay = (_reconnectAttempts <= _backoff.length) ? _backoff[_reconnectAttempts - 1] : 30;
    _reconnectPending = true;
    state = state.copyWith(
      phase: BlePhase.reconnecting,
      reconnectAttempt: _reconnectAttempts,
      message: 'Mất kết nối — thử lại sau ${delay}s (lần $_reconnectAttempts/$_maxReconnect)',
    );
    unawaited(ForegroundService.start(
      title: 'Dat Bike: ${state.bikeName ?? device.platformName}',
      text: 'Đang thử kết nối lại (lần $_reconnectAttempts/$_maxReconnect)...',
    ));
    BleLogger.instance
        .event('reconnect_scheduled', {'attempt': _reconnectAttempts, 'delay_s': delay});
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      _reconnectPending = false;
      if (_manualDisconnect || _reconnectAttempts > _maxReconnect) return;
      try {
        final ok = await _establish(device);
        if (ok && state.isAuthorized) {
          BleLogger.instance.event('reconnected', {'attempt': _reconnectAttempts});
          _reconnectAttempts = 0;
          state = state.copyWith(phase: BlePhase.connected, reconnectAttempt: 0, message: null);
          unawaited(ForegroundService.start(
            title: 'Dat Bike: ${state.bikeName ?? device.platformName}',
            text: 'Đã kết nối Bluetooth — Sẵn sàng điều khiển',
          ));
          _failStreak = 0;
          _watchConnection(device); // Chỉ gắn watcher khi ĐÃ KẾT NỐI THÀNH CÔNG!
        } else {
          throw Exception('Bắt tay phiên xe chưa hoàn tất');
        }
      } catch (e) {
        BleLogger.instance.event('reconnect_failed', {'attempt': _reconnectAttempts, 'error': '$e'});
        _failStreak++;
        if (_failStreak == 2) {
          state = state.copyWith(
            message: 'Đang đợi xe giải phóng phiên kết nối cũ (cooldown)… tiếp tục thử lại…',
          );
          BleLogger.instance.event('reconnect_waiting_cooldown', {'device': device.remoteId.str});
        }
        if (!_manualDisconnect) {
          _scheduleReconnect(device);
        }
      }
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectPending = false;
    if (FlutterBluePlus.isScanningNow) {
      try {
        FlutterBluePlus.stopScan();
      } catch (_) {}
    }
  }

  void _teardown() {
    _cancelReconnect();
    _stopKeepalive();
    _findBikeTimeoutTimer?.cancel();
    _findBikePeriodicTimer?.cancel();
    _pollTimer?.cancel();
    _connSub?.cancel();
    _notifySub?.cancel();
    _telemetry.close();
  }

  Future<String?> lastBikeName() async {
    final prefs = await _prefs;
    return prefs.getString(_kLastBikeName);
  }

  Future<String?> lastBikeId() async {
    final prefs = await _prefs;
    return prefs.getString(_kLastBikeId);
  }

  Future<void> _saveLastBike(BluetoothDevice device, String? name) async {
    final prefs = await _prefs;
    await prefs.setString(_kLastBikeId, device.remoteId.str);
    await prefs.setString(_kLastBikeName, name ?? device.platformName);
    state = state.copyWith(bikeName: name ?? device.platformName);
  }
}

final bleProvider = NotifierProvider<BleController, BleState>(BleController.new);
