// lib/shared/widgets/gemini_sparkle_icon.dart
//
// Multi-star AI trigger glyph for the Omnibar action — one primary
// 4-pointed sparkle with two smaller orbiting satellite sparkles, echoing
// the Gemini-style "AI cluster" mark rather than a single flat
// `Icons.auto_awesome` star. Plain CustomPainter, same approach as
// brand_icons.dart (no flutter_svg dependency — see that file's doc comment
// for why a font-based icon package was tried and reverted here).
import 'package:flutter/material.dart';

class GeminiSparkleIcon extends StatelessWidget {
  final double size;
  final Color color;

  const GeminiSparkleIcon({
    super.key,
    this.size = 22,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GeminiSparklePainter(color: color)),
    );
  }
}

class _GeminiSparklePainter extends CustomPainter {
  final Color color;
  const _GeminiSparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;

    // Primary sparkle — shifted slightly down-left to leave room for the
    // satellite stars in the top-right / bottom-left corners, matching the
    // asymmetric "cluster" composition of the reference mark.
    canvas.drawPath(
      _sparklePath(Offset(s * 0.44, s * 0.56), s * 0.30),
      Paint()..color = color,
    );
    // Medium satellite, top-right.
    canvas.drawPath(
      _sparklePath(Offset(s * 0.80, s * 0.22), s * 0.13),
      Paint()..color = color.withValues(alpha: 0.85),
    );
    // Tiny satellite, bottom-left.
    canvas.drawPath(
      _sparklePath(Offset(s * 0.16, s * 0.84), s * 0.08),
      Paint()..color = color.withValues(alpha: 0.65),
    );
  }

  /// A single 4-pointed sparkle (✦) centered at [c] with outer radius [r] —
  /// four quadratic-bezier lobes pinched at the diagonals, reused at three
  /// scales for the primary star and its two satellites.
  Path _sparklePath(Offset c, double r) {
    const pinch = 0.32;
    final tip = [
      c + Offset(0, -r),
      c + Offset(r, 0),
      c + Offset(0, r),
      c + Offset(-r, 0),
    ];
    final ctrl = [
      c + Offset(r * pinch, -r * pinch),
      c + Offset(r * pinch, r * pinch),
      c + Offset(-r * pinch, r * pinch),
      c + Offset(-r * pinch, -r * pinch),
    ];
    return Path()
      ..moveTo(tip[0].dx, tip[0].dy)
      ..quadraticBezierTo(ctrl[0].dx, ctrl[0].dy, tip[1].dx, tip[1].dy)
      ..quadraticBezierTo(ctrl[1].dx, ctrl[1].dy, tip[2].dx, tip[2].dy)
      ..quadraticBezierTo(ctrl[2].dx, ctrl[2].dy, tip[3].dx, tip[3].dy)
      ..quadraticBezierTo(ctrl[3].dx, ctrl[3].dy, tip[0].dx, tip[0].dy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _GeminiSparklePainter oldDelegate) =>
      oldDelegate.color != color;
}
