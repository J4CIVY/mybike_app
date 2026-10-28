part of '../geely_icons.dart';

class _SpeedometerPainter extends _BaseGeelyPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = createStroke(w * 0.085);

    final arcRect = Rect.fromCircle(
      center: Offset(w * 0.5, h * 0.54),
      radius: w * 0.38,
    );
    canvas.drawArc(arcRect, math.pi * 0.75, math.pi * 1.5, false, stroke);

    final needle = Path()
      ..moveTo(w * 0.5, h * 0.54)
      ..lineTo(w * 0.68, h * 0.34);
    canvas.drawPath(needle, stroke);

    canvas.drawCircle(Offset(w * 0.5, h * 0.54), w * 0.06, createFill());
  }
}

class _ShieldPainter extends _BaseGeelyPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = createStroke(w * 0.085);

    final shield = Path()
      ..moveTo(w * 0.5, h * 0.10)
      ..lineTo(w * 0.84, h * 0.24)
      ..quadraticBezierTo(w * 0.84, h * 0.62, w * 0.5, h * 0.90)
      ..quadraticBezierTo(w * 0.16, h * 0.62, w * 0.16, h * 0.24)
      ..close();
    canvas.drawPath(shield, stroke);

    final check = Path()
      ..moveTo(w * 0.36, h * 0.48)
      ..lineTo(w * 0.46, h * 0.58)
      ..lineTo(w * 0.64, h * 0.38);
    canvas.drawPath(check, stroke);
  }
}

class _NfcPainter extends _BaseGeelyPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = createStroke(w * 0.085);

    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.18, w * 0.76, h * 0.64),
      Radius.circular(w * 0.10),
    );
    canvas.drawRRect(card, stroke);

    for (int i = 1; i <= 3; i++) {
      final r = w * (0.08 + i * 0.09);
      final wave = Path()
        ..addArc(
          Rect.fromCircle(center: Offset(w * 0.35, h * 0.50), radius: r),
          -math.pi * 0.35,
          math.pi * 0.70,
        );
      canvas.drawPath(wave, createStroke(w * 0.07));
    }
  }
}

class _SettingsPainter extends _BaseGeelyPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = createStroke(w * 0.085);
    final fill = createFill();

    canvas.drawLine(Offset(w * 0.14, h * 0.34), Offset(w * 0.86, h * 0.34), stroke);
    canvas.drawCircle(Offset(w * 0.38, h * 0.34), w * 0.09, fill);

    canvas.drawLine(Offset(w * 0.14, h * 0.66), Offset(w * 0.86, h * 0.66), stroke);
    canvas.drawCircle(Offset(w * 0.62, h * 0.66), w * 0.09, fill);
  }
}

class _ProfilePainter extends _BaseGeelyPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = createStroke(w * 0.085);

    canvas.drawCircle(Offset(w * 0.5, h * 0.34), w * 0.18, stroke);

    final body = Path()
      ..moveTo(w * 0.20, h * 0.82)
      ..quadraticBezierTo(w * 0.26, h * 0.60, w * 0.5, h * 0.60)
      ..quadraticBezierTo(w * 0.74, h * 0.60, w * 0.80, h * 0.82);
    canvas.drawPath(body, stroke);
  }
}

