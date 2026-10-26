// Screen 4: User Profile — Hồ sơ Chủ Xe Máy Điện Dat Bike
// Thiết kế tham chiếu Geely "Edit your personalized information" tinh chỉnh cho Dat Bike:
// - Icon QR (quét mã ghép nối NFC / BLE xe máy) & Chat hỗ trợ Dat Care 24/7.
// - Avatar tròn đen chữ J (hoặc D).
// - Lời chào lớn Hello, Dat Bike User (font rộng), ID DB-QUANTUM-0187, nút Edit Profile ->.
// - Danh sách cài đặt thiết thực cho xe máy điện trên nền trắng:
//     1. Cài đặt xe & Chế độ lái (Regen Braking, Giới hạn tốc độ)
//     2. Bác Sĩ Pin & Chẩn đoán 24-Cell BMS
//     3. Cập nhật phần mềm xe qua mạng (OTA Firmware)
//     4. Thông tin ứng dụng (About)
//     5. Đăng xuất (Log Out)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';
import '../battery/battery_diagnostics_screen.dart';
import '../ota/ota_screen.dart';
import '../scan/scan_screen.dart';
import '../settings/vehicle_settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ══════════════════════════════════════════════════════════════
              // 1. THANH TRẠNG THÁI TIÊU ĐỀ & PHÍM TẮT TÌM XE BLE
              // ══════════════════════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TÀI KHOẢN & XE',
                    style: GoogleFonts.syne(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ScanScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bluetooth_searching_rounded, size: 16, color: Color(0xFF2563EB)),
                          const SizedBox(width: 6),
                          Text(
                            'Tìm Xe BLE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ══════════════════════════════════════════════════════════════
              // 2. AVATAR CHỦ XE DAT BIKE (CHỮ D)
              // ══════════════════════════════════════════════════════════════
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'D',
                  style: GoogleFonts.syne(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ══════════════════════════════════════════════════════════════
              // 3. LỜI CHÀO LỚN Hello, Dat Bike User (Font rộng)
              // ══════════════════════════════════════════════════════════════
              Text(
                'Hello,\nDat Bike User',
                style: GoogleFonts.syne(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.6,
                  color: const Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 10),

              // 4. MÃ ĐỊNH DANH XE MÁY ĐIỆN: DB-QUANTUM-0187
              Text(
                (ble.frameSerial != null && ble.frameSerial!.isNotEmpty) ? ble.frameSerial! : 'DB-QUANTUM-0187',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 14),

              // 5. NÚT Edit Profile ->
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hồ sơ chủ xe: Đồng bộ theo chìa khóa số BLE xe Dat Bike', style: GoogleFonts.plusJakartaSans()),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Edit Profile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
                        color: Color(0xFF0F172A),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ══════════════════════════════════════════════════════════════
              // 6. DANH SÁCH CÀI ĐẶT THIẾT YẾU CHO XE MÁY ĐIỆN TRÊN NỀN TRẮNG
              // ══════════════════════════════════════════════════════════════
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 0. Quản lý xe & Ghép đôi xe Dat Bike
                    _profileListItem(
                      icon: const Icon(Icons.bluetooth_searching_rounded, size: 22, color: Color(0xFF2563EB)),
                      title: 'Tìm & Ghép đôi xe mới (Bluetooth BLE)',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ScanScreen()),
                        );
                      },
                    ),

                    const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1, indent: 56, endIndent: 20),

                    // 1. Cài đặt xe & Phanh tái sinh
                    _profileListItem(
                      icon: const Icon(Icons.tune_rounded, size: 22, color: Color(0xFF0F172A)),
                      title: 'Cài đặt xe & Phanh động cơ (Settings)',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const VehicleSettingsScreen()),
                        );
                      },
                    ),

                    const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1, indent: 56, endIndent: 20),

                    // 2. Bác Sĩ Pin & Chẩn đoán 24-Cell BMS
                    _profileListItem(
                      icon: const Icon(Icons.medical_services_outlined, size: 22, color: Color(0xFF10B981)),
                      title: 'Bác Sĩ Pin & Chẩn đoán BMS',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BatteryDiagnosticsScreen()),
                        );
                      },
                    ),

                    const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1, indent: 56, endIndent: 20),

                    // 3. Cập nhật phần mềm xe qua mạng (OTA)
                    _profileListItem(
                      icon: const Icon(Icons.system_update_rounded, size: 22, color: Color(0xFF2563EB)),
                      title: 'Cập nhật phần mềm xe (OTA Firmware)',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OtaScreen()),
                        );
                      },
                    ),

                    const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1, indent: 56, endIndent: 20),

                    // 4. Thông tin ứng dụng (About)
                    _profileListItem(
                      icon: const Icon(Icons.info_outline_rounded, size: 22, color: Color(0xFF0F172A)),
                      title: 'Về Dat Bike Companion (About)',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Dat Bike Companion',
                          applicationVersion: 'v2.2.0 (Phase 1 Final)',
                          applicationIcon: const Icon(Icons.two_wheeler_rounded, size: 36, color: Color(0xFF2563EB)),
                          children: [
                            Text(
                              'Ứng dụng điều khiển xe máy điện Dat Bike (Quantum & Weaver series) tối ưu hóa kết nối BLE và quản lý thông số pin thông minh.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13),
                            ),
                          ],
                        );
                      },
                    ),

                    const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1, indent: 56, endIndent: 20),

                    // 5. Đăng xuất
                    _profileListItem(
                      icon: const Icon(Icons.logout_rounded, size: 22, color: Color(0xFFEF4444)),
                      title: 'Log Out',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text('Đăng Xuất', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
                            content: Text(
                              'Bạn có chắc chắn muốn ngắt kết nối tài khoản chìa khóa số khỏi xe?',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('HỦY', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã ngắt phiên kết nối chìa khóa xe')),
                                  );
                                },
                                child: Text('ĐĂNG XUẤT', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileListItem({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Center(child: icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
