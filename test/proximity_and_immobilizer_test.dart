import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mybike_app/core/ble/ble_controller.dart';
import 'package:mybike_app/core/proto/bike_log.dart';
import 'package:mybike_app/features/home/my_bike_screen.dart';

class TestBleController extends BleController {
  final BleState initialState;
  TestBleController(this.initialState);

  @override
  BleState build() => initialState;

  @override
  Future<void> refreshFwSettings() async {}
}

void main() {
  group('Proximidad y Automatización (§4.6)', () {
    test('walkUpUnlock y antiTheft5m actualizan el estado', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = TestBleController(const BleState(phase: BlePhase.idle));
      final container = ProviderContainer(
        overrides: [bleProvider.overrideWith(() => controller)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(bleProvider.notifier);

      expect(container.read(bleProvider).walkUpUnlock, isFalse);
      expect(container.read(bleProvider).antiTheft5m, isFalse);
      await notifier.setWalkUpUnlock(true);
      await notifier.setAntiTheft5m(true);
      expect(container.read(bleProvider).walkUpUnlock, isTrue);
      expect(container.read(bleProvider).antiTheft5m, isTrue);
      expect(container.read(bleProvider).autoLockWalkAway, isFalse);
    });

    test('walkUpAutoPowerOn y rangos de RSSI actualizan estado', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = TestBleController(const BleState(phase: BlePhase.idle));
      final container = ProviderContainer(
        overrides: [bleProvider.overrideWith(() => controller)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(bleProvider.notifier);

      expect(container.read(bleProvider).walkUpAutoPowerOn, isFalse);
      expect(container.read(bleProvider).walkUpRssiThreshold, isNull);
      expect(container.read(bleProvider).autoLockRssiThreshold, isNull);

      await notifier.setWalkUpAutoPowerOn(true);
      expect(container.read(bleProvider).walkUpAutoPowerOn, isTrue);

      await notifier.setWalkUpRssiThreshold(-50.0);
      expect(container.read(bleProvider).walkUpRssiThreshold, -50.0);

      await notifier.setAutoLockRssiThreshold(-88.5);
      expect(container.read(bleProvider).autoLockRssiThreshold, -88.5);
      expect(container.read(bleProvider).autoLockDistance, 2);
    });
  });

  group('Lógica de Inmovilizador', () {
    test('setImmobilizer(true) bloquea cuando velocidad <= 0.5 km/h', () async {
      final controller = TestBleController(
        const BleState(phase: BlePhase.idle, isLocked: false),
      );
      final container = ProviderContainer(
        overrides: [bleProvider.overrideWith(() => controller)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(bleProvider.notifier);
      await notifier.setImmobilizer(true);
      expect(container.read(bleProvider).isLocked, isTrue);

      await notifier.setImmobilizer(false);
      expect(container.read(bleProvider).isLocked, isFalse);
    });

    test('setImmobilizer(true) es rechazado si la moto se mueve (> 0.5 km/h)', () async {
      final movingTelemetry = BikeLogMsg()..speed = 25.5;
      final controller = TestBleController(
        BleState(
          phase: BlePhase.connected,
          lastTelemetry: movingTelemetry,
          isLocked: false,
        ),
      );
      final container = ProviderContainer(
        overrides: [bleProvider.overrideWith(() => controller)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(bleProvider.notifier);
      final msg = await notifier.setImmobilizer(true);
      expect(msg, contains('No se puede'));
      expect(container.read(bleProvider).isLocked, isFalse);
    });
  });

  group('MyBikeScreen UI Inmovilizador', () {
    testWidgets('Muestra controles de seguridad cuando está conectado', (tester) async {
      final controller = TestBleController(
        const BleState(
          phase: BlePhase.connected,
          bikeName: 'BSKMT Quantum S',
          isLocked: false,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [bleProvider.overrideWith(() => controller)],
          child: const MaterialApp(home: MyBikeScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      expect(find.text('Bloqueo Antirrobo'), findsOneWidget);
      expect(find.text('Alarma localizadora'), findsOneWidget);
      expect(find.text('Sincronizar Hora'), findsOneWidget);
    });

    testWidgets('Muestra distintivo de bloqueo y botón desbloquear', (tester) async {
      final controller = TestBleController(
        const BleState(
          phase: BlePhase.connected,
          bikeName: 'BSKMT Quantum S',
          isLocked: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [bleProvider.overrideWith(() => controller)],
          child: const MaterialApp(home: MyBikeScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Seguro activo (Bloqueada)'), findsWidgets);
      expect(find.text('Desbloquear'), findsOneWidget);
    });
  });
}

