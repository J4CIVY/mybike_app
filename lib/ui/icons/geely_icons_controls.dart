part of '../geely_icons.dart';

class _ClockPainter extends _BaseGeelyPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = createStroke(w * 0.085);

    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.40, stroke);

    canvas.drawLine(
      Offset(w * 0.5, h * 0.5),
      Offset(w * 0.72, h * 0.5),
      stroke,
    );

    canvas.drawLine(
      Offset(w * 0.5, h * 0.5),
      Offset(w * 0.5, h * 0.24),
      stroke,
    );

    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.05, createFill());
  }
}

class _TrunkPainter extends _BaseGeelyPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = createStroke(w * 0.085);

    final base = Path()
      ..moveTo(w * 0.15, h * 0.56)
      ..lineTo(w * 0.22, h * 0.82)
      ..lineTo(w * 0.78, h * 0.82)
      ..lineTo(w * 0.85, h * 0.56);
    canvas.drawPath(base, stroke);

    final lid = Path()
      ..moveTo(w * 0.15, h * 0.56)
      ..lineTo(w * 0.70, h * 0.26)
      ..lineTo(w * 0.82, h * 0.32);
    canvas.drawPath(lid, stroke);

    final arrow = Path()
      ..moveTo(w * 0.46, h * 0.62)
      ..lineTo(w * 0.46, h * 0.44)
      ..moveTo(w * 0.38, h * 0.50)
      ..lineTo(w * 0.46, h * 0.42)
      ..lineTo(w * 0.54, h * 0.50);
    canvas.drawPath(arrow, createStroke(w * 0.075));
  }
}

class _FanPainter extends _BaseGeelyPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = createStroke(w * 0.08);

    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.12, stroke);

    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.save();
      canvas.translate(w * 0.5, h * 0.5);
      canvas.rotate(angle);

      final blade = Path()
        ..moveTo(0, -w * 0.12)
        ..quadraticBezierTo(w * 0.18, -w * 0.28, w * 0.06, -w * 0.42)
        ..quadraticBezierTo(-w * 0.10, -w * 0.32, 0, -w * 0.12);
      canvas.drawPath(blade, stroke);

      canvas.restore();
    }
  }
}

class _BikePainter extends _BaseGeelyPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = createStroke(w * 0.08);

    canvas.drawCircle(Offset(w * 0.24, h * 0.68), w * 0.16, stroke);
    canvas.drawCircle(Offset(w * 0.76, h * 0.68), w * 0.16, stroke);

    final frame = Path()
      ..moveTo(w * 0.24, h * 0.68)
      ..lineTo(w * 0.46, h * 0.52)
      ..lineTo(w * 0.66, h * 0.34)
      ..lineTo(w * 0.76, h * 0.68)
      ..moveTo(w * 0.46, h * 0.52)
      ..lineTo(w * 0.42, h * 0.38)
      ..lineTo(w * 0.32, h * 0.38)
      ..moveTo(w * 0.66, h * 0.34)
      ..lineTo(w * 0.60, h * 0.24);
    canvas.drawPath(frame, stroke);
  }
}

class _BatteryPainter extends _BaseGeelyPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = createStroke(w * 0.08);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.28, w * 0.70, h * 0.44),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(body, stroke);

    final tip = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.84, h * 0.40, w * 0.06, h * 0.20),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(tip, createFill());

    final barW = w * 0.12;
    final barH = h * 0.26;
    for (int i = 0; i < 3; i++) {
      final barRect = Rect.fromLTWH(
        w * 0.22 + i * (barW + w * 0.06),
        h * 0.37,
        barW,
        barH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, Radius.circular(w * 0.02)),
        createFill(),
      );
    }
  }
}

