import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybike_app/core/ble/ble_controller.dart';
import 'package:mybike_app/features/settings/vehicle_settings_screen.dart';

class TestBleController extends BleController {
  final BleState initialState;
  TestBleController(this.initialState);

  @override
  BleState build() => initialState;

  @override
  Future<void> refreshFwSettings() async {}
}

void main() {
  group('Lógica Límite de Velocidad Seguro 60 km/h', () {
    test('setSafeSpeedLimit60(true) establece speedLimitMode y eceMode en 1', () async {
      final controller = TestBleController(const BleState(phase: BlePhase.idle));
      final container = ProviderContainer(
        overrides: [bleProvider.overrideWith(() => controller)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(bleProvider.notifier);
      final msg = await notifier.setSafeSpeedLimit60(true);

      final state = container.read(bleProvider);
      expect(state.speedLimitMode, 1);
      expect(state.eceMode, 1);
      expect(state.fwSpeedLimitRaw, 1);
      expect(msg, isNotEmpty);
    });

    test('setSafeSpeedLimit60(false) desactiva ambos modos', () async {
      final controller = TestBleController(
        const BleState(phase: BlePhase.idle, speedLimitMode: 1, eceMode: 1, fwSpeedLimitRaw: 1),
      );
      final container = ProviderContainer(
        overrides: [bleProvider.overrideWith(() => controller)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(bleProvider.notifier);
      final msg = await notifier.setSafeSpeedLimit60(false);
      final state = container.read(bleProvider);
      expect(state.speedLimitMode, 0);
      expect(state.eceMode, 0);
      expect(state.fwSpeedLimitRaw, 0);
      expect(msg, contains('VESC'));
    });
  });

  group('UI Límite de Velocidad 60 km/h', () {
    testWidgets('VehicleSettingsScreen muestra sección de velocidad', (tester) async {
      tester.view.physicalSize = const Size(360 * 2.0, 1600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = TestBleController(
        const BleState(
          phase: BlePhase.connected,
          bikeName: 'BSKMT Quantum',
          speedLimitMode: 1,
          eceMode: 1,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [bleProvider.overrideWith(() => controller)],
          child: const MaterialApp(home: VehicleSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final titleFinder = find.text('SEGURIDAD Y CONTROL DE MANEJO');
      await tester.scrollUntilVisible(titleFinder, 300, scrollable: find.byType(Scrollable).first);
      expect(titleFinder, findsOneWidget);
    });
  });
}

