import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../proto/bike_log.dart';
import 'ble_models.dart';

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
  final BatteryLogMsg? lastBattery;
  final bool isFindingBike;
  final TripData trip;
  final List<TripRecord> tripHistory;
  final String? userName;
  final bool autoLockWalkAway;
  final bool walkUpUnlock;
  final bool walkUpAutoPowerOn;
  final double? walkUpRssiThreshold;
  final double? autoLockRssiThreshold;
  final bool antiTheft5m;
  final bool antiForgetAlert;
  final int autoLockDistance;
  final int antiForgetDistance;
  final int? rssi;
  final int? filteredRssi;
  final DateTime? lastTimeSynced;
  final int findBikePattern;
  final int recupLevel;
  final int throttleResponse;
  final int speedLimitMode;
  final String? frameSerial;
  final int eceMode;
  final int grabMode;
  final bool idlingTurnOff;
  final int distanceMode;
  final int chargingProfile;
  final bool isLocked;
  final String? bikeModelCode;
  final String? boardManifest;
  final double? vescCurrent;
  final double? vescVoltage;
  final double? vescDutyCycle;
  final int? fwSpeedLimitRaw;
  final int? distanceRawU16;
  final bool vescProgActive;

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
    this.tripHistory = const [],
    this.userName,
    this.autoLockWalkAway = false,
    this.walkUpUnlock = false,
    this.walkUpAutoPowerOn = false,
    this.walkUpRssiThreshold,
    this.autoLockRssiThreshold,
    this.antiTheft5m = false,
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
    this.eceMode = 0,
    this.grabMode = 0,
    this.idlingTurnOff = false,
    this.distanceMode = 0,
    this.chargingProfile = 0,
    this.isLocked = false,
    this.frameSerial,
    this.bikeModelCode,
    this.boardManifest,
    this.vescCurrent,
    this.vescVoltage,
    this.vescDutyCycle,
    this.fwSpeedLimitRaw,
    this.distanceRawU16,
    this.vescProgActive = false,
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
    List<TripRecord>? tripHistory,
    String? userName,
    bool? autoLockWalkAway,
    bool? walkUpUnlock,
    bool? walkUpAutoPowerOn,
    double? walkUpRssiThreshold,
    double? autoLockRssiThreshold,
    bool? antiTheft5m,
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
    int? eceMode,
    int? grabMode,
    bool? idlingTurnOff,
    int? distanceMode,
    int? chargingProfile,
    bool? isLocked,
    String? frameSerial,
    String? bikeModelCode,
    String? boardManifest,
    double? vescCurrent,
    double? vescVoltage,
    double? vescDutyCycle,
    int? fwSpeedLimitRaw,
    int? distanceRawU16,
    bool? vescProgActive,
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
        tripHistory: tripHistory ?? this.tripHistory,
        userName: userName ?? this.userName,
        autoLockWalkAway: autoLockWalkAway ?? this.autoLockWalkAway,
        walkUpUnlock: walkUpUnlock ?? this.walkUpUnlock,
        walkUpAutoPowerOn: walkUpAutoPowerOn ?? this.walkUpAutoPowerOn,
        walkUpRssiThreshold: walkUpRssiThreshold ?? this.walkUpRssiThreshold,
        autoLockRssiThreshold: autoLockRssiThreshold ?? this.autoLockRssiThreshold,
        antiTheft5m: antiTheft5m ?? this.antiTheft5m,
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
        eceMode: eceMode ?? this.eceMode,
        grabMode: grabMode ?? this.grabMode,
        idlingTurnOff: idlingTurnOff ?? this.idlingTurnOff,
        distanceMode: distanceMode ?? this.distanceMode,
        chargingProfile: chargingProfile ?? this.chargingProfile,
        isLocked: isLocked ?? this.isLocked,
        frameSerial: frameSerial ?? this.frameSerial,
        bikeModelCode: bikeModelCode ?? this.bikeModelCode,
        boardManifest: boardManifest ?? this.boardManifest,
        vescCurrent: vescCurrent ?? this.vescCurrent,
        vescVoltage: vescVoltage ?? this.vescVoltage,
        vescDutyCycle: vescDutyCycle ?? this.vescDutyCycle,
        fwSpeedLimitRaw: fwSpeedLimitRaw ?? this.fwSpeedLimitRaw,
        distanceRawU16: distanceRawU16 ?? this.distanceRawU16,
        vescProgActive: vescProgActive ?? this.vescProgActive,
      );
}

