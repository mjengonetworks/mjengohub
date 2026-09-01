// lib/shared/widgets/responsive.dart
//
// Shared breakpoints + a content-width clamp so the same screens read well on
// a phone, a tablet and the web build (the app ships to Firebase Hosting /
// GitHub Pages, where an unclamped ListView stretches to 1900px and looks
// broken next to the website).
//
// Breakpoints mirror the website's `main.css` media queries.
import 'package:flutter/material.dart';

class Breakpoints {
  const Breakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isTablet => screenWidth >= Breakpoints.tablet;
  bool get isDesktop => screenWidth >= Breakpoints.desktop;

  /// Column count for card/media grids — 1 on phones, 2 on tablets, 3 on wide
  /// desktop, matching the website's project/article grid behaviour.
  int get gridColumns {
    if (screenWidth >= Breakpoints.desktop) return 3;
    if (screenWidth >= Breakpoints.tablet) return 2;
    return 1;
  }
}

/// Centres [child] and caps it at [maxWidth] on large screens, leaving phone
/// layouts completely untouched (no extra padding, no rebuild cost).
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = 900,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
