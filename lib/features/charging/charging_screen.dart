// Charging Screen — Bộ Định Tuyến Sạc Thông Minh & Bản Đồ Trạm Sạc Dat Charge
// Chuẩn thiết kế Kinetic Stitch EV:
// 1. Giám sát chi tiết dòng sạc, điện áp lưới AC Vin_RMS, nhiệt độ FET, công suất Watt.
// 2. Bộ đếm thời gian sạc thông minh: ETA đạt 80% (mốc vàng) & 100%, giới hạn sạc tùy chỉnh.
// 3. Bản đồ & danh bạ trạm sạc Dat Charge: Đánh giá khả thi tầm pin, lọc trạm, mở chỉ đường Google Maps.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';
import '../../core/services/charging_router_service.dart';
import '../../ui/app_theme.dart';
import '../../ui/widgets.dart';

class ChargingScreen extends ConsumerStatefulWidget {
  const ChargingScreen({super.key});

  @override
  ConsumerState<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends ConsumerState<ChargingScreen> {
  int _activeTab = 0; // 0: Trạng thái sạc, 1: Trạm sạc Dat Charge
  int _selectedSocLimit = 80; // Mặc định 80% để bảo vệ pin EV
  String _selectedCity = 'Tất cả';
  bool _filterWithinRangeOnly = false;
  bool _filterSuperBoostOnly = false;

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return 'Đã đạt mốc';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '$h giờ $m phút';
    return '$m phút';
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);
    final telemetry = ble.lastTelemetry;
    final kmLeft = telemetry?.kmLeft ?? 100.0;
    final currentPercent = telemetry?.percent ?? 65;

    final report = ChargingRouterService.analyzeCharging(
      telemetry: telemetry,
      targetLimit: _selectedSocLimit,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'ĐỊNH TUYẾN & TRẠM SẠC',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab switcher ở đầu màn hình
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.panelSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.panelBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSubTabButton(
                      label: 'TRẠNG THÁI SẠC',
                      icon: Icons.bolt_rounded,
                      isSelected: _activeTab == 0,
                      onTap: () => setState(() => _activeTab = 0),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildSubTabButton(
                      label: 'TRẠM SẠC DAT CHARGE',
                      icon: Icons.ev_station_rounded,
                      isSelected: _activeTab == 1,
                      onTap: () => setState(() => _activeTab = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nội dung tab
          Expanded(
            child: _activeTab == 0
                ? _buildChargingHudTab(report, currentPercent, kmLeft)
                : _buildStationsTab(kmLeft),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.panel : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? AppColors.cardShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textDim,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: TRẠNG THÁI SẠC THÔNG MINH (CHARGING HUD)
  // =========================================================================
  Widget _buildChargingHudTab(
    ChargingStatusReport report,
    int currentPercent,
    double kmLeft,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        if (report.isGridUnstable) ...[
          const NoticeBanner(
            color: AppColors.error,
            text: '⚠️ CẢNH BÁO NGUỒN AC: Điện áp lưới không ổn định! Khuyến nghị kiểm tra ổ cắm.',
          ),
          const SizedBox(height: 12),
        ],

        // 1. Hero Charging Pod
        Panel(
          padding: const EdgeInsets.all(22),
          borderRadius: 24,
          hasActiveHalo: report.isCharging,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: (report.isCharging ? AppColors.secondary : AppColors.primary)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: (report.isCharging ? AppColors.secondary : AppColors.primary)
                            .withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      report.isCharging ? Icons.bolt_rounded : Icons.battery_std_rounded,
                      size: 32,
                      color: report.isCharging ? AppColors.secondary : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.stageName.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.06 * 12,
                            color: report.isCharging ? AppColors.secondary : AppColors.textDim,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$currentPercent',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            Text(
                              '%',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDim,
                              ),
                            ),
                            const Spacer(),
                            if (report.isCharging)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${report.powerWatts} W',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.secondary,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  Text(
                                    'Công suất sạc',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.textDim,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Thanh tiến trình pin dạng capsule
              ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  height: 12,
                  color: AppColors.panelSecondary,
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: (currentPercent / 100.0).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: report.isCharging ? AppColors.secondary : AppColors.primary,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.panelBorder, height: 1),
              const SizedBox(height: 14),

              // 4 chỉ số kỹ thuật chi tiết
              Row(
                children: [
                  _buildChargingMetric(
                    label: 'ĐIỆN LƯỚI AC',
                    value: '${report.gridVoltageRms.toStringAsFixed(1)} V',
                    valueColor: report.isGridUnstable ? AppColors.error : AppColors.textPrimary,
                  ),
                  _buildChargingMetric(
                    label: 'NHIỆT CỦ SẠC',
                    value: '${report.fetTemp} °C',
                    valueColor: report.isFetOverheat ? AppColors.error : AppColors.textPrimary,
                  ),
                  _buildChargingMetric(
                    label: 'ĐIỆN ĐÃ NẠP',
                    value: '${report.energyChargedKwh.toStringAsFixed(2)} kWh',
                  ),
                  _buildChargingMetric(
                    label: 'CỰ LY DỰ KIẾN',
                    value: '${kmLeft.toStringAsFixed(0)} km',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Bộ đếm thời gian sạc thông minh (Smart ETA)
        const SectionTitle('BỘ ĐẾM THỜI GIAN SẠC THÔNG MINH (SMART ETA)'),
        const SizedBox(height: 10),
        Row(
          children: [
            // Thẻ đạt mốc 80% (Mốc vàng bảo vệ tuổi thọ pin EV)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.tertiary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'MỐC 80% (BẢO VỆ PIN)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.05 * 10.5,
                            color: AppColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(report.eta80),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Khuyến nghị hàng ngày để tối đa tuổi thọ cell pin.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Thẻ đạt 100% (Sạc đầy)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.battery_full_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'SẠC ĐẦY 100%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.05 * 10.5,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(report.etaTotal),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dành cho những chuyến đi xa cần cự ly tối đa.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3. Cài đặt Giới Hạn Sạc Pin Tùy Chỉnh (Charge Limit Guard)
        const SectionTitle('GIỚI HẠN SẠC MỤC TIÊU (CHARGE LIMIT)'),
        const SizedBox(height: 10),
        Panel(
          padding: const EdgeInsets.all(16),
          borderRadius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Cảnh báo khi đạt mốc giới hạn',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Ứng dụng sẽ gửi thông báo đẩy để bạn rút sạc đúng thời điểm, tránh chai pin.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDim),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildLimitOption(80, '80% (Khuyến nghị)'),
                  const SizedBox(width: 8),
                  _buildLimitOption(90, '90%'),
                  const SizedBox(width: 8),
                  _buildLimitOption(100, '100% (Đầy)'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLimitOption(int value, String label) {
    final isSelected = _selectedSocLimit == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSocLimit = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.panelSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.panelBorder,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChargingMetric({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: BẢN ĐỒ & DANH BẠ TRẠM SẠC DAT CHARGE
  // =========================================================================
  Widget _buildStationsTab(double kmLeft) {
    // Tọa độ tham chiếu trung tâm (TP.HCM: 10.7769, 106.7009)
    const userLat = 10.7769;
    const userLng = 106.7009;

    var filteredStations = ChargingRouterService.stations.where((s) {
      if (_selectedCity != 'Tất cả' && s.city != _selectedCity) return false;
      if (_filterSuperBoostOnly && s.powerKw < 4.0) return false;
      if (_filterWithinRangeOnly) {
        final dist = ChargingRouterService.calculateDistanceKm(
          lat1: userLat,
          lon1: userLng,
          lat2: s.latitude,
          lon2: s.longitude,
        );
        if (kmLeft < dist) return false;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        // 1. Thẻ thông tin cự ly pin hiện tại
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.radar_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TẦM HOẠT ĐỘNG PIN CỦA BẠN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Khoảng ${kmLeft.toStringAsFixed(1)} km pin còn lại',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: kmLeft > 40 ? 'DƯ DẢ' : 'CẦN SẠC',
                color: kmLeft > 40 ? AppColors.tertiary : AppColors.amber,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Bộ lọc Thành phố & Tiêu chí
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCityFilterChip('Tất cả'),
              _buildCityFilterChip('TP. Hồ Chí Minh'),
              _buildCityFilterChip('Hà Nội'),
              _buildCityFilterChip('Đà Nẵng'),
              _buildCityFilterChip('Bình Dương'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            FilterChip(
              label: Text(
                'Trong tầm pin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _filterWithinRangeOnly ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: _filterWithinRangeOnly,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.panel,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (val) => setState(() => _filterWithinRangeOnly = val),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(
                '⚡ Siêu nhanh 4kW',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _filterSuperBoostOnly ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: _filterSuperBoostOnly,
              selectedColor: AppColors.secondary,
              backgroundColor: AppColors.panel,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (val) => setState(() => _filterSuperBoostOnly = val),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3. Danh sách thẻ trạm sạc
        for (final station in filteredStations)
          _buildStationCard(station, userLat, userLng, kmLeft),
      ],
    );
  }

  Widget _buildCityFilterChip(String city) {
    final isSelected = _selectedCity == city;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          city,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (val) {
          if (val) setState(() => _selectedCity = city);
        },
      ),
    );
  }

  Widget _buildStationCard(
    DatChargeStation station,
    double userLat,
    double userLng,
    double kmLeft,
  ) {
    final distanceKm = ChargingRouterService.calculateDistanceKm(
      lat1: userLat,
      lon1: userLng,
      lat2: station.latitude,
      lon2: station.longitude,
    );

    final reachability = ChargingRouterService.evaluateReachability(
      distanceKm: distanceKm,
      kmLeft: kmLeft,
    );

    final reachColor = Color(reachability.colorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        station.address,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: station.powerKw >= 4.0
                        ? AppColors.secondary.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${station.powerKw.toStringAsFixed(1)} kW',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: station.powerKw >= 4.0 ? AppColors.secondary : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.panelBorder, height: 1),
            const SizedBox(height: 10),

            // Tiện ích & Thông số trạm
            Row(
              children: [
                Icon(Icons.ev_station_rounded, size: 16, color: reachColor),
                const SizedBox(width: 4),
                Text(
                  '${station.availablePorts}/${station.totalPorts} cổng trống',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.directions_bike_rounded, size: 16, color: reachColor),
                const SizedBox(width: 4),
                Text(
                  '${distanceKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  reachability.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: reachColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nút bấm chỉ đường Google Maps
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.navigation_rounded, size: 16),
                label: Text(
                  'Chỉ đường Google Maps',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => ChargingRouterService.launchGoogleMaps(
                  station.latitude,
                  station.longitude,
                  station.name,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
