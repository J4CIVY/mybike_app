part of 'ble_controller.dart';

extension BleControllerQueue on BleController {
  Future<T> _enqueueGatt<T>(Future<T> Function() action) {
    final prev = _gattChain ?? Future.value();
    final completer = Completer<T>();
    _gattChain = prev.catchError((_) {}).then((_) async {
      try {
        completer.complete(await action());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  static int? expectedLengthForUuid(String uuid) {
    final clean = uuid.replaceAll('-', '').toLowerCase();
    if (clean.startsWith('6d2eb205')) return 41;
    if (clean.startsWith('018e6a6f')) return 108;
    if (clean.startsWith('84c7be0b')) return 207;
    if (clean.startsWith('2c73e84e')) return 16;
    if (clean.startsWith('35a9b4f6')) return 12;
    if (clean.startsWith('4cb05df8')) return 12;
    if (clean.startsWith('5d681587')) return 2;
    if (clean.startsWith('c75ebe03')) return 2;
    if (clean.startsWith('0a19a49a') ||
        clean.startsWith('3b56ac38') ||
        clean.startsWith('a1d8e7c4') ||
        clean.startsWith('69c79762') ||
        clean.startsWith('b0ca953d') ||
        clean.startsWith('8a2b0d10') ||
        clean.startsWith('91e84eb0')) {
      return 1;
    }
    return null;
  }

  BluetoothCharacteristic? _findCharacteristic(String uuid) {
    final clean = uuid.toLowerCase().replaceAll('-', '');
    for (final c in state.characteristics) {
      if (c.uuid.str128.toLowerCase().replaceAll('-', '') == clean) return c;
    }
    return null;
  }

  Future<void> _throttleCommand() async {
    if (_lastCommandCompletedAt != null) {
      final elapsed = DateTime.now().difference(_lastCommandCompletedAt!);
      const minInterval = Duration(milliseconds: 300);
      if (elapsed < minInterval) {
        final waitMs = minInterval.inMilliseconds - elapsed.inMilliseconds;
        BleLogger.instance.event('cmd_throttle_wait', {'wait_ms': waitMs});
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    }
  }

  Future<void> _waitWhileCommandBusy({int maxWaitMs = 2500}) async {
    var waited = 0;
    while (_isCommandBusy && waited < maxWaitMs) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited += 100;
    }
  }
}

