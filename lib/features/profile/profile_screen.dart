// Módulo 3: Perfil Biker & Garaje Virtual BSKMT
// Sincronizado en tiempo real con el ecosistema BSKMT.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';
import '../../core/services/bskmt_provider.dart';
import '../../ui/app_theme.dart';
import '../../ui/widgets.dart';
import '../scan/scan_screen.dart';
import 'widgets/arpha_sos_banner.dart';
import 'widgets/biker_card.dart';
import 'widgets/garage_motorcycle_card.dart';
import 'widgets/profile_menu_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleProvider);
    final bskmt = ref.watch(bskmtProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superior & Estado BLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PERFIL BIKER & GARAJE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.textDim,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen())),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ble.phase == BlePhase.connected
                            ? AppColors.tertiary.withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ble.phase == BlePhase.connected
                              ? AppColors.tertiary.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ble.phase == BlePhase.connected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_searching_rounded,
                            size: 15,
                            color: ble.phase == BlePhase.connected ? AppColors.tertiary : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ble.phase == BlePhase.connected ? 'Moto Conectada' : 'Buscar BLE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: ble.phase == BlePhase.connected ? AppColors.tertiary : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Carnet del piloto
              BikerCard(
                user: bskmt.user,
                fallbackName: ble.userName ?? 'Piloto BSKMT',
                isAuthenticated: bskmt.isAuthenticated,
              ),
              const SizedBox(height: 24),

              // Garaje Virtual
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MI GARAJE VIRTUAL BSKMT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textDim,
                    ),
                  ),
                  if (bskmt.isAuthenticated)
                    IconButton(
                      icon: const Icon(Icons.sync_rounded, size: 20, color: AppColors.primary),
                      tooltip: 'Sincronizar Garaje con servidor',
                      onPressed: () async {
                        await ref.read(bskmtProvider.notifier).refreshGarage();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Garaje BSKMT sincronizado con éxito'),
                              backgroundColor: AppColors.tertiary,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (bskmt.motorcycles.isNotEmpty)
                Column(
                  children: bskmt.motorcycles.map((moto) {
                    final isSelected = bskmt.activeMotorcycle?.id == moto.id;
                    return GarageMotorcycleCard(
                      moto: moto,
                      isSelected: isSelected,
                      onSelect: () => ref.read(bskmtProvider.notifier).selectMotorcycle(moto.id),
                    );
                  }).toList(),
                )
              else
                Panel(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 20,
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.garage_rounded, size: 36, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          bskmt.isAuthenticated
                              ? 'No tienes motos registradas en tu Garaje BSKMT.'
                              : 'Inicia sesión para sincronizar las motos de tu Garaje Virtual BSKMT.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDim),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Botón SOS ARPHA
              ArphaSosBanner(ref: ref),
              const SizedBox(height: 24),

              // Módulos del ecosistema
              Text(
                'MÓDULOS DE CONTROL Y TELEMETRÍA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textDim,
                ),
              ),
              const SizedBox(height: 10),

              ProfileMenuSection(
                isAuthenticated: bskmt.isAuthenticated,
                onLogout: () async {
                  await ref.read(bskmtProvider.notifier).logout();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sesión cerrada correctamente')),
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
