import 'package:flutter/material.dart';

/// Authentic Apple Face ID vector glyph
class FaceIdIcon extends StatelessWidget {
  final double size;
  final Color color;

  const FaceIdIcon({
    super.key,
    this.size = 24,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FaceIdPainter(color: color),
    );
  }
}

class _FaceIdPainter extends CustomPainter {
  final Color color;

  _FaceIdPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cornerLen = w * 0.26;
    final radius = w * 0.14;

    // 1. Top-Left Bracket
    final tlPath = Path()
      ..moveTo(cornerLen, 0)
      ..lineTo(radius, 0)
      ..quadraticBezierTo(0, 0, 0, radius)
      ..lineTo(0, cornerLen);
    canvas.drawPath(tlPath, strokePaint);

    // 2. Top-Right Bracket
    final trPath = Path()
      ..moveTo(w - cornerLen, 0)
      ..lineTo(w - radius, 0)
      ..quadraticBezierTo(w, 0, w, radius)
      ..lineTo(w, cornerLen);
    canvas.drawPath(trPath, strokePaint);

    // 3. Bottom-Left Bracket
    final blPath = Path()
      ..moveTo(0, h - cornerLen)
      ..lineTo(0, h - radius)
      ..quadraticBezierTo(0, h, radius, h)
      ..lineTo(cornerLen, h);
    canvas.drawPath(blPath, strokePaint);

    // 4. Bottom-Right Bracket
    final brPath = Path()
      ..moveTo(w, h - cornerLen)
      ..lineTo(w, h - radius)
      ..quadraticBezierTo(w, h, w - radius, h)
      ..lineTo(w - cornerLen, h);
    canvas.drawPath(brPath, strokePaint);

    // 5. Left Eye
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.36, h * 0.36),
          width: w * 0.075,
          height: h * 0.16,
        ),
        Radius.circular(w * 0.038),
      ),
      fillPaint,
    );

    // 6. Right Eye
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.64, h * 0.36),
          width: w * 0.075,
          height: h * 0.16,
        ),
        Radius.circular(w * 0.038),
      ),
      fillPaint,
    );

    // 7. Nose (Clean vertical & hook)
    final nosePath = Path()
      ..moveTo(w * 0.50, h * 0.42)
      ..lineTo(w * 0.50, h * 0.56)
      ..lineTo(w * 0.56, h * 0.56);
    canvas.drawPath(nosePath, strokePaint..strokeWidth = size.width * 0.075);

    // 8. Mouth Curve (Minimalist subtle curve)
    final mouthPath = Path()
      ..moveTo(w * 0.33, h * 0.70)
      ..quadraticBezierTo(w * 0.50, h * 0.81, w * 0.67, h * 0.70);
    canvas.drawPath(mouthPath, strokePaint..strokeWidth = size.width * 0.075);
  }

  @override
  bool shouldRepaint(covariant _FaceIdPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Dynamic biometric icon that chooses between authentic Face ID glyph and Fingerprint icon
class DynamicBiometricIcon extends StatelessWidget {
  final double size;
  final Color color;
  final String? biometricLabel;

  const DynamicBiometricIcon({
    super.key,
    this.size = 26,
    required this.color,
    this.biometricLabel,
  });

  @override
  Widget build(BuildContext context) {
    final label = biometricLabel ?? 'Biometrics';
    if (label.contains('Face')) {
      return FaceIdIcon(size: size, color: color);
    }
    return Icon(Icons.fingerprint_rounded, size: size + 2, color: color);
  }
}
