// Shell chính — 3 Tabs Chuẩn Ngôn Ngữ Thiết Kế Xe Máy Điện Dat Bike:
// [ Xe ] · [ Năng Lượng ] · [ Chủ Xe ]
// Kèm thanh công cụ mô phỏng (Simulator Toolbar) để kiểm tra toàn bộ luồng sử dụng ngay trên Web.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';
import '../../core/proto/bike_log.dart';
import '../charging/charging_screen.dart';
import '../profile/profile_screen.dart';
import '../scan/scan_screen.dart';
import '../../ui/geely_icons.dart';
import 'my_bike_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;
  bool _showSimBar = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // 3 màn hình chính của xe máy điện
          IndexedStack(
            index: _tab.clamp(0, 2),
            children: const [
              MyBikeScreen(),
              ChargingScreen(),
              ProfileScreen(),
            ],
          ),

          // Thanh công cụ mô phỏng giả lập nhanh (Simulator Bar trên Web)
          if (_showSimBar)
            Positioned(
              left: 12,
              right: 12,
              bottom: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xE60F172A),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF60A5FA)),
                    const SizedBox(width: 8),
                    Text(
                      'SIMULATOR:',
                      style: GoogleFonts.syne(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _simButton('Đang Tắt', () => _setSimState(isOn: false, speed: 0.0, isLocked: false)),
                            _simButton('Đang Bật', () => _setSimState(isOn: true, speed: 0.0, isLocked: false)),
                            _simButton('Chạy 42km/h', () => _setSimState(isOn: true, speed: 42.0, isLocked: false)),
                            _simButton('Khóa An Toàn', () => _setSimState(isOn: false, speed: 0.0, isLocked: true)),
                            _simButton('Đang Sạc', () => _setSimState(isOn: false, speed: 0.0, isLocked: false, isCharging: true)),
                            _simButton('Tìm Xe BLE', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen()))),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showSimBar = false),
                      child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
          boxShadow: [
            BoxShadow(color: Color(0x060F172A), blurRadius: 12, offset: Offset(0, -4)),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          height: 64,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFFEFF6FF),
          indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
          ),
          destinations: [
            NavigationDestination(
              icon: GeelyIcons.bike(size: 22, color: const Color(0xFF64748B)),
              selectedIcon: GeelyIcons.bike(size: 22, color: const Color(0xFF2563EB)),
              label: 'Xe',
            ),
            NavigationDestination(
              icon: GeelyIcons.charging(size: 22, color: const Color(0xFF64748B)),
              selectedIcon: GeelyIcons.charging(size: 22, color: const Color(0xFF2563EB)),
              label: 'Năng Lượng',
            ),
            NavigationDestination(
              icon: GeelyIcons.profile(size: 22, color: const Color(0xFF64748B)),
              selectedIcon: GeelyIcons.profile(size: 22, color: const Color(0xFF2563EB)),
              label: 'Chủ Xe',
            ),
          ],
        ),
      ),
    );
  }

  Widget _simButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _setSimState({required bool isOn, required double speed, required bool isLocked, bool isCharging = false}) {
    final current = ref.read(bleProvider);
    final tele = current.lastTelemetry ?? BikeLogMsg();
    tele.speed = speed;
    tele.state = isOn ? BikeState.drive : BikeState.standBy;
    tele.percent = isCharging ? 85 : 68;

    ref.read(bleProvider.notifier).setMockState(
      isLocked: isLocked,
      telemetry: tele,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Giả lập: ${isOn ? "Xe Bật" : "Xe Tắt"} · Vận tốc ${speed.toInt()} km/h · ${isLocked ? "Đang Khóa" : "Mở Khóa"}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
