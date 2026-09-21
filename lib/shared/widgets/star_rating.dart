// lib/shared/widgets/star_rating.dart
//
// Dynamic 5-star row — always built from a real rating value rather than a
// hardcoded filled star, so it reflects whatever the caller actually scored.
import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  /// Rating on a 0–5 scale. Callers scoring on a different scale (e.g. the
  /// project tracker's 1–10 rating) should convert before passing it in.
  final double rating;
  final double size;
  final Color color;
  final Color emptyColor;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.color = const Color(0xFFF59E0B),
    this.emptyColor = const Color(0xFFE2E8F0),
  });

  @override
  Widget build(BuildContext context) {
    final clamped = rating.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final threshold = index + 1;
        final IconData icon;
        final Color iconColor;
        if (clamped >= threshold) {
          icon = Icons.star_rounded;
          iconColor = color;
        } else if (clamped >= threshold - 0.5) {
          icon = Icons.star_half_rounded;
          iconColor = color;
        } else {
          icon = Icons.star_border_rounded;
          iconColor = emptyColor;
        }
        return Icon(icon, size: size, color: iconColor);
      }),
    );
  }
}
