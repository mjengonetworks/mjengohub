// lib/news/widgets/featured_article_card.dart
import 'package:flutter/material.dart';

/// Minimalist line/underscore-dash indicators for the featured PageView —
/// mirrors the website's `.mj-hero-dot` (thin flat segments, not circular
/// dots), sized so they never overlap the hero's search bar or action
/// buttons above/below.
class PageDotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const PageDotIndicator({
    super.key,
    required this.count,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 38 : 28,
          height: 3,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
