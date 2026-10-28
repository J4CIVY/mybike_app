import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../proto/bike_log.dart';
import '../models/trip_gps_point.dart';
import '../services/foreground_service.dart';
import '../services/trip_gps_tracker.dart';
import '../session/bike_session_crypto.dart';
import '../utils/kalman_filter.dart';
import 'ble_logger.dart';
import 'ble_permissions.dart';
import 'gatt.dart';

import 'ble_models.dart';
import 'ble_state.dart';

export '../models/trip_gps_point.dart';
export 'ble_models.dart';
export 'ble_state.dart';

part 'ble_controller_storage.dart';
part 'ble_controller_driver_profile.dart';
part 'ble_controller_queue.dart';
part 'ble_controller_settings_io.dart';
part 'ble_controller_settings_actions.dart';
part 'ble_controller_diagnostics.dart';
part 'ble_controller_lab.dart';
part 'ble_controller_proximity_actions.dart';
part 'ble_controller_proximity_settings.dart';
part 'ble_controller_connect.dart';
part 'ble_controller_establish.dart';
part 'ble_controller_reconnect.dart';
part 'ble_controller_telemetry_check.dart';
part 'ble_controller_telemetry_dashboard.dart';
part 'ble_controller_power.dart';
part 'ble_controller_features.dart';
part 'ble_controller_auth_session.dart';
part 'ble_controller_auth.dart';

class BleController extends Notifier<BleState> {
  static const _kLastBikeId = 'last_bike_id';
  static const _kBikePassword = 'bike_password';
  static const _kLastBikeName = 'last_bike_name';
  static const _maxReconnect = 5;
  static const _backoff = [2, 4, 8, 16, 30];

  static const _kAutoLockWalkAway = 'auto_lock_walk_away';
  static const _kWalkUpUnlock = 'walk_up_unlock';
  static const _kWalkUpAutoPowerOn = 'walk_up_auto_power_on';
  static const _kWalkUpRssiThreshold = 'walk_up_rssi_threshold';
  static const _kAutoLockRssiThreshold = 'auto_lock_rssi_threshold';
  static const _kAntiTheft5m = 'anti_theft_5m';
  static const _kAntiForgetAlert = 'anti_forget_alert';
  static const _kAutoLockDistance = 'auto_lock_distance';
  static const _kAntiForgetDistance = 'anti_forget_distance';
  static const _kFindBikePattern = 'find_bike_pattern';
  static const _kRecupLevel = 'recup_level';
  static const _kThrottleResponse = 'throttle_response';
  static const _kSpeedLimitMode = 'speed_limit_mode';
  static const _kEceMode = 'fw_ece_mode';
  static const _kGrabMode = 'fw_grab_mode';
  static const _kIdlingTurnOff = 'fw_idling_turn_off';
  static const _kDistanceMode = 'fw_distance_mode';
  static const _kChargingProfile = 'fw_charging_profile';
  static const _kTripHistory = 'trip_history_v1';
  static const _kUserName = 'user_profile_name';
  static const enableKeepalive = false;

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

  Timer? _keepaliveTimer;
  Uint8List? _lastAuthNonce15;
  String _activePassword = '';
  int _keepaliveCount = 0;
  bool _keepaliveBusy = false;
  bool _establishBusy = false;
  bool _restoreBusy = false;
  bool _isCommandBusy = false;
  DateTime? _lastCommandCompletedAt;
  bool _recoveryDisconnect = false;
  Uint8List? _sessionKey;
  int _writeCounter = 0;
  String? _lastRawStatusSig;

  final _telemetry = StreamController<BikeTelemetry>.broadcast();
  final _rssiKalman = KalmanFilter1D(processNoise: 0.008, measurementNoise: 4.0);
  double? _smoothedRssi;
  int _autoLockCounter = 0;
  int _theftCounter = 0;
  int _unlockNearCounter = 0;
  bool _autoSecureBusy = false;
  DateTime? _lastUserCommandAt;
  int _antiForgetCounter = 0;
  bool _walkUpTriggered = false;

  double? _tripStartOdo;
  DateTime? _tripStartTime;
  int? _tripStartPercent;
  double _tripMaxSpeed = 0.0;
  double _tripSpeedSum = 0.0;
  int _tripSpeedSamples = 0;

  Future<void>? _gattChain;
  bool _labModeActive = false;
  Timer? _findBikeTimeoutTimer;
  Timer? _findBikePeriodicTimer;
  bool _honkBusy = false;

  Stream<BikeTelemetry> get telemetry => _telemetry.stream;
  BluetoothDevice? get _device => state.device;
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  BleState build() {
    ref.onDispose(_teardown);
    _initSavedBike();
    return const BleState(phase: BlePhase.idle);
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
}

final bleProvider = NotifierProvider<BleController, BleState>(BleController.new);
