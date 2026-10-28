import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart' show TripGpsPoint;

class TripRouteBikeMarker extends StatelessWidget {
  final TripGpsPoint point;
  final double heading;
  final bool useNavPuckMarker;
  final VoidCallback onToggleMarkerStyle;

  const TripRouteBikeMarker({
    super.key,
    required this.point,
    required this.heading,
    required this.useNavPuckMarker,
    required this.onToggleMarkerStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isMoving = point.speedKmh > 1.0;

    return GestureDetector(
      onTap: onToggleMarkerStyle,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (useNavPuckMarker) ...[
            Transform.rotate(
              angle: heading,
              child: SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(88, 88),
                      painter: HeadlightBeamPainter(),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isMoving ? const Color(0x600284C7) : const Color(0x352563EB),
                            blurRadius: isMoving ? 14 : 8,
                            spreadRadius: isMoving ? 3 : 1,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        ),
                        border: Border.all(
                          color: const Color(0xFF38BDF8),
                          width: 2.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.navigation_rounded,
                          color: Color(0xFF38BDF8),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x502563EB),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/bike_logo_3d.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.two_wheeler_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
          Positioned(
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xF20F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isMoving ? const Color(0x6638BDF8) : const Color(0x3394A3B8),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 11,
                    color: isMoving ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${point.speedKmh.toStringAsFixed(0)} km/h',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeadlightBeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - 24, center.dy - 42)
      ..arcToPoint(
        Offset(center.dx + 24, center.dy - 42),
        radius: const Radius.circular(36),
      )
      ..close();

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.1),
        radius: 0.85,
        colors: const [
          Color(0x6638BDF8),
          Color(0x2638BDF8),
          Color(0x0038BDF8),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 46));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
