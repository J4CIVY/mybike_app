// Screen 1: Home / Remote Control — Chuyên biệt hóa cho Xe Máy Điện Dat Bike
// Thiết kế tham chiếu Geely EV nhưng tinh chỉnh 100% chuẩn tính năng xe máy điện:
// - Header tên xe (Dat Bike Quantum S1 ⇄) + badge Bluetooth Connected.
// - Cụm thông số: Quãng đường xe máy điện (270 km) font rộng.
// - 2 thanh progress nhỏ:
//     + Dung lượng Pin: 68% (185 km - xanh lá)
//     + Quãng đường khả dụng tối đa: 270 km (xanh dương)
// - Giữa màn hình: Ảnh xe máy điện Dat Bike Quantum (bike_hero.jpg).
// - Card 4 nút điều khiển nhanh xe máy điện:
//     1. Khóa cổ & Chống trộm (Lock)
//     2. Bật / Tắt nguồn xe (Power - Keyless)
//     3. Tìm xe trong bãi (Find Bike - Còi & Đèn)
//     4. Mở khóa điện cốp xe 41L (Trunk Release)
// - Card Parked Bike: Địa chỉ bãi đỗ thực tế + 2 nút tròn Đèn/Còi + Mini map định vị xe máy.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';
import '../battery/battery_diagnostics_screen.dart';
import '../scan/scan_screen.dart';
import '../settings/vehicle_settings_screen.dart';
import '../../ui/geely_icons.dart';

class MyBikeScreen extends ConsumerStatefulWidget {
  const MyBikeScreen({super.key});

  @override
  ConsumerState<MyBikeScreen> createState() => _MyBikeScreenState();
}

class _MyBikeScreenState extends ConsumerState<MyBikeScreen> {
  late final AppLifecycleListener _lifecycleListener;

  // Trạng thái các chức năng điều khiển ẩn (Remote Controls)
  bool _hazardActive = false;
  bool _autoLockWalkAway = true;
  bool _walkUpUnlock = true;
  bool _antiTheftMotion = true;
  bool _speedLimiter60 = false;
  int _selectedRideMode = 1; // 0: ECO, 1: NORMAL, 2: SPORT
  int _regenBrakingLevel = 1; // 0: Nhẹ, 1: Tiêu Chuẩn, 2: Mạnh

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: _onAppResume,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndRestore();
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _onAppResume() {
    _checkAndRestore();
  }

  Future<void> _checkAndRestore() async {
    final ble = ref.read(bleProvider);
    if (ble.phase == BlePhase.connected ||
        ble.phase == BlePhase.connecting ||
        ble.phase == BlePhase.reconnecting ||
        ble.phase == BlePhase.disconnected) {
      return;
    }
    final last = await ref.read(bleProvider.notifier).lastBikeId();
    if (last != null && mounted) {
      await ref.read(bleProvider.notifier).tryRestoreLastBike();
    }
  }

  void _heroSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1800),
      ));
  }

  Future<void> _quickLockToggle() async {
    final ble = ref.read(bleProvider);
    final notifier = ref.read(bleProvider.notifier);
    if (ble.isLocked) {
      final msg = await notifier.unlockBike();
      _heroSnack(msg);
      return;
    }

    final spd = ble.lastTelemetry?.speed ?? 0.0;
    if (spd > 0.5) {
      _heroSnack('⚠️ Cảnh báo an toàn: Xe đang di chuyển (${spd.toStringAsFixed(0)} km/h), không thể khóa!');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Khóa Cổ & Chống Trộm',
          style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        content: Text(
          'Hệ thống sẽ khóa chốt cổ điện tử và kích hoạt cảm biến cảnh báo chống dắt xe.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('HỦY', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('KHÓA NGAY', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _heroSnack(await notifier.lockBike());
  }

  Future<void> _quickPowerToggle() async {
    final ble = ref.read(bleProvider);
    final notifier = ref.read(bleProvider.notifier);
    final on = ble.lastTelemetry?.isBikeOn == true;
    final spd = ble.lastTelemetry?.speed ?? 0.0;

    if (on && spd > 0.5) {
      _heroSnack('⚠️ Cảnh báo an toàn: Không thể tắt xe khi đang chạy (${spd.toStringAsFixed(1)} km/h)!');
      return;
    }

    try {
      if (on) {
        await notifier.turnOffBike();
        _heroSnack('Đã gửi lệnh TẮT nguồn xe máy điện');
      } else {
        await notifier.turnOnBike();
        _heroSnack('Đã gửi lệnh BẬT nguồn xe máy điện (Ready to drive)');
      }
    } catch (e) {
      _heroSnack('$e');
    }
  }

  Future<void> _quickFindBike() async {
    final msg = await ref.read(bleProvider.notifier).findBike();
    if (mounted) _heroSnack(msg);
  }

  Future<void> _quickSyncTime() async {
    final msg = await ref.read(bleProvider.notifier).syncTimeWithBike();
    if (mounted) _heroSnack(msg);
  }

  void _openRemoteControlsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final ble = ref.watch(bleProvider);
          final isBikeOn = ble.lastTelemetry?.isBikeOn == true;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thanh kéo định vị (Drag Handle)
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tiêu đề & Icon thanh mảnh
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chức Năng Điều Khiển Ẩn',
                              style: GoogleFonts.syne(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Thiết lập an toàn & điều khiển chuyên sâu Dat Bike',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ══════════════════════════════════════════════════════════
                  // 1. THAO TÁC NHANH TỪ XA (4 NÚT TRÒN ĐỒNG NHẤT BÊN NGOÀI)
                  // ══════════════════════════════════════════════════════════
                  Text(
                    'THAO TÁC NHANH TỪ XA',
                    style: GoogleFonts.syne(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Nút 1: Tìm Xe (Còi)
                      _sheetRoundButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF2563EB), size: 24),
                        label: 'Tìm Xe',
                        onTap: () async {
                          await _quickFindBike();
                        },
                      ),

                      // Nút 2: Xi-nhan Hazard
                      _sheetRoundButton(
                        icon: Icon(
                          Icons.warning_amber_rounded,
                          color: _hazardActive ? const Color(0xFFD97706) : const Color(0xFF64748B),
                          size: 24,
                        ),
                        label: 'Đèn Hazard',
                        active: _hazardActive,
                        activeColor: const Color(0xFFFEF3C7),
                        activeBorderColor: const Color(0xFFFDE68A),
                        onTap: () {
                          setSheetState(() => _hazardActive = !_hazardActive);
                          setState(() {});
                          _heroSnack(_hazardActive ? 'Đã bật nháy 4 đèn cảnh báo Hazard' : 'Đã tắt đèn Hazard');
                        },
                      ),

                      // Nút 3: Đồng bộ giờ Taplo (RTC)
                      _sheetRoundButton(
                        icon: const Icon(Icons.access_time_rounded, color: Color(0xFF0F172A), size: 24),
                        label: 'Đồng bộ giờ',
                        onTap: _quickSyncTime,
                      ),

                      // Nút 4: Khởi Động / Tắt Nguồn
                      _sheetRoundButton(
                        icon: Icon(
                          Icons.power_settings_new_rounded,
                          color: isBikeOn ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          size: 24,
                        ),
                        label: isBikeOn ? 'Tắt Máy' : 'Bật Xe',
                        active: isBikeOn,
                        activeColor: const Color(0xFFF0FDF4),
                        activeBorderColor: const Color(0xFFBBF7D0),
                        onTap: () async {
                          await _quickPowerToggle();
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ══════════════════════════════════════════════════════════
                  // 2. CHỐNG TRỘM & AN TOÀN THÔNG MINH
                  // ══════════════════════════════════════════════════════════
                  Text(
                    'CHỐNG TRỘM & AN TOÀN THÔNG MINH',
                    style: GoogleFonts.syne(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x040F172A),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _sheetToggleRow(
                          icon: Icons.lock_clock_rounded,
                          iconColor: const Color(0xFF2563EB),
                          iconBg: const Color(0xFFEFF6FF),
                          title: 'Tự Động Khóa Khi Đi Xa (>5m)',
                          subtitle: 'Tự khóa cổ & ngắt nguồn khi rời khỏi bán kính xe',
                          value: _autoLockWalkAway,
                          onChanged: (v) {
                            setSheetState(() => _autoLockWalkAway = v);
                            setState(() {});
                            _heroSnack(v ? 'Đã bật Auto-Lock khi rời xe' : 'Đã tắt Auto-Lock');
                          },
                        ),
                        const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1, indent: 56, endIndent: 16),
                        _sheetToggleRow(
                          icon: Icons.key_rounded,
                          iconColor: const Color(0xFF10B981),
                          iconBg: const Color(0xFFF0FDF4),
                          title: 'Mở Khóa Không Chìa (Walk-Up)',
                          subtitle: 'Tự nhận diện chủ xe và sẵn sàng nổ máy khi lại gần',
                          value: _walkUpUnlock,
                          onChanged: (v) {
                            setSheetState(() => _walkUpUnlock = v);
                            setState(() {});
                            _heroSnack(v ? 'Đã bật mở khóa không chìa Walk-Up' : 'Đã tắt mở khóa Walk-Up');
                          },
                        ),
                        const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1, indent: 56, endIndent: 16),
                        _sheetToggleRow(
                          icon: Icons.security_rounded,
                          iconColor: const Color(0xFFEF4444),
                          iconBg: const Color(0xFFFEF2F2),
                          title: 'Báo Động Rung Lắc & Chống Dắt',
                          subtitle: 'Khóa cứng bánh xe và hú còi khi có người lạ dịch chuyển',
                          value: _antiTheftMotion,
                          onChanged: (v) {
                            setSheetState(() => _antiTheftMotion = v);
                            setState(() {});
                            _heroSnack(v ? 'Đã bật cảm biến chống dắt xe' : 'Đã tắt cảnh báo chống dắt');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ══════════════════════════════════════════════════════════
                  // 3. HIỆU NĂNG LÁI & PHANH TÁI SINH
                  // ══════════════════════════════════════════════════════════
                  Text(
                    'CẢM GIÁC LÁI & PHANH TÁI SINH',
                    style: GoogleFonts.syne(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x040F172A),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chế độ lái
                        Text(
                          'Chế độ lái xe (Ride Mode)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _sheetSegmentPill(
                              label: 'ECO',
                              sub: 'Tiết kiệm pin',
                              selected: _selectedRideMode == 0,
                              onTap: () {
                                setSheetState(() => _selectedRideMode = 0);
                                setState(() {});
                                _heroSnack('Chế độ lái: ECO (Tiết kiệm pin)');
                              },
                            ),
                            const SizedBox(width: 8),
                            _sheetSegmentPill(
                              label: 'NORMAL',
                              sub: 'Cân bằng',
                              selected: _selectedRideMode == 1,
                              onTap: () {
                                setSheetState(() => _selectedRideMode = 1);
                                setState(() {});
                                _heroSnack('Chế độ lái: NORMAL (Tiêu chuẩn)');
                              },
                            ),
                            const SizedBox(width: 8),
                            _sheetSegmentPill(
                              label: 'SPORT',
                              sub: 'Tăng tốc',
                              selected: _selectedRideMode == 2,
                              onTap: () {
                                setSheetState(() => _selectedRideMode = 2);
                                setState(() {});
                                _heroSnack('Chế độ lái: SPORT (Thể thao)');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1),
                        const SizedBox(height: 14),

                        // Phanh tái sinh
                        Text(
                          'Mức phanh tái sinh động cơ (Regen)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Thu hồi động năng khi nhả tay ga nạp lại vào pin',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _sheetSegmentPill(
                              label: 'Nhẹ',
                              sub: 'Trôi xe êm',
                              selected: _regenBrakingLevel == 0,
                              onTap: () {
                                setSheetState(() => _regenBrakingLevel = 0);
                                setState(() {});
                                _heroSnack('Phanh tái sinh: Nhẹ');
                              },
                            ),
                            const SizedBox(width: 8),
                            _sheetSegmentPill(
                              label: 'Chuẩn',
                              sub: 'Hồi 15% pin',
                              selected: _regenBrakingLevel == 1,
                              onTap: () {
                                setSheetState(() => _regenBrakingLevel = 1);
                                setState(() {});
                                _heroSnack('Phanh tái sinh: Tiêu chuẩn');
                              },
                            ),
                            const SizedBox(width: 8),
                            _sheetSegmentPill(
                              label: 'Mạnh',
                              sub: 'Hồi 25% pin',
                              selected: _regenBrakingLevel == 2,
                              onTap: () {
                                setSheetState(() => _regenBrakingLevel = 2);
                                setState(() {});
                                _heroSnack('Phanh tái sinh: Mạnh (Một bàn đạp)');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1),
                        const SizedBox(height: 10),

                        // Giới hạn tốc độ ECE 60
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Giới Hạn Tốc Độ Đô Thị 60 km/h (ECE)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Đảm bảo an toàn và tối ưu thêm 15% quãng đường',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _speedLimiter60,
                              activeTrackColor: const Color(0xFF2563EB),
                              onChanged: (v) {
                                setSheetState(() => _speedLimiter60 = v);
                                setState(() {});
                                _heroSnack(v ? 'Đã bật giới hạn tốc độ 60 km/h' : 'Đã tắt giới hạn tốc độ');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nút Bác Sĩ Pin & Chẩn đoán 24-Cell BMS
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BatteryDiagnosticsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.medical_services_outlined, size: 18, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text(
                            'BÁC SĨ PIN & CHẨN ĐOÁN 24-CELL BMS',
                            style: GoogleFonts.syne(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF10B981)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nút mở Settings toàn diện
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const VehicleSettingsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.settings_outlined, size: 18, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          Text(
                            'MỞ TRANG CÀI ĐẶT XE TOÀN DIỆN (FULL SETTINGS)',
                            style: GoogleFonts.syne(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sheetRoundButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    Color? activeColor,
    Color? activeBorderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? (activeColor ?? const Color(0xFFEFF6FF)) : const Color(0xFFF8FAFC),
              border: Border.all(
                color: active ? (activeBorderColor ?? const Color(0xFFBFDBFE)) : const Color(0xFFF1F5F9),
                width: 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: (activeBorderColor ?? const Color(0xFF2563EB)).withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetToggleRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFF2563EB),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _sheetSegmentPill({
    required String label,
    required String sub,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.syne(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: selected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBikeSwitcherSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xe Của Bạn',
                      style: GoogleFonts.syne(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chuyển đổi xe đang điều khiển hoặc thêm xe mới',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Xe 1: Dat Bike Quantum S1 (Active)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Dat Bike Quantum S1',
                              style: GoogleFonts.syne(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ĐANG CHỌN',
                                style: GoogleFonts.syne(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'RL9C4NGSSSCC00187 · 68% Pin (184 km)',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 22),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Xe 2: Dat Bike Weaver++
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _heroSnack('Chuyển sang xe Dat Bike Weaver++');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF64748B), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dat Bike Weaver++',
                            style: GoogleFonts.syne(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'RL9C3NGSDB000412 · Ngoại tuyến (Cách 1.5 km)',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Nút Tìm & Ghép Đôi Xe BLE (Thanh mảnh & tinh tế)
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bluetooth_searching_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      'TÌM & GHÉP ĐÔI XE (BLUETOOTH BLE)',
                      style: GoogleFonts.syne(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB), letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);
    final connected = ble.phase == BlePhase.connected;
    final telemetry = ble.lastTelemetry;
    final percent = telemetry?.percent ?? 68;
    final kmLeft = ((percent / 100.0) * 270).round();
    final speed = telemetry?.speed ?? 0.0;
    final isBikeOn = telemetry?.isBikeOn == true;
    final isLocked = ble.isLocked;

    // Trạng thái vận hành thực tế của xe máy điện
    final statusText = !connected
        ? 'Chưa kết nối (Disconnected)'
        : (isLocked
            ? 'Đang khóa an toàn (Locked)'
            : (speed > 0.5
                ? 'Đang chạy (${speed.toStringAsFixed(0)} km/h)'
                : (isBikeOn ? 'Sẵn sàng chạy (Ready)' : 'Đang đỗ (Parking)')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ══════════════════════════════════════════════════════════════
              // 1. HEADER: Tên xe máy điện + Badge Bluetooth Connected
              // ══════════════════════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => _openBikeSwitcherSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        children: [
                          Text(
                            'Dat Bike Quantum S1',
                            style: GoogleFonts.syne(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.swap_horiz_rounded, size: 20, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ),
                  // Badge Bluetooth Connected hình viên thuốc trắng
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x080F172A),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          connected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                          size: 16,
                          color: connected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          connected ? 'Connected' : 'Disconnected',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: connected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ══════════════════════════════════════════════════════════════
              // 2. CỤM THÔNG SỐ: Quãng đường còn lại của xe máy điện (Font rộng)
              //    - Quãng đường: 185 km (theo pin thực tế) hoặc 270 km tối đa
              //    - ⚡ 68% Pin (185km)
              //    - 🔋 270km Max (hoặc 76.4 V · 33°C)
              // ══════════════════════════════════════════════════════════════
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$kmLeft',
                    style: GoogleFonts.syne(
                      fontSize: 54,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'km',
                    style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Dải thông số năng lượng xe máy điện: ⚡ Dung lượng pin · 🔋 Quãng đường đầy
              Row(
                children: [
                  // Điện năng hiện có: % Pin + Km
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, size: 17, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        '$percent% Pin ($kmLeft km)',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Quãng đường tiêu chuẩn tối đa khi đầy pin: 270 km
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '270 km Max',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),

              const SizedBox(height: 8),

              // 2 thanh progress nhỏ cho xe máy điện:
              // - Thanh 1: Tiến trình dung lượng Pin khả dụng (xanh lá)
              // - Thanh 2: Quãng đường còn lại / Dự phòng (xanh dương)
              Row(
                children: [
                  // Thanh Pin khả dụng (xanh lá)
                  Expanded(
                    flex: percent,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Thanh Quãng đường dự phòng (xanh dương)
                  Expanded(
                    flex: (100 - percent).clamp(5, 100),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Trạng thái vận hành xe máy điện (Parking / Ready / Driving)
              Text(
                statusText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 10),

              // ══════════════════════════════════════════════════════════════
              // 3. GIỮA MÀN HÌNH: ẢNH XE MÁY ĐIỆN DAT BIKE QUANTUM
              // ══════════════════════════════════════════════════════════════
              Container(
                width: double.infinity,
                height: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/bike_hero.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.two_wheeler_rounded, size: 90, color: Color(0xFF2563EB)),
                      ),
                    ),
                    // Badge trạng thái xe đang Bật / Khóa
                    if (isBikeOn)
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'XE SẴN SÀNG',
                                style: GoogleFonts.syne(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ══════════════════════════════════════════════════════════════
              // 4. CARD 4 NÚT ĐIỀU KHIỂN NHANH CHUYÊN BIỆT CHO XE MÁY ĐIỆN:
              //    1. Khóa (Lock/Unlock)
              //    2. Bật Xe (Power On/Off - Keyless)
              //    3. Tìm Xe (Find Bike - Còi & Đèn)
              //    4. Mở Cốp (Trunk - Cốp 41L)
              //    (Loại bỏ quạt điều hòa vì xe máy không có cabin AC!)
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // 1. Khóa Cổ & Chống Trộm
                          _quickActionButton(
                            icon: isLocked
                                ? GeelyIcons.lock(
                                    color: const Color(0xFFEF4444),
                                    size: 24,
                                  )
                                : GeelyIcons.lockOpen(
                                    color: const Color(0xFF2563EB),
                                    size: 24,
                                  ),
                            label: isLocked ? 'Mở Khóa' : 'Khóa Cổ',
                            onTap: _quickLockToggle,
                            active: isLocked,
                            activeColor: const Color(0xFFFEF2F2),
                            activeBorderColor: const Color(0xFFFECACA),
                          ),

                          // 2. Bật / Tắt Nguồn Xe Máy Điện (Keyless Power)
                          _quickActionButton(
                            icon: Icon(
                              Icons.power_settings_new_rounded,
                              color: isBikeOn ? const Color(0xFF10B981) : const Color(0xFF64748B),
                              size: 24,
                            ),
                            label: isBikeOn ? 'Tắt Máy' : 'Bật Xe',
                            onTap: _quickPowerToggle,
                            active: isBikeOn,
                            activeColor: const Color(0xFFF0FDF4),
                            activeBorderColor: const Color(0xFFBBF7D0),
                          ),

                          // 3. Tìm Xe Trong Bãi (Còi & Đèn Định Vị)
                          _quickActionButton(
                            icon: GeelyIcons.findBike(
                              color: const Color(0xFF2563EB),
                              size: 24,
                            ),
                            label: 'Tìm Xe',
                            onTap: _quickFindBike,
                          ),

                          // 4. Đồng bộ thời gian thực Taplo (RTC)
                          _quickActionButton(
                            icon: GeelyIcons.clock(
                              color: const Color(0xFF0F172A),
                              size: 24,
                            ),
                            label: 'Đồng bộ giờ',
                            onTap: _quickSyncTime,
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),

                    // Remote controls >
                    InkWell(
                      onTap: _openRemoteControlsSheet,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Remote controls',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ══════════════════════════════════════════════════════════════
              // 5. CARD CHUYẾN ĐI (Trip Computer & Thống kê hành trình)
              // ══════════════════════════════════════════════════════════════
              _buildTripCard(ble.trip),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WIDGETS CHUYẾN ĐI (TRIP COMPUTER) CHO XE MÁY ĐIỆN DAT BIKE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTripCard(TripData trip) {
    final mins = trip.duration.inMinutes;
    final secs = trip.duration.inSeconds % 60;
    final durationText = mins > 0
        ? '$mins phút ${secs > 0 ? "$secs s" : ""} · Đang ghi'
        : (secs > 0 ? '$secs giây · Đang ghi' : 'Sẵn sàng ghi nhận');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon Chuyến đi + Tiêu đề + Nút xem Lịch sử
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chuyến Đi Hiện Tại',
                      style: GoogleFonts.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      durationText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _openTripHistorySheet(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lịch sử',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lưới 4 thông số chuyến đi của xe máy điện
          Row(
            children: [
              Expanded(
                child: _tripMetricItem(
                  icon: Icons.straighten_rounded,
                  iconColor: const Color(0xFF2563EB),
                  label: 'Quãng đường',
                  value: trip.distanceKm.toStringAsFixed(1),
                  unit: 'km',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tripMetricItem(
                  icon: Icons.speed_rounded,
                  iconColor: const Color(0xFF0D9488),
                  label: 'Vận tốc TB',
                  value: trip.avgSpeedKmh.toStringAsFixed(1),
                  unit: 'km/h',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _tripMetricItem(
                  icon: Icons.electric_bolt_rounded,
                  iconColor: const Color(0xFFD97706),
                  label: 'Tốc độ tối đa',
                  value: trip.maxSpeedKmh.toStringAsFixed(0),
                  unit: 'km/h',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tripMetricItem(
                  icon: Icons.battery_charging_full_rounded,
                  iconColor: const Color(0xFF059669),
                  label: 'Pin tiêu hao',
                  value: '-${trip.usedPercent}',
                  unit: '%',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Eco impact banner + Nút đặt lại Trip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.eco_rounded, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Giảm ${(trip.distanceKm * 0.16).toStringAsFixed(1)} kg CO₂ so với xe xăng',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ),
                InkWell(
                  onTap: _confirmResetTrip,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF166534)),
                        const SizedBox(width: 4),
                        Text(
                          'Đặt lại',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResetTrip() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Đặt Lại Chuyến Đi (Trip)',
          style: GoogleFonts.syne(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Hệ thống sẽ đặt lại quãng đường, thời gian lái và vận tốc trung bình của chuyến đi hiện tại về 0.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'HỦY',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ĐẶT LẠI', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(bleProvider.notifier).resetTrip();
      _heroSnack('Đã đặt lại đồng hồ chuyến đi (Trip) về 0');
    }
  }

  void _openTripHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView(
              controller: scrollController,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lịch Sử Chuyến Đi',
                            style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tổng hợp hành trình & hiệu suất xe máy điện',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card Tổng hợp tuần này (Luminous Clean EV Banner)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x060F172A),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TUẦN NÀY',
                            style: GoogleFonts.syne(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                              letterSpacing: 1.0,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.eco_rounded, size: 12, color: Color(0xFF059669)),
                                const SizedBox(width: 4),
                                Text(
                                  '-23.7 kg CO₂',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _summaryStat(label: 'Tổng quãng đường', value: '148.2', unit: 'km'),
                          ),
                          Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
                          Expanded(
                            child: _summaryStat(label: 'Số chuyến đi', value: '12', unit: 'chuyến'),
                          ),
                          Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
                          Expanded(
                            child: _summaryStat(label: 'Tiết kiệm xăng', value: '195.000', unit: 'đ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'CÁC HÀNH TRÌNH GẦN ĐÂY',
                  style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),

                // Danh sách chuyến đi thực tế
                _tripHistoryItem(
                  title: 'Landmark 81 ➔ Thảo Điền',
                  time: 'Hôm nay · 08:15 (24 phút)',
                  distance: '12.4 km',
                  avgSpeed: '31 km/h',
                  batteryUsed: '-5%',
                  co2Saved: '2.0 kg',
                  isRecent: true,
                ),
                const SizedBox(height: 10),
                _tripHistoryItem(
                  title: 'Khu CNC Thủ Đức ➔ Quận 1',
                  time: 'Hôm qua · 17:45 (38 phút)',
                  distance: '19.8 km',
                  avgSpeed: '42 km/h',
                  batteryUsed: '-9%',
                  co2Saved: '3.2 kg',
                ),
                const SizedBox(height: 10),
                _tripHistoryItem(
                  title: 'Bến Bạch Đằng ➔ Sân Bay TSN',
                  time: '24/10 · 14:10 (22 phút)',
                  distance: '8.6 km',
                  avgSpeed: '27 km/h',
                  batteryUsed: '-4%',
                  co2Saved: '1.4 kg',
                ),
                const SizedBox(height: 10),
                _tripHistoryItem(
                  title: 'Phú Mỹ Hưng ➔ Chợ Bến Thành',
                  time: '23/10 · 09:30 (19 phút)',
                  distance: '7.5 km',
                  avgSpeed: '29 km/h',
                  batteryUsed: '-3%',
                  co2Saved: '1.2 kg',
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryStat({required String label, required String value, required String unit}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.syne(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: const Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _tripHistoryItem({
    required String title,
    required String time,
    required String distance,
    required String avgSpeed,
    required String batteryUsed,
    required String co2Saved,
    bool isRecent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecent ? const Color(0xFFBFDBFE) : const Color(0xFFF1F5F9),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isRecent ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.two_wheeler_rounded,
                  size: 18,
                  color: isRecent ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.syne(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                distance,
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _tripBadge(icon: Icons.speed_rounded, label: avgSpeed),
              const SizedBox(width: 8),
              _tripBadge(
                icon: Icons.battery_std_rounded,
                label: batteryUsed,
                color: const Color(0xFF059669),
              ),
              const SizedBox(width: 8),
              _tripBadge(
                icon: Icons.eco_rounded,
                label: '-$co2Saved CO₂',
                color: const Color(0xFF16A34A),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tripBadge({
    required IconData icon,
    required String label,
    Color color = const Color(0xFF64748B),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    Color? activeColor,
    Color? activeBorderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? (activeColor ?? const Color(0xFFEFF6FF)) : const Color(0xFFF8FAFC),
              border: Border.all(
                color: active ? (activeBorderColor ?? const Color(0xFFBFDBFE)) : const Color(0xFFF1F5F9),
                width: 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: (activeBorderColor ?? const Color(0xFF2563EB)).withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
