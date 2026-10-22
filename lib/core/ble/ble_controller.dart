import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../proto/bike_log.dart' show BikeLogMsg, decodeBikeLogMsg, decodeDashboardStruct;
import '../services/foreground_service.dart';
import '../session/bike_session_crypto.dart';
import '../security/secure_key_manager.dart';
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
  final bool dashboardEncrypted;
  final List<BluetoothCharacteristic> characteristics;
  final bool isAuthorized;
  final Uint8List? sessionKey;
  final BikeLogMsg? lastTelemetry;
  final bool isFindingBike;
  final TripData trip;
  final bool autoLockWalkAway;
  final bool antiForgetAlert;
  final int autoLockDistance;
  final int antiForgetDistance;
  final int? rssi;

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
    this.isFindingBike = false,
    this.trip = const TripData(),
    this.autoLockWalkAway = false,
    this.antiForgetAlert = true,
    this.autoLockDistance = 1,
    this.antiForgetDistance = 1,
    this.rssi,
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
    bool? isFindingBike,
    TripData? trip,
    bool? autoLockWalkAway,
    bool? antiForgetAlert,
    int? autoLockDistance,
    int? antiForgetDistance,
    int? rssi,
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
        isFindingBike: isFindingBike ?? this.isFindingBike,
        trip: trip ?? this.trip,
        autoLockWalkAway: autoLockWalkAway ?? this.autoLockWalkAway,
        antiForgetAlert: antiForgetAlert ?? this.antiForgetAlert,
        autoLockDistance: autoLockDistance ?? this.autoLockDistance,
        antiForgetDistance: antiForgetDistance ?? this.antiForgetDistance,
        rssi: rssi ?? this.rssi,
      );
}

class BleController extends Notifier<BleState> {
  static const _kLastBikeId = 'last_bike_id';
  static const _kBikePassword = 'bike_password';
  static const _kLastBikeName = 'last_bike_name';
  static const _maxReconnect = 5;
  static const _backoff = [2, 4, 8, 16, 30];

  StreamSubscription? _connSub;
  StreamSubscription? _notifySub;
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  BluetoothCharacteristic? _dashChar;
  bool _manualDisconnect = false;
  bool _reconnectPending = false;
  int _reconnectAttempts = 0;
  int _failStreak = 0;
  int _decodeFailStreak = 0;
  int _plainLogCount = 0;

  Timer? _keepaliveTimer;
  Uint8List? _lastAuthNonce15;
  String _activePassword = '';
  int _keepaliveCount = 0;
  bool _keepaliveBusy = false;
  bool _establishBusy = false;
  bool _restoreBusy = false;
  bool _isCommandBusy = false;
  DateTime? _lastCommandCompletedAt;

  static const enableKeepalive = false;
  bool _recoveryDisconnect = false;
  Uint8List? _sessionKey;
  int _writeCounter = 0;

  final _telemetry = StreamController<BikeTelemetry>.broadcast();

  static const _kAutoLockWalkAway = 'auto_lock_walk_away';
  static const _kAntiForgetAlert = 'anti_forget_alert';
  static const _kAutoLockDistance = 'auto_lock_distance';
  static const _kAntiForgetDistance = 'anti_forget_distance';

  double? _smoothedRssi;
  int _autoLockCounter = 0;
  int _antiForgetCounter = 0;

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
    state = state.copyWith(
      bikeName: (savedId != null && savedName != null) ? savedName : state.bikeName,
      autoLockWalkAway: autoLock,
      antiForgetAlert: antiForget,
      autoLockDistance: autoLockDist,
      antiForgetDistance: antiForgetDist,
    );

    if (savedId != null && savedId.isNotEmpty) {
      unawaited(tryRestoreLastBike());
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
      title: 'My Bike',
      text: 'Đang kết nối với ${name ?? device.platformName}...',
    ));
    await BleLogger.instance.startSession();
    BleLogger.instance.event('connect_start', {
      'device_id': device.remoteId.str,
      'name': name ?? device.platformName,
    });

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
        _manualDisconnect = true;
        _recoveryDisconnect = true;
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
          title: 'My Bike: ${state.bikeName ?? device.platformName}',
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
        title: 'My Bike: ${state.bikeName ?? device.platformName}',
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

    try {
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        await FlutterBluePlus.adapterState
            .where((s) => s == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 4));
      }
    } catch (_) {}

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

    final allChars = <BluetoothCharacteristic>[];
    for (final s in services) {
      allChars.addAll(s.characteristics);
    }
    state = state.copyWith(device: device, characteristics: allChars);

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

    await authenticateSession(targetDevice: device);

    for (final service in services) {
      if (service.uuid.str128.toLowerCase() != Gatt.dashboardService) continue;
      for (final c in service.characteristics) {
        if (c.uuid.str128.toLowerCase() != Gatt.dashboardCharacteristic) continue;
        _dashChar = c;
        if (c.properties.notify) {

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

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
        Duration(milliseconds: Gatt.dashboardPollMs), (_) => _pollDashboard());
    await _pollDashboard();
    return state.isAuthorized;
  }

  Future<void> _pollDashboard() async {
    final c = _dashChar;
    if (c == null || state.phase != BlePhase.connected) return;

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

    try {
      final dev = _device;
      if (dev != null) {
        final curRssi = await dev.readRssi();
        _smoothedRssi = (_smoothedRssi == null)
            ? curRssi.toDouble()
            : (0.35 * curRssi + 0.65 * _smoothedRssi!);
        state = state.copyWith(rssi: curRssi);
        _checkAutoLockAndAlert();
      }
    } catch (_) {}
  }

  void _checkAutoLockAndAlert() {
    if (_smoothedRssi == null) return;
    final isBikeOn = state.lastTelemetry?.isBikeOn == true;
    final speed = state.lastTelemetry?.speed ?? 0.0;

    if (state.autoLockWalkAway && isBikeOn && speed <= 0.5) {
      const thresholds = [-75, -85, -92];
      final threshold = thresholds[state.autoLockDistance.clamp(0, 2)];
      if (_smoothedRssi! <= threshold) {
        _autoLockCounter++;

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

    if (state.antiForgetAlert && isBikeOn) {
      const alertThresholds = [-75, -85, -92];
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

  bool _isTelemetrySane(BikeLogMsg msg) {
    if (msg.speed.isNaN || msg.speed < 0 || msg.speed > 250) return false;
    if (msg.odo.isNaN || msg.odo < 0 || msg.odo > 500000) return false;
    if (msg.voltage.isNaN || msg.voltage < 10 || msg.voltage > 130) return false;
    if (msg.percent < 0 || msg.percent > 100) return false;
    if (msg.kmLeft.isNaN || msg.kmLeft < 0 || msg.kmLeft > 500) return false;
    return true;
  }

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

  void _handleDashboardPayload(List<int> raw) {

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

      final msg = (payloadToDecode.length >= 36)
          ? decodeDashboardStruct(payloadToDecode)
          : decodeBikeLogMsg(payloadToDecode);

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

      state = state.copyWith(lastTelemetry: msg, trip: currentTrip);
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

      await BlePermissions.ensure();

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

      final name = prefs.getString(_kLastBikeName) ?? 'Xe My Bike';
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
            title: 'My Bike: $name',
            text: 'Đã kết nối Bluetooth — Sẵn sàng điều khiển',
          ));
          return true;
        }
      } catch (e) {
        BleLogger.instance.event('restore_attempt_failed', {'error': '$e'});
      }

      _scheduleReconnect(device);
      return false;
    } finally {
      _restoreBusy = false;
    }
  }

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

          await Future.delayed(const Duration(milliseconds: 250));
        } catch (e) {
          BleLogger.instance.event('power_err',
              {'target': 'dynamicCmdChar', 'error': '$e'});
        }
      }
    }
    for (final c in state.characteristics) {
      final uuid = c.uuid.str128.toLowerCase();

      if (uuid == Gatt.powerSwitchChar.toLowerCase()) {
        try {
          await c.write(value.codeUnits, withoutResponse: false);
          BleLogger.instance.event('power_command', {'target': 'powerSwitchChar', 'val': value});
          sent = true;

          await Future.delayed(const Duration(milliseconds: 250));
        } catch (e) {
          BleLogger.instance.event('power_err', {'target': 'powerSwitchChar', 'error': '$e'});
        }
      }

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

    await BleLogger.instance.close();
    unawaited(ForegroundService.stop());
    state = state.copyWith(
      phase: BlePhase.disconnected,
      isAuthorized: false,
      isFindingBike: false,
    );
  }

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

  Timer? _findBikeTimeoutTimer;
  Timer? _findBikePeriodicTimer;

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

    state = state.copyWith(isFindingBike: true, message: 'Đang phát tín hiệu tìm xe (hú còi)...');
    BleLogger.instance.event('find_bike_start', {'timeout_s': timeout.inSeconds});

    await _sendFindBikeSignal('1');

    _findBikePeriodicTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (!state.isFindingBike) {
        timer.cancel();
        return;
      }
      try {
        await _sendFindBikeSignal('1');
      } catch (e) {
        BleLogger.instance.event('find_bike_tick_err', {'error': '$e'});
      }
    });

    _findBikeTimeoutTimer = Timer(timeout, () {
      stopFindBike();
    });
    return 'Đang phát tín hiệu tìm xe (hú còi) trong ${timeout.inSeconds} giây...';
  }

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

    final dataAscii = val.codeUnits;
    final dataByte = [val == '1' ? 1 : 0];
    bool sentSuccess = false;

    for (final c in state.characteristics) {
      final uuid = c.uuid.str128.toLowerCase();
      if (uuid == Gatt.findBikeChar.toLowerCase()) {
        try {
          await c.write(dataAscii, withoutResponse: false);
          BleLogger.instance.event('find_bike_primary_success', {
            'target': c.uuid.str128,
            'val': val,
            'mode': 'ascii_with_resp',
          });
          sentSuccess = true;
        } catch (e) {
          try {
            await c.write(dataByte, withoutResponse: false);
            BleLogger.instance.event('find_bike_primary_byte_success', {
              'target': c.uuid.str128,
              'val': val,
            });
            sentSuccess = true;
          } catch (e2) {
            try {
              await c.write(dataAscii, withoutResponse: true);
              sentSuccess = true;
            } catch (e3) {
              BleLogger.instance.event('find_bike_primary_err', {
                'target': c.uuid.str128,
                'error': '$e / $e2 / $e3',
              });
            }
          }
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));

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
    final bikeId = dev?.remoteId.str ?? '';
    var stored = await SecureKeyManager.getBikePassword(bikeId);
    if (stored == null || stored.isEmpty) {
      final legacy = prefs.getString(_kBikePassword);
      if (legacy != null && legacy.isNotEmpty) {
        stored = legacy;
        await SecureKeyManager.saveBikePassword(bikeId, legacy);
        await prefs.remove(_kBikePassword);
      }
    }
    final hasStoredPassword = stored != null && stored.isNotEmpty;

    final pin = (password != null && password.isNotEmpty)
        ? password
        : (hasStoredPassword ? stored : '');

    BluetoothCharacteristic? find(String uuid) {
      for (final c in chars) {
        if (c.uuid.str128.toLowerCase() == uuid.toLowerCase()) return c;
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

        await authChar.write(resp, withoutResponse: false);
        BleLogger.instance.event('auto_handshake_response_sent',
            {'attempt': attempt, 'hex': BleLogger.hex(resp)});

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

      if (dev != null) {
        await _ensureBonded(dev, reason: 'xác thực thành công, thiết lập bond');
      }

      final saltNonce = nonce15;
      final dash = find(Gatt.dashboardCharacteristic);
      final serialChar = find(Gatt.bikeSerial);
      int ctr(List<int> r) => r.length >= 4
          ? r[0] | (r[1] << 8) | (r[2] << 16) | (r[3] << 24)
          : -1;

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

               'salt': BleLogger.hex(salt), 'sk': BleLogger.hex(sk)});
          return live;
        } catch (_) {
          return false;
        }
      }

      var live = false;
      var livePw = '';
      Uint8List? liveKey;

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
            await SecureKeyManager.saveBikePassword(dev?.remoteId.str ?? '', pin);
            await prefs.remove(_kBikePassword);
          }
        } else if (live) {
          livePw = pin;
          liveKey = _sessionKeyOf(token, pin, saltNonce);
          await SecureKeyManager.saveBikePassword(dev?.remoteId.str ?? '', pin);
          await prefs.remove(_kBikePassword);
        }
      }

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
            await SecureKeyManager.saveBikePassword(dev?.remoteId.str ?? '', stored);
            await prefs.remove(_kBikePassword);
          }
        } else if (live) {
          livePw = stored;
          liveKey = _sessionKeyOf(token, stored, saltNonce);
          await SecureKeyManager.saveBikePassword(dev?.remoteId.str ?? '', stored);
          await prefs.remove(_kBikePassword);
        }
      }

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
            final ack = await appAuthChar.read();
            BleLogger.instance.event('auto_handshake_register_ack',
                {'hex': BleLogger.hex(ack)});
          } catch (_) {}
        } catch (e) {
          BleLogger.instance.event('auto_handshake_register_error',
              {'error': '$e'});
        }

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
              await SecureKeyManager.saveBikePassword(dev?.remoteId.str ?? '', newPw);
              await prefs.remove(_kBikePassword);
            }
          }
        }
      }

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
      BleLogger.instance.event('auto_handshake_success');
      BleLogger.instance.event('auto_handshake_success');
      return true;
    } catch (e) {
      BleLogger.instance.event('auto_handshake_failed', {'error': '$e'});
      return false;
    }
  }

  bool _isAuthError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('137') ||
        s.contains('insufficient') ||
        s.contains('gatt_auth') ||
        s.contains('auth_fail');
  }

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
    if (savedId != null) {
      await SecureKeyManager.deleteBikeCredentials(savedId);
    }

    await BleLogger.instance.close();
    unawaited(ForegroundService.stop());

    state = const BleState(
      phase: BlePhase.idle,
      message: 'Đã xóa thông tin xe',
      device: null,
      bikeName: null,
    );
  }

  void _watchConnection(BluetoothDevice device) {
    _connSub?.cancel();
    _connSub = FlutterBluePlus.events.onConnectionStateChanged.listen((e) async {
      if (e.device.remoteId != device.remoteId) return;
      if (e.connectionState == BluetoothConnectionState.disconnected) {
        BleLogger.instance.event('disconnected', {
          'device_id': device.remoteId.str,
          'manual': _manualDisconnect,
        });

        _connSub?.cancel();
        _connSub = null;

        _pollTimer?.cancel();
        _stopKeepalive();
        _notifySub?.cancel();
        _notifySub = null;
        _dashChar = null;
        _sessionKey = null;
        _writeCounter = 0;
        _decodeFailStreak = 0;

        if (_manualDisconnect) {

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

    if (_reconnectPending) {
      BleLogger.instance.event('reconnect_debounced', {});
      return;
    }
    _reconnectAttempts++;

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
      title: 'My Bike: ${state.bikeName ?? device.platformName}',
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
            title: 'My Bike: ${state.bikeName ?? device.platformName}',
            text: 'Đã kết nối Bluetooth — Sẵn sàng điều khiển',
          ));
          _failStreak = 0;
          _watchConnection(device);
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
