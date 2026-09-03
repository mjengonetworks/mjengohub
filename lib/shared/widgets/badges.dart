// lib/shared/widgets/badges.dart
//
// Reusable brand widgets shared across screens: the "Get Verified" pill CTA,
// Mjengo Hub Prime badge, reviewer-level badge (Google Local Guides style),
// and the animated Play/App Store footer buttons.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../point/models/points_models.dart';
import '../theme/app_theme.dart';

/// Permanent primary-blue gradient pill CTA for "Get Verified", used in the
/// global header. Always rendered in its active/default gradient state per
/// spec — no idle/disabled visual variant.
class GetVerifiedButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool compact;
  const GetVerifiedButton({super.key, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: compact ? 8 : 10),
        decoration: BoxDecoration(
          gradient: AppColors.verifiedPillGradient,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(
              'Get Verified',
              style: GoogleFonts.montserrat(
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark contrasting backdrop for secondary hero text over a photo, used on
/// non-home screens (project/incident/article detail hero images) so
/// subtext stays readable regardless of the underlying image.
class HeroTextBadge extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const HeroTextBadge({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

/// High-contrast "Submit a Project" CTA.
class SubmitProjectButton extends StatelessWidget {
  final VoidCallback onTap;
  const SubmitProjectButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.textDark,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_business_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 7),
            Text('Submit a Project',
                style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// "Mjengo Hub Prime" badge — refined blue, replaces any generic "Premium" label.
class PrimeBadge extends StatelessWidget {
  final double fontSize;
  const PrimeBadge({super.key, this.fontSize = 9});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.primeGradient,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, color: Colors.white, size: fontSize + 3),
          const SizedBox(width: 3),
          Text(
            'MJENGO HUB PRIME',
            style: GoogleFonts.montserrat(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reviewer level badge (Google Local Guides style), shown on profile
/// headers and next to commenter names.
class ReviewerLevelBadge extends StatelessWidget {
  final int points;
  final bool small;
  const ReviewerLevelBadge({super.key, required this.points, this.small = false});

  @override
  Widget build(BuildContext context) {
    final level = ReviewerLevel.forPoints(points);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 9, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.military_tech_rounded, size: small ? 11 : 13, color: AppColors.accentBlue),
          SizedBox(width: small ? 3 : 4),
          Text(
            'Level ${level.level} · ${level.name}',
            style: GoogleFonts.montserrat(
              fontSize: small ? 9.5 : 11,
              fontWeight: FontWeight.w700,
              color: AppColors.accentBlue,
            ),
          ),
        ],
      ),
    );
  }
}

/// Role badge for elevated accounts (admin/editor/moderator/author) — mirrors
/// the website profile hero's `{{ user.role.value.title() }}` pill. Not shown
/// for the plain 'user' role, which carries no special standing.
class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final label = role
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Inline "Add on Google" pill — the mobile equivalent of the website's
/// Google Maps share trigger on a project's detail page.
class AddOnGooglePill extends StatelessWidget {
  final VoidCallback onTap;
  const AddOnGooglePill({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_rounded, size: 13, color: Color(0xFF4285F4)),
            const SizedBox(width: 5),
            Text(
              'Add on Google',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Play Store / App Store footer buttons — launches the admin-configured
/// store URLs (SiteSetting: footer_playstore_url / footer_appstore_url).
/// No hardcoded "Coming Soon" — falls back silently if a link isn't set.
class StoreButtonsRow extends StatelessWidget {
  final String? playStoreUrl;
  final String? appStoreUrl;
  const StoreButtonsRow({super.key, this.playStoreUrl, this.appStoreUrl});

  static const String _defaultPlayStore =
      'https://play.google.com/store/apps/details?id=ke.co.mjengohub.app';
  static const String _defaultAppStore = 'https://apps.apple.com/app/mjengo-hub';

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StoreButton(
            icon: Icons.shop_rounded,
            label: 'Google Play',
            onTap: () => _launch(playStoreUrl?.isNotEmpty == true ? playStoreUrl! : _defaultPlayStore),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StoreButton(
            icon: Icons.apple,
            label: 'App Store',
            onTap: () => _launch(appStoreUrl?.isNotEmpty == true ? appStoreUrl! : _defaultAppStore),
          ),
        ),
      ],
    );
  }
}

class _StoreButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _StoreButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.textDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
