import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';

/// A responsive layout wrapper for auth screens.
/// - Mobile (<600px): Full width with padding
/// - Tablet/Desktop (>=600px): Centered form with max width and card styling
class ResponsiveAuthLayout extends StatelessWidget {
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;

  // Brand Colors
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color backgroundWhite = Color(0xFFFAFAFA);
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color textDark = Color(0xFF1A1A1A);

  const ResponsiveAuthLayout({
    Key? key,
    required this.child,
    this.showBackButton = false,
    this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth >= 600;

            if (isLargeScreen) {
              return _buildLargeScreenLayout(context, constraints);
            } else {
              return _buildMobileLayout(context);
            }
          },
        ),
      ),
    );
  }

  /// Large screen layout: Centered form with max width and card styling
  Widget _buildLargeScreenLayout(BuildContext context, BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 540),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          margin: const EdgeInsets.only(top: 12, bottom: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.sharpLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Mobile layout: Full width with standard padding
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: child,
    );
  }
}

/// A mixin to provide responsive helpers for auth screens
mixin ResponsiveAuthMixin {
  // Get responsive font size
  double getResponsiveTitleSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 600) return 32;
    return 36;
  }

  // Check if we're on a large screen
  bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  // Check if we're on desktop (kept for compatibility, same as isLargeScreen now)
  bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }
}
