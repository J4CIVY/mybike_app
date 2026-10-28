import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mybike_app/features/firmware_lab/firmware_lab_screen.dart';
import 'package:mybike_app/features/firmware_lab/lab_catalog.dart';

void main() {
  testWidgets('FirmwareLabScreen render catalog + custom char card',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 30000));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: FirmwareLabScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('🧪 LABORATORIO DE FIRMWARE BSKMT'), findsOneWidget);
    expect(find.text('CARACTERÍSTICA PERSONALIZADA (Fuera de catálogo)'), findsOneWidget);
    for (final t in labCatalog) {
      expect(find.text(t.name), findsOneWidget,
          reason: 'Falta tarjeta para ${t.id}');
    }
  });
}
