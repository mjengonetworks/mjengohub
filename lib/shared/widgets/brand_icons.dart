// lib/shared/widgets/brand_icons.dart
//
// Hand-drawn brand silhouettes for the 6 required social platforms (X,
// LinkedIn, Facebook, Instagram, YouTube, WhatsApp) — zero new pub
// dependency. font_awesome_flutter was tried first and reverted: it
// subclasses Flutter's own `IconData`, which newer Flutter SDKs mark
// `final`, breaking dart2js compilation outright
// ("The class 'IconData' can't be extended outside of its library because
// it's a final class"). These are plain CustomPainters instead, using only
// Canvas primitives that have been stable for years — no risk of an
// SDK-internal class-modifier change breaking the build again.
//
// These are simplified geometric silhouettes, not pixel-perfect
// reproductions of the official marks (that needs real vector assets this
// app doesn't have) — but they're recognizable, brand-distinct shapes
// rather than generic Material glyphs standing in for the wrong platform.
import 'package:flutter/material.dart';

enum BrandIcon { x, linkedin, facebook, instagram, youtube, whatsapp }

class BrandIconWidget extends StatelessWidget {
  final BrandIcon icon;
  final Color color;
  final double size;
  const BrandIconWidget({super.key, required this.icon, required this.color, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BrandPainter(icon: icon, color: color)),
    );
  }
}

class _BrandPainter extends CustomPainter {
  final BrandIcon icon;
  final Color color;
  const _BrandPainter({required this.icon, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (icon) {
      case BrandIcon.x:
        _paintX(canvas, size, stroke);
        break;
      case BrandIcon.linkedin:
        _paintLinkedIn(canvas, size, fill);
        break;
      case BrandIcon.facebook:
        _paintFacebook(canvas, size, stroke);
        break;
      case BrandIcon.instagram:
        _paintInstagram(canvas, size, stroke, fill);
        break;
      case BrandIcon.youtube:
        _paintYoutube(canvas, size, fill);
        break;
      case BrandIcon.whatsapp:
        _paintWhatsapp(canvas, size, fill);
        break;
    }
  }

  // X (Twitter) -- two crossing diagonal strokes.
  void _paintX(Canvas canvas, Size s, Paint stroke) {
    final w = s.width;
    final inset = w * 0.16;
    canvas.drawLine(Offset(inset, inset), Offset(w - inset, w - inset), stroke);
    canvas.drawLine(Offset(w - inset, inset), Offset(inset, w - inset), stroke);
  }

  // LinkedIn -- a dot+stem "i" and an arched "n".
  void _paintLinkedIn(Canvas canvas, Size s, Paint fill) {
    final w = s.width;
    // "i" dot + stem, left side.
    canvas.drawCircle(Offset(w * 0.22, h(s, 0.2)), w * 0.09, fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.13, h(s, 0.38), w * 0.18, h(s, 0.44)), Radius.circular(w * 0.05)),
      fill,
    );
    // "n" -- two stems joined by an arch.
    final nLeft = w * 0.5;
    final nRight = w * 0.82;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(nLeft - w * 0.09, h(s, 0.38), w * 0.18, h(s, 0.44)), Radius.circular(w * 0.05)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(nRight - w * 0.09, h(s, 0.5), w * 0.18, h(s, 0.32)), Radius.circular(w * 0.05)),
      fill,
    );
    final arch = Path()
      ..moveTo(nLeft, h(s, 0.44))
      ..quadraticBezierTo(nLeft + w * 0.16, h(s, 0.32), nRight, h(s, 0.44))
      ..lineTo(nRight, h(s, 0.56))
      ..quadraticBezierTo(nLeft + w * 0.16, h(s, 0.46), nLeft, h(s, 0.56))
      ..close();
    canvas.drawPath(arch, fill);
  }

  // Facebook -- lowercase "f" letterform.
  void _paintFacebook(Canvas canvas, Size s, Paint stroke) {
    final w = s.width;
    final path = Path()
      ..moveTo(w * 0.62, h(s, 0.85))
      ..lineTo(w * 0.62, h(s, 0.32))
      ..quadraticBezierTo(w * 0.62, h(s, 0.12), w * 0.82, h(s, 0.12))
      ..moveTo(w * 0.42, h(s, 0.42))
      ..lineTo(w * 0.78, h(s, 0.42));
    canvas.drawPath(path, stroke);
  }

  // Instagram -- rounded-square frame, lens circle, flash dot.
  void _paintInstagram(Canvas canvas, Size s, Paint stroke, Paint fill) {
    final w = s.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, w * 0.08, w * 0.84, w * 0.84), Radius.circular(w * 0.26)),
      stroke,
    );
    canvas.drawCircle(Offset(w * 0.5, w * 0.5), w * 0.22, stroke);
    canvas.drawCircle(Offset(w * 0.72, w * 0.28), w * 0.06, fill);
  }

  // YouTube -- rounded rectangle with a play-triangle cut out of it.
  void _paintYoutube(Canvas canvas, Size s, Paint fill) {
    final w = s.width;
    final frame = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.05, h(s, 0.18), w * 0.9, h(s, 0.64)), Radius.circular(w * 0.2)));
    final triangle = Path()
      ..moveTo(w * 0.42, h(s, 0.35))
      ..lineTo(w * 0.42, h(s, 0.65))
      ..lineTo(w * 0.68, h(s, 0.5))
      ..close();
    canvas.drawPath(Path.combine(PathOperation.difference, frame, triangle), fill);
  }

  // WhatsApp -- rounded speech-bubble with a phone-handset silhouette.
  void _paintWhatsapp(Canvas canvas, Size s, Paint fill) {
    final w = s.width;
    final bubble = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, w * 0.08, w * 0.84, w * 0.72), Radius.circular(w * 0.32)))
      ..moveTo(w * 0.28, w * 0.72)
      ..lineTo(w * 0.18, w * 0.92)
      ..lineTo(w * 0.42, w * 0.76)
      ..close();
    canvas.drawPath(bubble, fill);
    // Handset squiggle, cut out of the bubble in white-on-color style would
    // need a blend mode; simplest legible approach is an inline stroke arc.
    final handset = Path()
      ..moveTo(w * 0.36, h(s, 0.36))
      ..quadraticBezierTo(w * 0.32, h(s, 0.3), w * 0.4, h(s, 0.28))
      ..quadraticBezierTo(w * 0.48, h(s, 0.26), w * 0.46, h(s, 0.36))
      ..quadraticBezierTo(w * 0.44, h(s, 0.44), w * 0.5, h(s, 0.48))
      ..quadraticBezierTo(w * 0.56, h(s, 0.52), w * 0.62, h(s, 0.46))
      ..quadraticBezierTo(w * 0.7, h(s, 0.42), w * 0.68, h(s, 0.5))
      ..quadraticBezierTo(w * 0.66, h(s, 0.6), w * 0.54, h(s, 0.58))
      ..quadraticBezierTo(w * 0.4, h(s, 0.54), w * 0.36, h(s, 0.36))
      ..close();
    final white = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawPath(handset, white);
  }

  double h(Size s, double fraction) => s.height * fraction;

  @override
  bool shouldRepaint(covariant _BrandPainter oldDelegate) => oldDelegate.icon != icon || oldDelegate.color != color;
}
