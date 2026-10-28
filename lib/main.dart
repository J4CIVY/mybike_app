import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ble/ble_logger.dart';
import 'features/auth/login_screen.dart';
import 'features/battery/battery_diagnostics_screen.dart';
import 'features/charging/charging_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/firmware_lab/firmware_lab_screen.dart';
import 'features/home/home_shell.dart';
import 'features/logs/logs_screen.dart';
import 'features/ota/ota_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/scan/connecting_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/settings/vehicle_settings_screen.dart';
import 'ui/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Captura centralizada de excepciones no controladas hacia logs de diagnóstico
  FlutterError.onError = (details) {
    BleLogger.logAppError('flutter_error', details.exception, details.stack);
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    BleLogger.logAppError('uncaught_error', error, stackTrace);
    return true; // Previene pantalla en blanco
  };

  runApp(const ProviderScope(child: MyBikeApp()));
}

class MyBikeApp extends StatelessWidget {
  const MyBikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BSKMT Cockpit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeShell(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeShell(),
        '/cockpit': (_) => const DashboardScreen(),
        '/garage': (_) => const ProfileScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/scan': (_) => const ScanScreen(),
        '/connecting': (_) => const ConnectingScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/battery': (_) => const BatteryDiagnosticsScreen(),
        '/charging': (_) => const ChargingScreen(),
        '/settings': (_) => const VehicleSettingsScreen(),
        '/logs': (_) => const LogsScreen(),
        '/ota': (_) => const OtaScreen(),
        '/lab': (_) => const FirmwareLabScreen(),
      },
    );
  }
}
