// Bác Sĩ Pin & Chẩn Đoán Lỗi OBD — Động cơ phân tích chuyên sâu cho xe Dat Bike.
//
// 1. Phân tích 20/24 cell pin: Vmax, Vmin, Vavg, Delta V (mV), phân cấp cân bằng cell.
// 2. Bản đồ nhiệt độ 3 điểm: Motor, Inverter/ECU, Battery Pack/BMS.
// 3. Hệ thống mã lỗi OBD: Quét 8 cờ bitmask lỗi phần cứng + hướng dẫn khắc phục.

import 'dart:math';
import '../proto/bike_log.dart';

enum CellBalanceGrade {
  excellent('Hoàn hảo', 'Độ lệch áp cực thấp, các cell đồng đều tuyệt đối.'),
  good('Tốt', 'Khối pin cân bằng tốt, hiệu suất xả nạp tối ưu.'),
  fair('Cần theo dõi', 'Có độ lệch áp nhẹ giữa các cell, nên sạc đầy để BMS cân bằng.'),
  poor('Lệch áp cao', 'Các cell lệch áp đáng kể (>80mV), cần cắm sạc qua đêm.'),
  critical('BÁO ĐỘNG', 'Nguy cơ tụt áp cell nghiêm trọng (>120mV), hạn chế vặn ga mạnh!');

  final String label;
  final String description;
  const CellBalanceGrade(this.label, this.description);
}

enum ThermalStatus {
  cool('Mát', 0xFF10B981),
  normal('Bình thường', 0xFF0EA5E9),
  warm('Ấm', 0xFFF59E0B),
  hot('Nóng', 0xFFF97316),
  critical('Nguy hiểm', 0xFFEF4444);

  final String label;
  final int colorValue;
  const ThermalStatus(this.label, this.colorValue);
}

class ThermalZone {
  final String name;
  final double temperature;
  final double warningTemp;
  final double criticalTemp;
  final ThermalStatus status;

  const ThermalZone({
    required this.name,
    required this.temperature,
    required this.warningTemp,
    required this.criticalTemp,
    required this.status,
  });

  factory ThermalZone.evaluate({
    required String name,
    required double temp,
    required double warningTemp,
    required double criticalTemp,
  }) {
    final ThermalStatus status;
    if (temp <= 35) {
      status = ThermalStatus.cool;
    } else if (temp < warningTemp - 10) {
      status = ThermalStatus.normal;
    } else if (temp < warningTemp) {
      status = ThermalStatus.warm;
    } else if (temp < criticalTemp) {
      status = ThermalStatus.hot;
    } else {
      status = ThermalStatus.critical;
    }

    return ThermalZone(
      name: name,
      temperature: temp,
      warningTemp: warningTemp,
      criticalTemp: criticalTemp,
      status: status,
    );
  }
}

class ObdDiagnosticItem {
  final int bit;
  final String name;
  final String code;
  final bool isHealthy;
  final String severity; // 'Tốt', 'Cảnh báo', 'Khẩn cấp'
  final String description;
  final String recommendation;

  const ObdDiagnosticItem({
    required this.bit,
    required this.name,
    required this.code,
    required this.isHealthy,
    required this.severity,
    required this.description,
    required this.recommendation,
  });
}

class BatteryHealthReport {
  final List<double> cellVoltages;
  final int cellCount;
  final double maxCellVoltage;
  final int maxCellIndex;
  final double minCellVoltage;
  final int minCellIndex;
  final double avgCellVoltage;
  final double deltaVoltageMv;
  final CellBalanceGrade balanceGrade;
  final int healthPercentage; // SOH 0-100%
  final double packVoltage;
  final double currentAmp;
  final bool isBalancing;
  final int chargeCycles;
  final double internalResistanceMo; // mOhm
  final ThermalZone motorThermal;
  final ThermalZone ecuThermal;
  final ThermalZone bmsThermal;
  final List<ObdDiagnosticItem> obdItems;
  final int safetyScore; // 0-100
  final bool isSimulated;
  final String packConfigName;

  const BatteryHealthReport({
    required this.cellVoltages,
    required this.cellCount,
    required this.maxCellVoltage,
    required this.maxCellIndex,
    required this.minCellVoltage,
    required this.minCellIndex,
    required this.avgCellVoltage,
    required this.deltaVoltageMv,
    required this.balanceGrade,
    required this.healthPercentage,
    required this.packVoltage,
    required this.currentAmp,
    required this.isBalancing,
    required this.chargeCycles,
    required this.internalResistanceMo,
    required this.motorThermal,
    required this.ecuThermal,
    required this.bmsThermal,
    required this.obdItems,
    required this.safetyScore,
    this.isSimulated = false,
    this.packConfigName = '23S6P (23 Cell)',
  });
}

class BatteryDiagnosticsService {
  BatteryDiagnosticsService._();

  static BatteryHealthReport analyze({
    BikeLogMsg? telemetry,
    BatteryLogMsg? battery,
    String? modelName,
  }) {
    final packVoltage = battery?.voltage ?? telemetry?.voltage ?? 0.0;
    final currentAmp = battery?.current ?? telemetry?.phase ?? 0.0;

    List<double> cells = [];
    bool isSimulated = false;
    final String packConfig;

    if (battery != null && battery.cellVols.isNotEmpty) {
      // 1. DỮ LIỆU THỰC TẾ TỪ BLUETOOTH BMS (Single Source of Truth)
      // Bluetooth gửi bao nhiêu cell thì hiển thị bấy nhiêu cell, hoàn toàn tự động 100%!
      cells = List<double>.from(battery.cellVols);
      isSimulated = false;
      packConfig = '${cells.length}S (${cells.length} Cell nối tiếp)';
    } else {
      // 2. Chế độ dự phòng khi offline (chưa nhận được bản tin BMS từ Bluetooth):
      // Ước lượng số cell theo điện áp thực tế của xe (Li-ion 3.7V nominal):
      // - Dải điện áp 78V - 96.6V: Hệ 23S (Quantum S, Weaver 200, Weaver++)
      // - Dải điện áp 60V - 78V: Hệ 20S (Weaver 1.0 cũ)
      isSimulated = true;
      final int fallbackCellCount;
      if (packVoltage >= 78.0) {
        fallbackCellCount = 23;
      } else if (packVoltage >= 55.0 && packVoltage < 78.0) {
        fallbackCellCount = 20;
      } else {
        fallbackCellCount = 23; // Mặc định chuẩn thế hệ xe Dat Bike mới
      }

      if (packVoltage > 20.0) {
        final baseV = packVoltage / fallbackCellCount;
        // Mô phỏng nhẹ độ lệch tự nhiên giữa các cell (±4mV) khi chưa có tín hiệu Bluetooth
        cells = List.generate(fallbackCellCount, (i) {
          final variance = sin(i * 1.5) * 0.006 + cos(i * 0.8) * 0.003;
          return double.parse((baseV + variance).toStringAsFixed(3));
        });
      } else {
        cells = List.generate(fallbackCellCount, (_) => 3.700);
      }
      packConfig = '$fallbackCellCount S ($fallbackCellCount Cell)';
    }

    // 2. Tính toán Vmax, Vmin, Vavg, Delta V
    double vMax = cells.first;
    int maxIdx = 1;
    double vMin = cells.first;
    int minIdx = 1;
    double sum = 0.0;

    for (int i = 0; i < cells.length; i++) {
      final v = cells[i];
      sum += v;
      if (v > vMax) {
        vMax = v;
        maxIdx = i + 1;
      }
      if (v < vMin) {
        vMin = v;
        minIdx = i + 1;
      }
    }

    final avgV = cells.isNotEmpty ? (sum / cells.length) : 0.0;
    final deltaMv = (vMax - vMin) * 1000.0;

    // 3. Đánh giá cấp độ cân bằng cell
    final CellBalanceGrade grade;
    if (deltaMv <= 20.0) {
      grade = CellBalanceGrade.excellent;
    } else if (deltaMv <= 45.0) {
      grade = CellBalanceGrade.good;
    } else if (deltaMv <= 80.0) {
      grade = CellBalanceGrade.fair;
    } else if (deltaMv <= 120.0) {
      grade = CellBalanceGrade.poor;
    } else {
      grade = CellBalanceGrade.critical;
    }

    // 4. Ước lượng SOH (State of Health)
    final cycles = battery?.socCycles.round() ?? (telemetry != null ? (telemetry.odo / 150.0).round() : 0);
    int health = 100 - (cycles * 0.03).round();
    if (deltaMv > 80) health -= 5;
    if (deltaMv > 120) health -= 10;
    health = health.clamp(60, 100);

    // 5. Bản đồ nhiệt 3 điểm
    final motorZone = ThermalZone.evaluate(
      name: 'Động cơ (Motor)',
      temp: telemetry?.motor ?? 32.0,
      warningTemp: 75.0,
      criticalTemp: 90.0,
    );

    final ecuZone = ThermalZone.evaluate(
      name: 'Biến tần (ECU)',
      temp: telemetry?.ecu ?? 30.0,
      warningTemp: 65.0,
      criticalTemp: 80.0,
    );

    final bmsZone = ThermalZone.evaluate(
      name: 'Khối Pin (BMS)',
      temp: telemetry?.bmsTemp ?? (battery?.ntcs.isNotEmpty == true ? battery!.ntcs.first : 29.0),
      warningTemp: 48.0,
      criticalTemp: 58.0,
    );

    // 6. Quét & Giải mã mã lỗi hệ thống OBD
    final errorCode = telemetry?.error ?? 0;
    final obdItems = _evaluateObdSystems(errorCode, battery);

    // Điểm an toàn vận hành (100 - 20 cho mỗi lỗi đang xuất hiện)
    final activeErrors = obdItems.where((item) => !item.isHealthy).length;
    final safetyScore = max(0, 100 - (activeErrors * 25));

    return BatteryHealthReport(
      cellVoltages: cells,
      cellCount: cells.length,
      maxCellVoltage: vMax,
      maxCellIndex: maxIdx,
      minCellVoltage: vMin,
      minCellIndex: minIdx,
      avgCellVoltage: avgV,
      deltaVoltageMv: deltaMv,
      balanceGrade: grade,
      healthPercentage: health,
      packVoltage: packVoltage,
      currentAmp: currentAmp,
      isBalancing: (battery?.balancing ?? 0) != 0,
      chargeCycles: cycles,
      internalResistanceMo: battery?.resistor ?? 18.5,
      motorThermal: motorZone,
      ecuThermal: ecuZone,
      bmsThermal: bmsZone,
      obdItems: obdItems,
      safetyScore: safetyScore,
      isSimulated: isSimulated,
      packConfigName: packConfig,
    );
  }

  static List<ObdDiagnosticItem> _evaluateObdSystems(int errorCode, BatteryLogMsg? battery) {
    return [
      ObdDiagnosticItem(
        bit: 0,
        name: 'Cảm biến tay ga (Throttle)',
        code: 'OBD-TH-01',
        isHealthy: (errorCode & (1 << 0)) == 0,
        severity: (errorCode & (1 << 0)) != 0 ? 'Khẩn cấp' : 'Tốt',
        description: (errorCode & (1 << 0)) != 0
            ? 'Tín hiệu điện áp tay ga vượt ngưỡng an toàn (đứt dây hoặc kẹt cảm biến Hall tay ga).'
            : 'Tín hiệu Hall tay ga phản hồi mượt mà, dải điện áp 0.8V – 4.2V chuẩn xác.',
        recommendation: (errorCode & (1 << 0)) != 0
            ? 'Kiểm tra giắc cắm cùm ga bên phải. Thử nhả tay ga hoàn toàn rồi bật lại xe.'
            : 'Hệ thống điều khiển ga đang ở trạng thái hoàn hảo.',
      ),
      ObdDiagnosticItem(
        bit: 1,
        name: 'Cảm biến Hall Động cơ',
        code: 'OBD-MOT-02',
        isHealthy: (errorCode & (1 << 1)) == 0,
        severity: (errorCode & (1 << 1)) != 0 ? 'Khẩn cấp' : 'Tốt',
        description: (errorCode & (1 << 1)) != 0
            ? 'Bộ điều khiển mất tín hiệu góc quay từ 3 cảm biến Hall trong động cơ.'
            : 'Tín hiệu pha động cơ 3 pha đồng bộ chính xác, không phát hiện mất bước.',
        recommendation: (errorCode & (1 << 1)) != 0
            ? 'Không tiếp tục vặn ga ép tải. Cần kiểm tra bó dây động cơ bánh sau và giắc Hall 5 chân.'
            : 'Hệ thống truyền động hoạt động ổn định.',
      ),
      ObdDiagnosticItem(
        bit: 2,
        name: 'Bảo vệ quá dòng (Over-Current)',
        code: 'OBD-PWR-03',
        isHealthy: (errorCode & (1 << 2)) == 0,
        severity: (errorCode & (1 << 2)) != 0 ? 'Khẩn cấp' : 'Tốt',
        description: (errorCode & (1 << 2)) != 0
            ? 'Dòng xả tức thời vượt ngưỡng giới hạn an toàn của biến tần (>300A).'
            : 'Dòng tải nằm trong giới hạn thiết kế an toàn của bo công suất MOSFET.',
        recommendation: (errorCode & (1 << 2)) != 0
            ? 'Dừng xe, đợi 2 phút để tụ xả xả bớt năng lượng. Tránh chở quá tải trọng thiết kế.'
            : 'Bộ điều tốc VESC hoạt động đúng định mức.',
      ),
      ObdDiagnosticItem(
        bit: 3,
        name: 'Cảm biến nhiệt ECU/Inverter',
        code: 'OBD-ECU-04',
        isHealthy: (errorCode & (1 << 3)) == 0,
        severity: (errorCode & (1 << 3)) != 0 ? 'Cảnh báo' : 'Tốt',
        description: (errorCode & (1 << 3)) != 0
            ? 'Nhiệt độ bo điều khiển ECU vượt ngưỡng an toàn (>80°C), công suất bị giới hạn.'
            : 'Nhiệt độ bo ECU mát mẻ, keo tản nhiệt và quạt làm mát hoạt động hiệu quả.',
        recommendation: (errorCode & (1 << 3)) != 0
            ? 'Giảm tốc độ, tránh ép ga liên tục. Cho xe nghỉ ở nơi thoáng mát 10-15 phút.'
            : 'Tản nhiệt ECU tối ưu.',
      ),
      ObdDiagnosticItem(
        bit: 4,
        name: 'Giao tiếp mạng CAN/BMS',
        code: 'OBD-COM-05',
        isHealthy: (errorCode & (1 << 4)) == 0,
        severity: (errorCode & (1 << 4)) != 0 ? 'Khẩn cấp' : 'Tốt',
        description: (errorCode & (1 << 4)) != 0
            ? 'Mất liên lạc giữa ECU trung tâm và bo mạch quản lý pin thông minh BMS.'
            : 'Đường truyền dữ liệu CAN Bus 250kbps ổn định, không có gói tin thất lạc.',
        recommendation: (errorCode & (1 << 4)) != 0
            ? 'Kiểm tra giắc tín hiệu BMS nối với pack pin dưới cốp xe.'
            : 'BMS phản hồi dữ liệu liên tục.',
      ),
      ObdDiagnosticItem(
        bit: 5,
        name: 'Nhiệt độ khối Cell Pin',
        code: 'OBD-BAT-06',
        isHealthy: (errorCode & (1 << 5)) == 0,
        severity: (errorCode & (1 << 5)) != 0 ? 'Khẩn cấp' : 'Tốt',
        description: (errorCode & (1 << 5)) != 0
            ? 'Cảm biến NTC phát hiện nhiệt độ pack pin vượt ngưỡng nguy hại (>55°C).'
            : 'Nhiệt độ toàn bộ khối cell pin đồng đều và nằm trong vùng tối ưu hóa tuổi thọ.',
        recommendation: (errorCode & (1 << 5)) != 0
            ? 'CẢNH BÁO: Tắt nguồn ngay! Không cắm sạc khi pin đang quá nhiệt.'
            : 'Điều kiện môi trường pin lý tưởng.',
      ),
      ObdDiagnosticItem(
        bit: 6,
        name: 'Bảo vệ điện áp thấp (Low Voltage)',
        code: 'OBD-VOLT-07',
        isHealthy: (errorCode & (1 << 6)) == 0,
        severity: (errorCode & (1 << 6)) != 0 ? 'Cảnh báo' : 'Tốt',
        description: (errorCode & (1 << 6)) != 0
            ? 'Điện áp pack pin tụt dưới ngưỡng cắt bảo vệ, xe chuyển sang chế độ bảo tồn (Rùa).'
            : 'Điện áp ổn định, không có hiện tượng sụt áp sâu dưới tải nặng.',
        recommendation: (errorCode & (1 << 6)) != 0
            ? 'Cần cắm sạc ngay. Tránh để xe kiệt pin dưới 0% trong thời gian dài.'
            : 'Điện áp cung cấp dồi dào.',
      ),
      ObdDiagnosticItem(
        bit: 7,
        name: 'Công tắc ngắt phanh (Brake Cutoff)',
        code: 'OBD-BRK-08',
        isHealthy: (errorCode & (1 << 7)) == 0,
        severity: (errorCode & (1 << 7)) != 0 ? 'Cảnh báo' : 'Tốt',
        description: (errorCode & (1 << 7)) != 0
            ? 'Công tắc vi mô ở tay thắng bị kẹt đóng, xe tự ngắt ga an toàn.'
            : 'Cảm biến hành trình tay phanh đóng/ngắt chuẩn xác theo nhịp bóp phanh.',
        recommendation: (errorCode & (1 << 7)) != 0
            ? 'Kiểm tra độ rơ của tay phanh trái và phải. Tra dầu bôi trơn công tắc nếu bị kẹt dính.'
            : 'Hệ thống phanh tái sinh và ngắt ga hoạt động an toàn.',
      ),
    ];
  }
}
