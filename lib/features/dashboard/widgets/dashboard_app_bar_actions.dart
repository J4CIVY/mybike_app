import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ble/ble_controller.dart';
import '../../../ui/app_theme.dart';

class DashboardAppBarActions extends ConsumerWidget {
  final VoidCallback onSyncOdo;

  const DashboardAppBarActions({
    super.key,
    required this.onSyncOdo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.cloud_upload_rounded),
          tooltip: 'Sincronizar Odómetro con Garaje Virtual BSKMT',
          onPressed: onSyncOdo,
        ),
        IconButton(
          icon: const Icon(Icons.battery_charging_full_rounded),
          tooltip: 'Diagnóstico Batería & OBD',
          onPressed: () => Navigator.of(context).pushNamed('/battery'),
        ),
        IconButton(
          icon: const Icon(Icons.access_time_rounded),
          tooltip: 'Sincronizar Hora Taplo',
          onPressed: () async {
            final res = await ref.read(bleProvider.notifier).syncTimeWithBike();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res),
                backgroundColor: res.contains('éxito') || res.contains('correctamente')
                    ? AppColors.tertiary
                    : AppColors.amber,
                duration: const Duration(seconds: 3),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Reiniciar Trip A',
          onPressed: () {
            ref.read(bleProvider.notifier).resetTrip();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Odómetro parcial Trip A reiniciado a cero'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Ajustes del Vehículo',
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
        IconButton(
          icon: const Icon(Icons.link_off_rounded),
          tooltip: 'Desconectar BLE',
          onPressed: () async {
            await ref.read(bleProvider.notifier).disconnect();
            if (!context.mounted) return;
            Navigator.of(context).pushReplacementNamed('/scan');
          },
        ),
      ],
    );
  }
}

