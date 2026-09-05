// lib/shared/widgets/scroll_to_top_fab.dart
//
// Global "scroll to top" floating action button (Spec 12). Wrap a screen's
// scroll view with [ScrollToTopFab], passing the same [ScrollController] the
// screen already uses (or a fresh one if the screen doesn't have one yet).
// Hidden until the user scrolls past 300px, then fades/slides into view;
// tapping animates back to offset 0 over 400ms.
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ScrollToTopFab extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  /// Extra bottom padding so the button clears a bottom nav bar / other FAB.
  final double bottomOffset;

  const ScrollToTopFab({
    super.key,
    required this.controller,
    required this.child,
    this.bottomOffset = 20,
  });

  @override
  State<ScrollToTopFab> createState() => _ScrollToTopFabState();
}

class _ScrollToTopFabState extends State<ScrollToTopFab> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final show = widget.controller.offset > 300;
    if (show != _visible) setState(() => _visible = show);
  }

  void _scrollToTop() {
    if (!widget.controller.hasClients) return;
    widget.controller.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 16,
          bottom: widget.bottomOffset,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            offset: _visible ? Offset.zero : const Offset(0, 0.4),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: _visible ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_visible,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sharpLg),
                    onTap: _scrollToTop,
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.headingSlate,
                        borderRadius: BorderRadius.circular(AppRadius.sharpLg),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
