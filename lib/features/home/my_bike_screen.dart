// My Bike — Màn hình trung tâm (Kinetic Stitch EV):
// Bảng điều khiển tối giản chuẩn EV, thẻ trắng nâng cao, hiển thị pin dạng capsule,
// điều khiển nguồn hyper-legible, thông số telemetry Tabular Figures.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';
import '../../ui/app_theme.dart';
import '../../ui/widgets.dart';

class MyBikeScreen extends ConsumerStatefulWidget {
  const MyBikeScreen({super.key});

  @override
  ConsumerState<MyBikeScreen> createState() => _MyBikeScreenState();
}

class _MyBikeScreenState extends ConsumerState<MyBikeScreen> {
  late final AppLifecycleListener _lifecycleListener;

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

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);
    final connected = ble.phase == BlePhase.connected;
    final busy = ble.phase == BlePhase.connecting || ble.phase == BlePhase.reconnecting;
    final telemetry = ble.lastTelemetry;

    final (pillColor, pillLabel, pulse) = switch (ble.phase) {
      BlePhase.connected => (AppColors.tertiary, 'ĐÃ KẾT NỐI', true),
      BlePhase.connecting => (AppColors.amber, 'ĐANG KẾT NỐI…', true),
      BlePhase.reconnecting => (AppColors.amber, 'ĐANG THỬ LẠI…', true),
      BlePhase.scanning => (AppColors.secondary, 'ĐANG QUÉT…', true),
      BlePhase.disconnected => (AppColors.error, ble.message?.contains('sau 5 lần') == true ? 'MẤT TÍN HIỆU' : 'CHƯA KẾT NỐI', false),
      _ => (AppColors.textDim, 'SẴN SÀNG', false),
    };

    // Công suất tức thời kW
    final powerKw = (telemetry != null && telemetry.voltage > 0)
        ? ((telemetry.voltage * telemetry.phase) / 1000.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            // Top App Bar / Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAT BIKE EV',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08 * 11,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'XE CỦA TÔI',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                StatusPill(label: pillLabel, color: pillColor, pulse: pulse),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary, size: 22),
                  tooltip: 'Cài đặt xe & Hiệu năng',
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hero Card Xe (Kinetic Stitch Pure White Card)
            Panel(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              hasActiveHalo: connected,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: (connected ? AppColors.secondary : AppColors.primary)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (connected ? AppColors.secondary : AppColors.primary)
                                .withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.electric_moped_rounded,
                          size: 30,
                          color: connected ? AppColors.secondary : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ble.bikeName ?? 'Chưa kết nối xe',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ble.message ??
                                  (connected
                                      ? 'Kết nối BLE ổn định · Sẵn sàng vận hành'
                                      : busy
                                          ? 'Đang đàm phán phiên kết nối…'
                                          : 'Bấm "Tìm xe" hoặc "Kết nối lại" để bắt đầu'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.textDim,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (busy) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: const LinearProgressIndicator(minHeight: 4),
                    ),
                  ],

                  // Telemetry Metrics Mini Strip khi đã kết nối
                  if (connected && telemetry != null) ...[
                    const SizedBox(height: 18),
                    const Divider(color: AppColors.panelBorder, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DUNG LƯỢNG PIN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.05 * 10.5,
                                  color: AppColors.textDim,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${telemetry.percent}%',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ĐIỆN ÁP PACK',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.05 * 10.5,
                                  color: AppColors.textDim,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${telemetry.voltage.toStringAsFixed(1)} V',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CÔNG SUẤT',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.05 * 10.5,
                                  color: AppColors.textDim,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${powerKw.toStringAsFixed(2)} kW',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: powerKw < -0.05
                                      ? AppColors.tertiary
                                      : (powerKw > 0.05 ? AppColors.secondary : AppColors.textDim),
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Battery & Range Capsule (EV Exclusive)
            if (connected && telemetry != null) ...[
              BatteryRangeCapsule(
                percent: telemetry.percent,
                kmLeft: telemetry.kmLeft,
                isCharging: telemetry.charging != null,
                onTap: () => Navigator.of(context).pushNamed('/battery'),
              ),
              const SizedBox(height: 16),

              // Dynamic Charging Alert Card khi đang sạc
              if (telemetry.charging != null || telemetry.phase < -0.5) ...[
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/charging'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: AppColors.secondary, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ĐANG CẮM SẠC PIN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Text(
                                'Xem chi tiết công suất sạc, điện áp lưới & đồng hồ ETA ->',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDim),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.secondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],

            // Reconnect / Scan Buttons khi chưa kết nối
            if (!connected) ...[
              if (ble.bikeName != null) ...[
                VehicleCommandButton(
                  icon: Icons.refresh_rounded,
                  title: 'KẾT NỐI LẠI VỚI XE',
                  subtitle: ble.bikeName,
                  backgroundColor: AppColors.primary,
                  onPressed: busy ? null : () => ref.read(bleProvider.notifier).tryRestoreLastBike(),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.radar, size: 20),
                  label: const Text('Quét tìm xe khác'),
                  onPressed: busy ? null : () => Navigator.of(context).pushNamed('/scan'),
                ),
              ] else ...[
                VehicleCommandButton(
                  icon: Icons.radar,
                  title: 'TÌM XE BLUETOOTH',
                  subtitle: 'Bắt đầu quét xe Dat Bike xung quanh',
                  backgroundColor: AppColors.primary,
                  onPressed: busy ? null : () => Navigator.of(context).pushNamed('/scan'),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Cụm Công tắc Nguồn Bật / Tắt Xe chính (Level 1 Panel)
            if (connected) ...[
              Panel(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                borderRadius: 20,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tertiary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.power_settings_new_rounded, size: 22),
                        label: Text(
                          'BẬT XE',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(bleProvider.notifier).turnOnBike();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('⚡ Đã gửi lệnh BẬT XE thành công!'),
                                  backgroundColor: AppColors.tertiary,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi bật xe: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (telemetry?.speed ?? 0.0) > 0.5
                              ? AppColors.textDim
                              : AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(
                          (telemetry?.speed ?? 0.0) > 0.5 ? Icons.shield_rounded : Icons.power_off_rounded,
                          size: 22,
                        ),
                        label: Text(
                          (telemetry?.speed ?? 0.0) > 0.5 ? 'ĐANG CHẠY' : 'TẮT XE',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        onPressed: () async {
                          final spd = telemetry?.speed ?? 0.0;
                          if (spd > 0.5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('⚠️ CẢNH BÁO AN TOÀN: Không thể tắt xe khi đang di chuyển (${spd.toStringAsFixed(1)} km/h)!'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          final confirm = await _showConfirmTurnOffDialog(context);
                          if (!confirm) return;
                          try {
                            await ref.read(bleProvider.notifier).turnOffBike();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🔒 Đã gửi lệnh TẮT XE thành công!'),
                                  backgroundColor: AppColors.error,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi tắt xe: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Cụm Điều khiển Nhanh
            const SectionTitle('ĐIỀU KHIỂN NHANH'),
            const SizedBox(height: 10),
            Panel(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              borderRadius: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RoundControl(
                    icon: Icons.speed_rounded,
                    label: 'Cockpit HUD',
                    enabled: connected,
                    activeColor: AppColors.secondary,
                    onTap: () => Navigator.of(context).pushNamed('/dashboard'),
                  ),
                  RoundControl(
                    icon: Icons.lock_open_rounded,
                    label: 'Mở khóa',
                    enabled: connected,
                    activeColor: AppColors.primary,
                    onTap: () async {
                      final msg = await ref.read(bleProvider.notifier).unlockBike();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    },
                  ),
                  RoundControl(
                    icon: Icons.lock_rounded,
                    label: 'Khóa xe',
                    enabled: connected,
                    activeColor: AppColors.amber,
                    onTap: () async {
                      final spd = telemetry?.speed ?? 0.0;
                      if (spd > 0.5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('⚠️ Không thể khóa khi xe đang chạy (${spd.toStringAsFixed(1)} km/h)!'), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      final msg = await ref.read(bleProvider.notifier).lockBike();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    },
                  ),
                  RoundControl(
                    icon: ble.isFindingBike ? Icons.notifications_active_rounded : Icons.volume_up_rounded,
                    label: ble.isFindingBike ? 'Dừng còi' : 'Tìm xe',
                    enabled: connected,
                    activeColor: ble.isFindingBike ? AppColors.amber : AppColors.secondary,
                    onTap: () async {
                      if (ble.isFindingBike) {
                        final res = await ref.read(bleProvider.notifier).stopFindBike();
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
                      } else {
                        final res = await ref.read(bleProvider.notifier).findBike();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res), backgroundColor: AppColors.amber),
                          );
                        }
                      }
                    },
                  ),
                  RoundControl(
                    icon: Icons.ev_station_rounded,
                    label: 'Trạm sạc',
                    enabled: true,
                    activeColor: AppColors.secondary,
                    onTap: () => Navigator.of(context).pushNamed('/charging'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Trạng thái Kết nối & Đồng bộ Taplo xe (Sprint 1)
            if (connected) ...[
              const SectionTitle('KẾT NỐI & ĐỒNG BỘ TAPLO'),
              const SizedBox(height: 10),
              Panel(
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                child: Column(
                  children: [
                    // 1. Tín hiệu BLE & Khoảng cách (Kalman Filter)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ((ble.filteredRssi ?? -100) > -65
                                    ? AppColors.tertiary
                                    : (ble.filteredRssi ?? -100) > -85
                                        ? AppColors.secondary
                                        : AppColors.amber)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            (ble.filteredRssi ?? -100) > -65
                                ? Icons.near_me_rounded
                                : (ble.filteredRssi ?? -100) > -85
                                    ? Icons.bluetooth_connected_rounded
                                    : Icons.directions_walk_rounded,
                            color: (ble.filteredRssi ?? -100) > -65
                                ? AppColors.tertiary
                                : (ble.filteredRssi ?? -100) > -85
                                    ? AppColors.secondary
                                    : AppColors.amber,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Tín hiệu cự ly',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Kalman 1D',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                ble.filteredRssi != null
                                    ? 'Cường độ: ${ble.filteredRssi} dBm (Gốc: ${ble.rssi ?? "--"} dBm)'
                                    : 'Đang đo suy hao sóng BLE…',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(
                          label: (ble.filteredRssi ?? -100) > -65
                              ? 'RẤT GẦN'
                              : (ble.filteredRssi ?? -100) > -85
                                  ? 'CỰ LY VỪA'
                                  : 'Ở XA',
                          color: (ble.filteredRssi ?? -100) > -65
                              ? AppColors.tertiary
                              : (ble.filteredRssi ?? -100) > -85
                                  ? AppColors.secondary
                                  : AppColors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.panelBorder, height: 1),
                    const SizedBox(height: 14),

                    // 2. Đồng bộ thời gian thực Taplo xe
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.access_time_filled_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đồng hồ Taplo xe',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                ble.lastTimeSynced != null
                                    ? 'Đã đồng bộ: ${ble.lastTimeSynced!.hour.toString().padLeft(2, '0')}:${ble.lastTimeSynced!.minute.toString().padLeft(2, '0')}:${ble.lastTimeSynced!.second.toString().padLeft(2, '0')}'
                                    : 'Tự động gửi khi bắt tay xe',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: ble.lastTimeSynced != null
                                      ? AppColors.tertiary
                                      : AppColors.textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: Text(
                            'Gửi giờ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () async {
                            final res = await ref.read(bleProvider.notifier).syncTimeWithBike();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res),
                                  backgroundColor: res.contains('thành công')
                                      ? AppColors.tertiary
                                      : AppColors.amber,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Tự Động Hóa Thông Minh & An Toàn
            const SectionTitle('TỰ ĐỘNG HÓA & AN TOÀN'),
            const SizedBox(height: 10),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              borderRadius: 20,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.amber, size: 20),
                    ),
                    title: Text(
                      'Cảnh báo quên tắt xe khi đi xa',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Nhắc nhở ngay nếu đi xa hoặc mất kết nối khi xe vẫn đang bật',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDim),
                    ),
                    value: ble.antiForgetAlert,
                    onChanged: (val) => ref.read(bleProvider.notifier).setAntiForgetAlert(val),
                  ),
                  if (ble.antiForgetAlert) ...[
                    _buildDistanceSelector(
                      title: 'Khoảng cách kích hoạt cảnh báo',
                      selectedIndex: ble.antiForgetDistance,
                      onSelected: (idx) => ref.read(bleProvider.notifier).setAntiForgetDistance(idx),
                    ),
                  ],
                  const Divider(color: AppColors.panelBorder, height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_clock_rounded, color: AppColors.secondary, size: 20),
                    ),
                    title: Text(
                      'Tự động khóa khi rời xa (Walk-away)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Tự động tắt nguồn/khóa xe an toàn khi phát hiện bạn đi xa',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDim),
                    ),
                    value: ble.autoLockWalkAway,
                    onChanged: (val) => ref.read(bleProvider.notifier).setAutoLockWalkAway(val),
                  ),
                  if (ble.autoLockWalkAway) ...[
                    _buildDistanceSelector(
                      title: 'Khoảng cách kích hoạt tự khóa',
                      selectedIndex: ble.autoLockDistance,
                      onSelected: (idx) => ref.read(bleProvider.notifier).setAutoLockDistance(idx),
                    ),
                  ],
                  const Divider(color: AppColors.panelBorder, height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      'Cài đặt hiệu năng & Cảm giác lái',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Mức phanh tái sinh RECUP, độ nhạy ga, mẫu còi tìm xe',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDim),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textDim),
                    onTap: () => Navigator.of(context).pushNamed('/settings'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nút Quên xe / Xóa xe
            if (ble.bikeName != null) ...[
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(
                    'Xóa / Quên xe "${ble.bikeName}"',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    final confirm = await _showConfirmForgetBikeDialog(context, ble.bikeName ?? '');
                    if (confirm && mounted) {
                      await ref.read(bleProvider.notifier).forgetBike();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã xóa thông tin xe và hủy kết nối.'),
                            backgroundColor: AppColors.textPrimary,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmTurnOffDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.panel,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 26),
                const SizedBox(width: 10),
                Text(
                  'Xác nhận tắt xe',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              'Bạn có chắc chắn muốn TẮT NGUỒN xe không?\nĐộng cơ sẽ ngắt và xe chuyển sang trạng thái chờ.',
              style: GoogleFonts.plusJakartaSans(color: AppColors.textDim, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'HỦY',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textDim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'TẮT XE',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showConfirmForgetBikeDialog(BuildContext context, String bikeName) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.panel,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 26),
                const SizedBox(width: 10),
                Text(
                  'Xóa xe đã lưu',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              'Bạn có chắc chắn muốn XÓA xe "$bikeName" khỏi ứng dụng không?\n\n'
              'Ứng dụng sẽ ngắt kết nối, hủy ghép nối và xóa toàn bộ thông tin đã lưu của xe này.',
              style: GoogleFonts.plusJakartaSans(color: AppColors.textDim, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'HỦY',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textDim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'XÓA XE',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildDistanceSelector({
    required String title,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    const labels = ['Gần (~2-3m)', 'Vừa (~5-7m)', 'Xa (~10m)'];
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(3, (idx) {
              final isSelected = selectedIndex == idx;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: idx == 0 ? 0 : 3,
                    right: idx == 2 ? 0 : 3,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onSelected(idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.panelSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.panelBorder,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          labels[idx],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textDim,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
