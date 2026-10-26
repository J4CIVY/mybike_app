// Screen 2: Power Control (Charging) — Chuyên biệt hóa cho Xe Máy Điện Dat Bike
// Thiết kế tham chiếu Geely EV nhưng tinh chỉnh 100% chuẩn sạc xe máy điện:
// - Quãng đường tiêu chuẩn: 270 km ở trên (font rộng).
// - Trung tâm: Xe máy điện 3D X-ray trong suốt lộ khối pin Li-ion xanh lá 34% (hoặc đồng bộ pin).
// - 2 chỉ báo trạng thái: 🟢 Đã cắm sạc an toàn · 🔵 Cổng sạc nhanh Dat Charge.
// - Bottom card Charging Details liệt kê thông số sạc thực tế xe máy điện:
//     + Remaining Time: 35 phút (đến 100% pin)
//     + Current: [DC] 3.3 kW · 45 A · 76.8 V (chuẩn pin 72V Li-ion Dat Bike)
//     + Estimated Range After Charging: 270 km
//     + Nút Stop màu xanh dương full-width.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ble/ble_controller.dart';

class ChargingScreen extends ConsumerStatefulWidget {
  const ChargingScreen({super.key});

  @override
  ConsumerState<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends ConsumerState<ChargingScreen> {
  bool _isCharging = true;

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);
    final telemetry = ble.lastTelemetry;
    final percent = telemetry?.percent ?? 68;
    final voltage = telemetry?.voltage ?? 76.8;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'Power Control',
          style: GoogleFonts.syne(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // ══════════════════════════════════════════════════════════════
              // 1. HIỂN THỊ 270 km Ở TRÊN (Quãng đường tiêu chuẩn đầy pin Dat Bike)
              // ══════════════════════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '270',
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

              const SizedBox(height: 18),

              // ══════════════════════════════════════════════════════════════
              // 2. TRUNG TÂM: XE MÁY ĐIỆN 3D HIỆU ỨNG TRONG SUỐT (X-RAY)
              //    Lộ khối pin Li-ion xanh lá
              // ══════════════════════════════════════════════════════════════
              Container(
                width: double.infinity,
                height: 235,
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
                    // Ảnh X-Ray xe máy điện Dat Bike
                    Image.asset(
                      'assets/images/bike_xray.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.bolt_rounded, size: 80, color: Color(0xFF10B981)),
                      ),
                    ),

                    // Khối Pin xanh lá hiển thị trực tiếp chuẩn mẫu ảnh Power Control
                    Positioned(
                      bottom: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xE622C55E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x6622C55E),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 8,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 1.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 4.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$percent%',
                              style: GoogleFonts.syne(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ══════════════════════════════════════════════════════════════
              // 3. TRẠNG THÁI KẾT NỐI SẠC XE MÁY ĐIỆN THỰC TẾ
              //    - 🟢 Đã cắm nguồn sạc an toàn
              //    - 🔵 Cổng sạc siêu tốc Dat Charge (hoặc Sạc gia đình 220V)
              // ══════════════════════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statusBullet(
                    color: _isCharging ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                    label: _isCharging ? 'Đã cắm sạc an toàn' : 'Chưa kết nối nguồn',
                  ),
                  const SizedBox(width: 18),
                  _statusBullet(
                    color: const Color(0xFF2563EB),
                    label: 'Cổng sạc nhanh Dat Charge',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ══════════════════════════════════════════════════════════════
              // 4. BOTTOM CARD: CHARGING DETAILS (Thông số xe máy điện thực tế)
              //    - Remaining Time: 35 phút (đến 100%)
              //    - Current: [DC] 3.3 kW · 45 A · 76.8 V (Pin 72V)
              //    - Estimated Range After Charging: 270 km
              //    - Full-width Button: Stop (xanh dương)
              // ══════════════════════════════════════════════════════════════
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
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
                    // Tiêu đề Charging Details
                    Text(
                      'Charging Details',
                      style: GoogleFonts.syne(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Hàng 1: Remaining Time  35 phút
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remaining Time',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          _isCharging ? '35 phút' : '---',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Color(0xFFF1F5F9), height: 26, thickness: 1),

                    // Hàng 2: Current   [DC] 3.3 kW · 45 A · 76.8 V (Pin 72V)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Row(
                          children: [
                            // Badge DC xanh nhạt (chuẩn sạc pin xe máy điện)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'DC',
                                style: GoogleFonts.syne(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                            Text(
                              _isCharging ? '3.3 kW · 45 A · ${voltage.toStringAsFixed(1)} V' : '0.0 kW · 0 A · ${voltage.toStringAsFixed(1)} V',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(color: Color(0xFFF1F5F9), height: 26, thickness: 1),

                    // Hàng 3: Estimated Range After Charging   270 km
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimated Range\nAfter Charging',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '270',
                              style: GoogleFonts.syne(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'km',
                              style: GoogleFonts.syne(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Hàng 4: Nút Stop màu xanh dương full-width
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCharging ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          setState(() => _isCharging = !_isCharging);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isCharging ? 'Đã kích hoạt sạc pin an toàn' : 'Đã ngắt phiên sạc pin an toàn',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        child: Text(
                          _isCharging ? 'Stop' : 'Start Charging',
                          style: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBullet({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
