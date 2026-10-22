// Vehicle Settings & Customization Screen — Cài Đặt Hiệu Năng & Cá Nhân Hóa Xe
// Chuẩn thiết kế Kinetic Stitch EV:
// 1. Tinh chỉnh cảm giác lái: Mức phanh tái sinh RECUP, Độ nhạy tay ga, Giới hạn tốc độ an toàn.
// 2. Chế độ âm thanh còi tìm xe: Mẫu nhịp tiêu chuẩn, Nhịp đôi Staccato, Báo động dồn dập SOS.
// 3. Thông tin xe & Serial khung sườn từ firmware xe (deviceSerialChar).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';
import '../../ui/app_theme.dart';
import '../../ui/widgets.dart';

class VehicleSettingsScreen extends ConsumerStatefulWidget {
  const VehicleSettingsScreen({super.key});

  @override
  ConsumerState<VehicleSettingsScreen> createState() => _VehicleSettingsScreenState();
}

class _VehicleSettingsScreenState extends ConsumerState<VehicleSettingsScreen> {
  bool _isReadingSerial = false;
  bool _isSyncingTime = false;

  Future<void> _readSerial() async {
    setState(() => _isReadingSerial = true);
    final serial = await ref.read(bleProvider.notifier).readDeviceSerial();
    if (mounted) {
      setState(() => _isReadingSerial = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(serial != null ? '✅ Đã đọc số Serial xe: $serial' : 'Không thể đọc số Serial lúc này.'),
          backgroundColor: serial != null ? AppColors.tertiary : AppColors.amber,
        ),
      );
    }
  }

  Future<void> _syncTime() async {
    setState(() => _isSyncingTime = true);
    final res = await ref.read(bleProvider.notifier).syncTimeWithBike();
    if (mounted) {
      setState(() => _isSyncingTime = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res),
          backgroundColor: res.contains('thành công') ? AppColors.tertiary : AppColors.amber,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);
    final connected = ble.phase == BlePhase.connected;
    final telemetry = ble.lastTelemetry;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'CÀI ĐẶT XE & HIỆU NĂNG',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // 1. Thẻ Thông Tin Xe & Serial Khung
          _buildVehicleInfoCard(ble, connected, telemetry?.version ?? '1.14.0'),
          const SizedBox(height: 16),

          // 2. Thẻ Đồng Bộ Đồng Hồ Taplo
          const SectionTitle('ĐỒNG HỒ TAPLO & THỜI GIAN THỰC'),
          const SizedBox(height: 10),
          _buildTimeSyncCard(ble, connected),
          const SizedBox(height: 16),

          // 3. Cảm Giác Lái & Hiệu Năng Vận Hành
          const SectionTitle('HIỆU NĂNG & CẢM GIÁC LÁI'),
          const SizedBox(height: 10),
          _buildPerformanceCard(ble),
          const SizedBox(height: 16),

          // 4. Chế Độ Âm Thanh Còi / Buzzer Tìm Xe
          const SectionTitle('ÂM THANH CÒI TÌM XE & BÁO ĐỘNG'),
          const SizedBox(height: 10),
          _buildSoundPatternCard(ble, connected),
          const SizedBox(height: 16),

          // 5. Giới Hạn Tốc Độ An Toàn (Speed Limiter)
          const SectionTitle('GIỚI HẠN TỐC ĐỘ AN TOÀN'),
          const SizedBox(height: 10),
          _buildSpeedLimiterCard(ble),
        ],
      ),
    );
  }

  // ========== THẺ 1: THÔNG TIN XE & SERIAL ==========
  Widget _buildVehicleInfoCard(BleState ble, bool connected, String fwVersion) {
    final telemetry = ble.lastTelemetry;
    final displaySerial = (ble.frameSerial != null && ble.frameSerial!.trim().isNotEmpty)
        ? ble.frameSerial!.trim()
        : (telemetry != null && telemetry.frame.trim().isNotEmpty ? telemetry.frame.trim() : null);

    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ble.bikeName ?? 'Dat Bike EV',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Firmware: $fwVersion · ${connected ? "Đang kết nối" : "Chưa kết nối"}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: connected ? AppColors.tertiary : AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: connected ? 'ONLINE' : 'OFFLINE',
                color: connected ? AppColors.tertiary : AppColors.textDim,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.panelBorder, height: 1),
          const SizedBox(height: 12),

          // KHUNG SỐ SERIAL KHUNG XE (FRAME / VIN) CHUYÊN DỤNG — Kinetic Stitch EV
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.panelSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.panelBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, size: 14, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SỐ SERIAL KHUNG XE (FRAME / VIN)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.textDim,
                        ),
                      ),
                    ),
                    if (displaySerial != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.tertiary.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'ĐÃ ĐỒNG BỘ',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.tertiary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          displaySerial ?? 'Chưa đọc từ firmware xe',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: displaySerial != null ? 1.0 : 0.2,
                            color: displaySerial != null ? AppColors.textPrimary : AppColors.textDim,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (displaySerial != null)
                      IconButton(
                        tooltip: 'Sao chép số Serial',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textDim),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: displaySerial));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Đã sao chép số Serial: $displaySerial'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.panel,
                            ),
                          );
                        },
                      ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: connected && !_isReadingSerial ? _readSerial : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: connected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: connected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.panelBorder,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isReadingSerial)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.primary),
                              )
                            else
                              Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: connected ? AppColors.primary : AppColors.textDim,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              _isReadingSerial ? 'Đang đọc...' : 'Đọc lại',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: connected ? AppColors.primary : AppColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== THẺ: ĐỒNG HỒ TAPLO & THỜI GIAN THỰC ==========
  Widget _buildTimeSyncCard(BleState ble, bool connected) {
    final lastSync = ble.lastTimeSynced;
    final lastSyncStr = lastSync != null
        ? '${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}:${lastSync.second.toString().padLeft(2, '0')} (${lastSync.day}/${lastSync.month})'
        : 'Chưa đồng bộ phiên này';

    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đồng Hồ Màn Hình Taplo',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lần cuối: $lastSyncStr',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: lastSync != null ? AppColors.tertiary : AppColors.textDim,
                        fontWeight: lastSync != null ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: connected ? AppColors.primary : AppColors.surface,
                  foregroundColor: connected ? Colors.white : AppColors.textDim,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isSyncingTime
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync_rounded, size: 16),
                label: Text(
                  _isSyncingTime ? 'Đang gửi...' : 'Đồng bộ',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: (connected && !_isSyncingTime) ? _syncTime : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Gửi số giây chuẩn UTC (chuẩn firmware Dat Bike) vào màn hình Taplo xe qua kết nối BLE bảo mật, khắc phục triệt để lỗi lệch giờ khi xe ngắt bình hoặc đỗ lâu ngày.',
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textDim, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ========== THẺ 2: CẢM GIÁC LÁI & PHANH TÁI SINH ==========
  Widget _buildPerformanceCard(BleState ble) {
    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.amber, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'LƯU Ý KỸ THUẬT: Firmware xe hiện tại (v1.14.0) chưa hỗ trợ nạp cấu hình phanh RECUP & tay ga trực tiếp qua Bluetooth. Tùy chọn này được lưu làm hồ sơ cá nhân trên ứng dụng.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 1. Phanh tái sinh (Regenerative Braking RECUP)
          Row(
            children: [
              const Icon(Icons.replay_circle_filled_rounded, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mức Phanh Tái Sinh (RECUP)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Thu hồi động năng nạp ngược vào pack pin khi bạn buông tay ga.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDim),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSegmentOption(
                label: 'Nhẹ',
                desc: 'Trôi xe êm',
                isSelected: ble.recupLevel == 0,
                onTap: () => ref.read(bleProvider.notifier).setRecupLevel(0),
              ),
              const SizedBox(width: 8),
              _buildSegmentOption(
                label: 'Tiêu chuẩn',
                desc: 'Cân bằng EV',
                isSelected: ble.recupLevel == 1,
                onTap: () => ref.read(bleProvider.notifier).setRecupLevel(1),
              ),
              const SizedBox(width: 8),
              _buildSegmentOption(
                label: 'Mạnh',
                desc: 'One-Pedal',
                isSelected: ble.recupLevel == 2,
                onTap: () => ref.read(bleProvider.notifier).setRecupLevel(2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.panelBorder, height: 1),
          const SizedBox(height: 14),

          // 2. Độ nhạy tay ga (Throttle Response)
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Độ Nhạy Phản Hồi Bướm Ga',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Điều chỉnh đường đặc tính đáp ứng mô-men xoắn của động cơ.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDim),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSegmentOption(
                label: 'Êm ái',
                desc: 'Eco / Đường mưa',
                isSelected: ble.throttleResponse == 0,
                onTap: () => ref.read(bleProvider.notifier).setThrottleResponse(0),
              ),
              const SizedBox(width: 8),
              _buildSegmentOption(
                label: 'Tiêu chuẩn',
                desc: 'Mượt mà đô thị',
                isSelected: ble.throttleResponse == 1,
                onTap: () => ref.read(bleProvider.notifier).setThrottleResponse(1),
              ),
              const SizedBox(width: 8),
              _buildSegmentOption(
                label: 'Thể thao',
                desc: 'Đề pa bốc',
                isSelected: ble.throttleResponse == 2,
                onTap: () => ref.read(bleProvider.notifier).setThrottleResponse(2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== THẺ 3: MẪU ÂM THANH CÒI TÌM XE ==========
  Widget _buildSoundPatternCard(BleState ble, bool connected) {
    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ghi chú kỹ thuật về tính năng còi tìm xe
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đặc tả BLE: Còi tìm xe hiện phát tín hiệu thử nghiệm an toàn qua Alert Service (0x5B6D1069). Ứng dụng đã gỡ bỏ hoàn toàn việc can thiệp vào công tắc nguồn (0x350D9A82) để bảo vệ tuyệt đối relay xe.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chọn mẫu nhịp chuông kèn khi bấm "Tìm xe" trong bãi đỗ:',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDim),
          ),
          const SizedBox(height: 14),

          _buildPatternRadioTile(
            patternId: 0,
            title: 'Nhịp Tiêu Chuẩn (Single Beep)',
            subtitle: 'Bíp đơn cách nhau 1.1 giây — nhã nhặn, vang xa',
            isSelected: ble.findBikePattern == 0,
            onTap: () => ref.read(bleProvider.notifier).setFindBikePattern(0),
          ),
          const SizedBox(height: 8),
          _buildPatternRadioTile(
            patternId: 1,
            title: 'Nhịp Đôi Thể Thao (Double Staccato)',
            subtitle: 'Bíp kép (bíp-bíp... bíp-bíp) — dễ phân biệt trong bãi xe đông',
            isSelected: ble.findBikePattern == 1,
            onTap: () => ref.read(bleProvider.notifier).setFindBikePattern(1),
          ),
          const SizedBox(height: 8),
          _buildPatternRadioTile(
            patternId: 2,
            title: 'Báo Động Dồn Dập (Urgent SOS)',
            subtitle: 'Bíp liên hồi chu kỳ ngắn 450ms — định vị tức thời',
            isSelected: ble.findBikePattern == 2,
            onTap: () => ref.read(bleProvider.notifier).setFindBikePattern(2),
          ),
          const SizedBox(height: 14),

          // Nút thử âm thanh còi
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ble.isFindingBike ? AppColors.amber : AppColors.secondary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(
                ble.isFindingBike ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                size: 20,
              ),
              label: Text(
                ble.isFindingBike ? 'DỪNG THỬ CÒI' : 'THỬ ÂM THANH NÀY (3 GIÂY)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              onPressed: connected
                  ? () async {
                      if (ble.isFindingBike) {
                        await ref.read(bleProvider.notifier).stopFindBike();
                      } else {
                        await ref.read(bleProvider.notifier).findBike(timeout: const Duration(seconds: 3));
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternRadioTile({
    required int patternId,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.panelSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.panelBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textDim,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textDim),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== THẺ 4: GIỚI HẠN TỐC ĐỘ AN TOÀN ==========
  Widget _buildSpeedLimiterCard(BleState ble) {
    return Panel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'CẢNH BÁO AN TOÀN: Firmware xe hiện tại (v1.14.0) KHÔNG hỗ trợ giới hạn tốc độ xe từ Bluetooth! Xe vẫn chạy với công suất nguyên bản. TUYỆT ĐỐI KHÔNG sử dụng tùy chọn này làm chốt an toàn để cho người mới tập lái mượn xe!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Hồ sơ tốc độ lái khuyến nghị trên ứng dụng (App-side Driver Profile):',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDim),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSegmentOption(
                label: 'Không giới hạn',
                desc: 'Hồ sơ Full Power',
                isSelected: ble.speedLimitMode == 0,
                onTap: () => ref.read(bleProvider.notifier).setSpeedLimitMode(0),
              ),
              const SizedBox(width: 8),
              _buildSegmentOption(
                label: 'Đô thị',
                desc: 'Khuyến nghị 50 km/h',
                isSelected: ble.speedLimitMode == 1,
                onTap: () => ref.read(bleProvider.notifier).setSpeedLimitMode(1),
              ),
              const SizedBox(width: 8),
              _buildSegmentOption(
                label: 'Tập lái',
                desc: 'Khuyến nghị 30 km/h',
                isSelected: ble.speedLimitMode == 2,
                onTap: () => ref.read(bleProvider.notifier).setSpeedLimitMode(2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentOption({
    required String label,
    required String desc,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.panelSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.panelBorder,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white.withValues(alpha: 0.85) : AppColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
