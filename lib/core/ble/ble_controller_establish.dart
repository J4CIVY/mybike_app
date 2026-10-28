part of 'ble_controller.dart';

extension BleControllerEstablish on BleController {
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
            await _ensureBonded(device, reason: 'fw char requiere autenticacion');
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

    await authenticateSession(targetDevice: device, chars: allChars);

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
    if (state.isAuthorized) {
      unawaited(refreshFwSettings());
      unawaited(fetchVehicleDiagnostics());
    }
    return state.isAuthorized;
  }

  Future<void> _pollDashboard() async {
    final c = _dashChar;
    if (c == null || state.phase != BlePhase.connected) return;
    if (BleController.enableKeepalive &&
        state.isAuthorized &&
        _keepaliveTimer == null &&
        _activePassword.isNotEmpty &&
        _lastAuthNonce15 != null) {
      BleLogger.instance.event('keepalive_watchdog_restart', {});
      _startKeepalive();
    }
    try {
      final raw = await _enqueueGatt(() => c.read());
      _handleDashboardPayload(raw);
    } catch (e) {
      BleLogger.instance.event('poll_error', {'error': '$e'});
    }

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
        _smoothedRssi = null;
        _rssiKalman.reset();
        _autoLockCounter = 0;
        _antiForgetCounter = 0;
        _walkUpTriggered = false;
        _batteryChar = null;
        _batteryPollCounter = 0;
        unawaited(_archiveCurrentTripIfMeaningful());

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
              ? '⚠️ ADVERTENCIA: La moto sigue ENCENDIDA tras perder conexión.'
              : null,
        );

        _scheduleReconnect(device);
      }
    });
  }
}

