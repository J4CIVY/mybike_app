part of '../geely_icons.dart';

class _IconWrapper extends StatelessWidget {
  final double size;
  final Color? color;
  final CustomPainter painter;

  const _IconWrapper({
    required this.size,
    required this.painter,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? IconTheme.of(context).color ?? Colors.white;
    return CustomPaint(
      size: Size(size, size),
      painter: _ColorAwarePainter(painter: painter, color: iconColor),
    );
  }
}

class _ColorAwarePainter extends CustomPainter {
  final CustomPainter painter;
  final Color color;

  _ColorAwarePainter({required this.painter, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (painter is _BaseGeelyPainter) {
      (painter as _BaseGeelyPainter).color = color;
    }
    painter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _ColorAwarePainter oldDelegate) =>
      color != oldDelegate.color;
}

abstract class _BaseGeelyPainter extends CustomPainter {
  Color color = Colors.white;

  Paint createStroke(double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint createFill() => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LockPainter extends _BaseGeelyPainter {
  final bool isOpen;
  _LockPainter({required this.isOpen});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = createStroke(w * 0.085);

    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.42, w * 0.64, h * 0.48),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(bodyRRect, stroke);

    final fill = createFill();
    canvas.drawCircle(Offset(w * 0.5, h * 0.61), w * 0.05, fill);
    final keyholePath = Path()
      ..moveTo(w * 0.47, h * 0.62)
      ..lineTo(w * 0.53, h * 0.62)
      ..lineTo(w * 0.52, h * 0.74)
      ..lineTo(w * 0.48, h * 0.74)
      ..close();
    canvas.drawPath(keyholePath, fill);

    final shacklePath = Path();
    if (!isOpen) {
      shacklePath.moveTo(w * 0.32, h * 0.42);
      shacklePath.lineTo(w * 0.32, h * 0.26);
      shacklePath.arcToPoint(
        Offset(w * 0.68, h * 0.26),
        radius: Radius.circular(w * 0.18),
      );
      shacklePath.lineTo(w * 0.68, h * 0.42);
    } else {
      shacklePath.moveTo(w * 0.32, h * 0.42);
      shacklePath.lineTo(w * 0.32, h * 0.22);
      shacklePath.arcToPoint(
        Offset(w * 0.68, h * 0.22),
        radius: Radius.circular(w * 0.18),
      );
      shacklePath.lineTo(w * 0.68, h * 0.30);
    }
    canvas.drawPath(shacklePath, stroke);
  }
}

class _FindBikePainter extends _BaseGeelyPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = createStroke(w * 0.085);

    final hornPath = Path()
      ..moveTo(w * 0.12, h * 0.38)
      ..lineTo(w * 0.28, h * 0.38)
      ..lineTo(w * 0.52, h * 0.18)
      ..lineTo(w * 0.52, h * 0.82)
      ..lineTo(w * 0.28, h * 0.62)
      ..lineTo(w * 0.12, h * 0.62)
      ..close();
    canvas.drawPath(hornPath, stroke);

    final wave1 = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(w * 0.48, h * 0.5), radius: w * 0.20),
        -math.pi / 4,
        math.pi / 2,
      );
    canvas.drawPath(wave1, stroke);

    final wave2 = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(w * 0.48, h * 0.5), radius: w * 0.34),
        -math.pi / 4,
        math.pi / 2,
      );
    canvas.drawPath(wave2, stroke);
  }
}

class _ChargingBoltPainter extends _BaseGeelyPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = createStroke(w * 0.085);

    final path = Path()
      ..moveTo(w * 0.58, h * 0.08)
      ..lineTo(w * 0.26, h * 0.52)
      ..lineTo(w * 0.48, h * 0.52)
      ..lineTo(w * 0.38, h * 0.92)
      ..lineTo(w * 0.74, h * 0.44)
      ..lineTo(w * 0.52, h * 0.44)
      ..close();

    canvas.drawPath(path, stroke);
  }
}

