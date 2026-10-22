// Bộ Định Tuyến Sạc Thông Minh & Bản Đồ Trạm Sạc Dat Charge
//
// 1. Giám sát chi tiết dòng sạc: Công suất W, Điện áp lưới AC Vin_RMS, Nhiệt độ FET, Stage sạc.
// 2. Bộ đếm thời gian sạc thông minh: ETA đạt 80% (mốc vàng bảo vệ pin) và 100%.
// 3. Bản đồ trạm sạc Dat Charge: Đánh giá khả thi pin (Range Check), lọc trạm, mở chỉ đường Google Maps.

import 'dart:math';
import 'package:flutter/services.dart';
import '../proto/bike_log.dart';

class DatChargeStation {
  final String id;
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final double powerKw;
  final int totalPorts;
  final int availablePorts;
  final bool isOpen247;
  final bool hasCoffee;
  final bool hasServiceShop;
  final bool isOfficial;

  const DatChargeStation({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.powerKw,
    required this.totalPorts,
    required this.availablePorts,
    this.isOpen247 = true,
    this.hasCoffee = false,
    this.hasServiceShop = false,
    this.isOfficial = true,
  });
}

enum StationReachability {
  safe('Trong tầm pin an toàn', 0xFF10B981),
  tight('Sát tầm pin (Chạy tiết kiệm)', 0xFFF59E0B),
  unreachable('Không đủ pin tới nơi', 0xFFEF4444);

  final String label;
  final int colorValue;
  const StationReachability(this.label, this.colorValue);
}

class ChargingStatusReport {
  final bool isCharging;
  final String stageName;
  final int stage;
  final int powerWatts;
  final double gridVoltageRms;
  final bool isGridUnstable;
  final int fetTemp;
  final bool isFetOverheat;
  final Duration etaTotal;
  final Duration eta80;
  final Duration boostRemaining;
  final String profileName;
  final double energyChargedKwh;
  final int targetSocLimit;

  const ChargingStatusReport({
    required this.isCharging,
    required this.stageName,
    required this.stage,
    required this.powerWatts,
    required this.gridVoltageRms,
    required this.isGridUnstable,
    required this.fetTemp,
    required this.isFetOverheat,
    required this.etaTotal,
    required this.eta80,
    required this.boostRemaining,
    required this.profileName,
    required this.energyChargedKwh,
    this.targetSocLimit = 80,
  });
}

class ChargingRouterService {
  ChargingRouterService._();

  static const _channel = MethodChannel('vn.datbike/export');

  /// Danh sách trạm sạc Dat Charge chính hãng & liên kết tại Việt Nam
  static const List<DatChargeStation> stations = [
    // TP. HỒ CHÍ MINH
    DatChargeStation(
      id: 'hcm-01',
      name: 'Dat Charge Showroom Thủ Thiêm',
      address: 'Số 12 Đường Mai Chí Thọ, P. An Phú, TP. Thủ Đức, TP.HCM',
      city: 'TP. Hồ Chí Minh',
      latitude: 10.7852,
      longitude: 106.7321,
      powerKw: 4.0,
      totalPorts: 4,
      availablePorts: 3,
      isOpen247: true,
      hasCoffee: true,
      hasServiceShop: true,
    ),
    DatChargeStation(
      id: 'hcm-02',
      name: 'Dat Charge Flagship Quận 1',
      address: 'Số 214 Trần Hưng Đạo, P. Nguyễn Cư Trinh, Quận 1, TP.HCM',
      city: 'TP. Hồ Chí Minh',
      latitude: 10.7601,
      longitude: 106.6902,
      powerKw: 4.0,
      totalPorts: 3,
      availablePorts: 2,
      isOpen247: true,
      hasCoffee: true,
    ),
    DatChargeStation(
      id: 'hcm-03',
      name: 'Dat Charge Landmark 81',
      address: 'Khu Đô Thị Vinhomes Central Park, P. 22, Q. Bình Thạnh, TP.HCM',
      city: 'TP. Hồ Chí Minh',
      latitude: 10.7950,
      longitude: 106.7218,
      powerKw: 2.4,
      totalPorts: 2,
      availablePorts: 2,
      isOpen247: true,
      hasCoffee: true,
    ),
    DatChargeStation(
      id: 'hcm-04',
      name: 'Dat Charge Phú Mỹ Hưng',
      address: 'Số 1024 Nguyễn Văn Linh, P. Tân Phong, Quận 7, TP.HCM',
      city: 'TP. Hồ Chí Minh',
      latitude: 10.7290,
      longitude: 106.7110,
      powerKw: 4.0,
      totalPorts: 4,
      availablePorts: 4,
      isOpen247: true,
      hasCoffee: true,
      hasServiceShop: true,
    ),
    DatChargeStation(
      id: 'hcm-05',
      name: 'Dat Charge Tân Bình - Cộng Hòa',
      address: 'Số 354 Cộng Hòa, P. 13, Q. Tân Bình, TP.HCM',
      city: 'TP. Hồ Chí Minh',
      latitude: 10.8032,
      longitude: 106.6431,
      powerKw: 2.4,
      totalPorts: 2,
      availablePorts: 1,
      isOpen247: false,
      hasCoffee: false,
    ),
    DatChargeStation(
      id: 'hcm-06',
      name: 'Dat Charge Gò Vấp - Cityland',
      address: 'Số 18 Phan Văn Trị, P. 10, Q. Gò Vấp, TP.HCM',
      city: 'TP. Hồ Chí Minh',
      latitude: 10.8315,
      longitude: 106.6712,
      powerKw: 2.4,
      totalPorts: 2,
      availablePorts: 2,
      isOpen247: true,
      hasCoffee: true,
    ),

    // HÀ NỘI
    DatChargeStation(
      id: 'hn-01',
      name: 'Dat Charge Giảng Võ - Ba Đình',
      address: 'Số 112 Giảng Võ, P. Cát Linh, Q. Đống Đa, Hà Nội',
      city: 'Hà Nội',
      latitude: 21.0285,
      longitude: 105.8234,
      powerKw: 4.0,
      totalPorts: 4,
      availablePorts: 3,
      isOpen247: true,
      hasCoffee: true,
      hasServiceShop: true,
    ),
    DatChargeStation(
      id: 'hn-02',
      name: 'Dat Charge Cầu Giấy - Duy Tân',
      address: 'Số 8 Duy Tân, P. Dịch Vọng Hậu, Q. Cầu Giấy, Hà Nội',
      city: 'Hà Nội',
      latitude: 21.0312,
      longitude: 105.7825,
      powerKw: 4.0,
      totalPorts: 3,
      availablePorts: 2,
      isOpen247: true,
      hasCoffee: true,
    ),
    DatChargeStation(
      id: 'hn-03',
      name: 'Dat Charge Long Biên - Aeon Mall',
      address: 'Số 27 Cổ Linh, P. Long Biên, Q. Long Biên, Hà Nội',
      city: 'Hà Nội',
      latitude: 21.0271,
      longitude: 105.8994,
      powerKw: 2.4,
      totalPorts: 2,
      availablePorts: 1,
      isOpen247: true,
      hasCoffee: true,
    ),
    DatChargeStation(
      id: 'hn-04',
      name: 'Dat Charge Thanh Xuân - Royal City',
      address: 'Số 72A Nguyễn Trãi, P. Thượng Đình, Q. Thanh Xuân, Hà Nội',
      city: 'Hà Nội',
      latitude: 21.0028,
      longitude: 105.8152,
      powerKw: 2.4,
      totalPorts: 2,
      availablePorts: 2,
      isOpen247: true,
      hasCoffee: true,
    ),

    // ĐÀ NẴNG
    DatChargeStation(
      id: 'dn-01',
      name: 'Dat Charge Hải Châu - Nguyễn Văn Linh',
      address: 'Số 98 Nguyễn Văn Linh, P. Nam Dương, Q. Hải Châu, Đà Nẵng',
      city: 'Đà Nẵng',
      latitude: 16.0610,
      longitude: 108.2185,
      powerKw: 4.0,
      totalPorts: 3,
      availablePorts: 3,
      isOpen247: true,
      hasCoffee: true,
      hasServiceShop: true,
    ),
    DatChargeStation(
      id: 'dn-02',
      name: 'Dat Charge Sơn Trà - Biển Mỹ Khê',
      address: 'Số 256 Võ Nguyên Giáp, P. Phước Mỹ, Q. Sơn Trà, Đà Nẵng',
      city: 'Đà Nẵng',
      latitude: 16.0682,
      longitude: 108.2465,
      powerKw: 2.4,
      totalPorts: 2,
      availablePorts: 2,
      isOpen247: true,
      hasCoffee: true,
    ),

    // CÁC TỈNH THÀNH KHÁC
    DatChargeStation(
      id: 'bd-01',
      name: 'Dat Charge Thủ Dầu Một - Becamex',
      address: 'Đại lộ Bình Dương, P. Phú Hòa, TP. Thủ Dầu Một, Bình Dương',
      city: 'Bình Dương',
      latitude: 10.9805,
      longitude: 106.6742,
      powerKw: 4.0,
      totalPorts: 4,
      availablePorts: 3,
      isOpen247: true,
      hasCoffee: true,
    ),
    DatChargeStation(
      id: 'dn-03',
      name: 'Dat Charge Biên Hòa - Pegasus',
      address: 'Số 53 Võ Thị Sáu, P. Quyết Thắng, TP. Biên Hòa, Đồng Nai',
      city: 'Đồng Nai',
      latitude: 10.9521,
      longitude: 106.8203,
      powerKw: 2.4,
      totalPorts: 2,
      availablePorts: 2,
      isOpen247: true,
      hasCoffee: true,
    ),
    DatChargeStation(
      id: 'vt-01',
      name: 'Dat Charge Vũng Tàu - Bãi Sau',
      address: 'Số 115 Thùy Vân, Phường 2, TP. Vũng Tàu, Bà Rịa - Vũng Tàu',
      city: 'Vũng Tàu',
      latitude: 10.3340,
      longitude: 107.0872,
      powerKw: 2.4,
      totalPorts: 2,
      availablePorts: 2,
      isOpen247: true,
      hasCoffee: true,
    ),
    DatChargeStation(
      id: 'ct-01',
      name: 'Dat Charge Cần Thơ - Ninh Kiều',
      address: 'Số 42 Đường 30 Tháng 4, P. An Phú, Q. Ninh Kiều, Cần Thơ',
      city: 'Cần Thơ',
      latitude: 10.0335,
      longitude: 105.7794,
      powerKw: 2.4,
      totalPorts: 2,
      availablePorts: 2,
      isOpen247: true,
      hasCoffee: true,
    ),
  ];

  /// Tính khoảng cách km theo công thức Haversine giữa 2 tọa độ
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const r = 6371.0; // Bán kính trái đất km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180.0);

  /// Đánh giá xem xe có đủ pin để chạy đến trạm sạc không
  static StationReachability evaluateReachability({
    required double distanceKm,
    required double kmLeft,
  }) {
    if (kmLeft >= distanceKm * 1.25) {
      return StationReachability.safe;
    } else if (kmLeft >= distanceKm) {
      return StationReachability.tight;
    } else {
      return StationReachability.unreachable;
    }
  }

  /// Phân tích dữ liệu sạc chi tiết từ ChargerLogMsg và Telemetry
  static ChargingStatusReport analyzeCharging({
    BikeLogMsg? telemetry,
    int targetLimit = 80,
  }) {
    final charger = telemetry?.charging;
    final isCharging = charger != null || (telemetry != null && telemetry.phase < -0.5);

    final power = charger?.power ?? (isCharging && telemetry != null && telemetry.voltage > 0 ? (telemetry.voltage * telemetry.phase.abs()).round() : 0);
    final vin = charger?.vinRms.toDouble() ?? 220.0;
    final isGridUnstable = isCharging && (vin < 190.0 || vin > 255.0);
    final fetTemp = charger?.fetTemp ?? 36;
    final isFetHot = fetTemp > 65;

    final stage = charger?.stage ?? (isCharging ? 2 : 0);
    final stageName = switch (stage) {
      0 => 'Chưa cắm sạc',
      1 => 'Khởi động nguồn sạc',
      2 => 'Sạc nhanh Boost (Dòng không đổi CC)',
      3 => 'Sạc bảo vệ (Điện áp không đổi CV)',
      4 => 'Đã sạc đầy 100% (Trickle)',
      5 => 'Ngắt an toàn / Lỗi sạc',
      _ => 'Đang sạc',
    };

    final profileName = switch (charger?.profile ?? 0) {
      1 => 'Dat Charge Siêu Tốc (SuperBoost 4kW)',
      2 => 'Sạc chậm bảo vệ pin (Eco Night)',
      _ => 'Sạc tiêu chuẩn (Standard 1.2kW - 2.4kW)',
    };

    final currentPercent = telemetry?.percent ?? 0;
    final totalEtaSec = charger?.etaSec ?? _estimateEtaSeconds(currentPercent, 100, power);
    final eta80Sec = _estimateEtaSeconds(currentPercent, targetLimit, power);
    final boostSec = charger?.boostLeftSec ?? 0;

    // Ước tính kWh đã nạp
    final energyKwh = (power > 0 && charger != null)
        ? (power * charger.stageSec) / 3600000.0
        : 0.0;

    return ChargingStatusReport(
      isCharging: isCharging,
      stageName: stageName,
      stage: stage,
      powerWatts: power,
      gridVoltageRms: vin,
      isGridUnstable: isGridUnstable,
      fetTemp: fetTemp,
      isFetOverheat: isFetHot,
      etaTotal: Duration(seconds: max(0, totalEtaSec)),
      eta80: Duration(seconds: max(0, eta80Sec)),
      boostRemaining: Duration(seconds: max(0, boostSec)),
      profileName: profileName,
      energyChargedKwh: energyKwh,
      targetSocLimit: targetLimit,
    );
  }

  static int _estimateEtaSeconds(int currentPct, int targetPct, int powerWatts) {
    if (currentPct >= targetPct) return 0;
    // Pack pin Dat Bike Quantum: ~7.2 kWh (7200 Wh), Weaver++: ~5.0 kWh (5000 Wh)
    // Giả định pack chuẩn 7.0 kWh = 7000 Wh. 1% = 70 Wh.
    final pwr = powerWatts > 200 ? powerWatts : 1200;
    final neededPct = targetPct - currentPct;
    final neededWh = neededPct * 70.0;
    // Hiệu suất sạc ~92%
    final hours = (neededWh / (pwr * 0.92));
    return (hours * 3600).round();
  }

  /// Mở Google Maps chỉ đường tới trạm sạc
  static Future<bool> launchGoogleMaps(double lat, double lng, String label) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    try {
      final res = await _channel.invokeMethod<bool>('openMap', {'url': url});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
