import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/scan/scan_screen.dart';
import 'features/scan/connecting_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/home/my_bike_screen.dart';
import 'ui/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyBikeApp()));
}

class MyBikeApp extends StatelessWidget {
  const MyBikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Bike',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const MyBikeScreen(),
        '/scan': (_) => const ScanScreen(),
        '/connecting': (_) => const ConnectingScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}
