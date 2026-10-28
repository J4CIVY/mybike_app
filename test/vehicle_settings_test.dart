import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybike_app/core/ble/ble_controller.dart';
import 'package:mybike_app/core/proto/bike_log.dart';
import 'package:mybike_app/features/settings/vehicle_settings_screen.dart';

class MockBleController extends BleController {
  final BleState initialState;
  MockBleController(this.initialState);

  @override
  BleState build() => initialState;

  @override
  Future<String?> readDeviceSerial() async => 'BSKMT-TEST-SERIAL-12345';
}

void main() {
  testWidgets('VehicleSettingsScreen renders on 320dp narrow screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockController = MockBleController(
      const BleState(
        phase: BlePhase.connected,
        bikeName: 'Quantum S',
        frameSerial: 'BSKMT-QUANTUM-2024-VN-009823487192',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bleProvider.overrideWith(() => mockController),
        ],
        child: const MaterialApp(
          home: VehicleSettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Configuración de la Moto'), findsOneWidget);
  });

  testWidgets('VehicleSettingsScreen handles long frame serial without breaking layout', (tester) async {
    tester.view.physicalSize = const Size(360 * 2.0, 780 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const superLongSerial = 'BSKMT-EXTRA-LONG-VIN-CODE-2024-QUANTUM-VN-99887766554433';
    final mockController = MockBleController(
      const BleState(
        phase: BlePhase.connected,
        bikeName: 'Quantum Pro',
        frameSerial: superLongSerial,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bleProvider.overrideWith(() => mockController),
        ],
        child: const MaterialApp(
          home: VehicleSettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('BSKMT-EXTRA-LONG-VIN'), findsWidgets);
  });

  testWidgets('VehicleSettingsScreen renders with textScaleFactor 1.4 without overflow', (tester) async {
    tester.view.physicalSize = const Size(360 * 2.0, 780 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockController = MockBleController(
      const BleState(
        phase: BlePhase.connected,
        bikeName: 'Weaver++',
        frameSerial: 'BSKMTW-2023-8888',
      ),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(1.4),
          size: Size(360, 780),
        ),
        child: ProviderScope(
          overrides: [
            bleProvider.overrideWith(() => mockController),
          ],
          child: const MaterialApp(
            home: VehicleSettingsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('VehicleSettingsScreen falls back to telemetry.frame when frameSerial is null', (tester) async {
    final mockController = MockBleController(
      BleState(
        phase: BlePhase.connected,
        bikeName: 'Quantum',
        frameSerial: null,
        lastTelemetry: BikeLogMsg()..frame = 'FRAME-TELEMETRY-9999',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bleProvider.overrideWith(() => mockController),
        ],
        child: const MaterialApp(
          home: VehicleSettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('FRAME-TELEMETRY-9999'), findsOneWidget);
    expect(find.text('SINCRONIZADO'), findsOneWidget);
  });

  testWidgets('VehicleSettingsScreen copy and read button interaction works cleanly', (tester) async {
    final mockController = MockBleController(
      const BleState(
        phase: BlePhase.connected,
        bikeName: 'Quantum S',
        frameSerial: 'BSKMTQ-SERIAL-2024-TEST',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bleProvider.overrideWith(() => mockController),
        ],
        child: const MaterialApp(
          home: VehicleSettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final copyButton = find.byIcon(Icons.copy_rounded);
    expect(copyButton, findsOneWidget);
    await tester.tap(copyButton);
    await tester.pump();
    expect(tester.takeException(), isNull);

    final refreshBtn = find.text('Releer');
    expect(refreshBtn, findsOneWidget);
    await tester.tap(refreshBtn);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
