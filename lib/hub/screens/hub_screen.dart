// lib/hub/screens/hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../navigation/main_navigation.dart';
import '../../news/controllers/discover_controller.dart';
import '../../point/routes/app_routes.dart';
import '../../profile/contact_screen.dart';
import '../../shared/theme/app_theme.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  HUB SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class HubScreen extends StatelessWidget {
  const HubScreen({Key? key}) : super(key: key);

  static const String _mjengoNetworksUrl = 'https://mjengonetworks.co.ke/';
  static const String _shareBarabaraUrl = 'https://sharebarabara.co.ke';

  // Order matches the website's header menu exactly (Spec: Infrastructure
  // Tracker, Private Projects, Built History, Africa & World, Site Safety,
  // Merch). Everything else the app also exposes here lives in
  // [_utilityItems] instead, grouped below a divider.
  static const _items = [
    _HubItem(
      label: 'Infrastructure Tracker',
      sub: "Kenya's roads, bridges & public infrastructure",
      icon: Icons.corporate_fare_rounded,
      color: AppColors.accentBlue,
      route: AppRoutes.projects,
    ),
    _HubItem(
      label: 'Private Projects',
      sub: 'Commercial & residential developments',
      icon: Icons.apartment_rounded,
      color: AppColors.primaryBlue,
      route: AppRoutes.privateProjects,
    ),
    _HubItem(
      label: 'Built History',
      sub: "Kenya's architectural & infrastructure heritage",
      icon: Icons.account_balance_rounded,
      color: AppColors.deepNavy,
      route: AppRoutes.builtHistory,
    ),
    _HubItem(
      label: 'Africa & World',
      sub: 'Landmark projects across the continent and beyond',
      icon: Icons.public_rounded,
      color: AppColors.accentBlue,
      route: AppRoutes.africaWorld,
    ),
    _HubItem(
      label: 'Site Safety',
      sub: 'Construction site incident database',
      icon: Icons.engineering_rounded,
      color: AppColors.warning,
      route: AppRoutes.siteSafety,
    ),
    _HubItem(
      label: 'Merch',
      sub: 'Mjengo Hub branded gear',
      icon: Icons.shopping_bag_rounded,
      color: AppColors.primeBadge,
      route: AppRoutes.merch,
    ),
  ];

  // Remaining ecosystem/utility links — grouped beneath a divider with the
  // sharp architectural button styling rather than the primary tracker rows.
  static const _utilityItems = [
    _HubItem(
      label: 'Infrastructure Reports',
      sub: 'Report a road, bridge or utility fault',
      icon: Icons.report_gmailerrorred_rounded,
      color: AppColors.warning,
      route: AppRoutes.reports,
    ),
    _HubItem(
      label: 'Submit a Project',
      sub: 'Add a project to a tracker for review',
      icon: Icons.add_business_rounded,
      color: AppColors.accentBlue,
      route: AppRoutes.submitProject,
    ),
    _HubItem(
      label: 'Top Contributors',
      sub: 'Weekly leaderboards — points & project submissions',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFFBBF24),
      route: AppRoutes.contributors,
    ),
    _HubItem(
      label: 'Partner With Us',
      sub: 'Reach construction professionals across Kenya',
      icon: Icons.campaign_rounded,
      color: AppColors.primeBadge,
      route: AppRoutes.advertise,
    ),
    _HubItem(
      label: 'About & Contact',
      sub: 'Get in touch with the Mjengo Hub team',
      icon: Icons.info_outline_rounded,
      color: AppColors.deepNavy,
      openScreen: _openContact,
    ),
    _HubItem(
      label: 'Mjengo Networks',
      sub: 'Our wider media & social network',
      icon: Icons.hub_rounded,
      color: AppColors.deepNavy,
      route: null,
      externalUrl: _mjengoNetworksUrl,
    ),
    _HubItem(
      label: 'Share Barabara',
      sub: 'Road safety awareness & reporting',
      icon: Icons.directions_car_filled_rounded,
      color: AppColors.danger,
      route: null,
      externalUrl: _shareBarabaraUrl,
    ),
  ];

  static void _openContact() => Get.to(() => const ContactScreen());

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hub',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Projects, safety, services & community',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSubtle,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── List ─────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  for (final item in _items) _HubRow(item: item),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.borderSlate, height: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'MORE',
                            style: GoogleFonts.montserrat(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.captionSlate,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.borderSlate, height: 1)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        for (final item in _utilityItems) _HubUtilityButton(item: item),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA
// ─────────────────────────────────────────────────────────────────────────────

class _HubItem {
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  final String? route;
  final String? externalUrl;

  /// When set, tapping this tile presets the News tab's category filter to
  /// this slug and switches to it, instead of pushing [route].
  final String? categorySlug;

  /// When set, tapping this tile pushes a screen directly (Get.to) instead
  /// of going through a named route — used for tiles with no AppRoutes
  /// entry, e.g. About & Contact.
  final VoidCallback? openScreen;

  const _HubItem({
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
    this.route,
    this.externalUrl,
    this.categorySlug,
    this.openScreen,
  });

  Future<void> open() async {
    if (externalUrl != null) {
      final uri = Uri.parse(externalUrl!);
      // In-app browser (Custom Tabs / SFSafariViewController), not a
      // system-browser hand-off — matches X/Twitter's in-app link behavior.
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
      return;
    }
    if (categorySlug != null) {
      try {
        Get.find<DiscoverController>().selectCategory(categorySlug!);
      } catch (_) {}
      try {
        Get.find<MainNavController>().currentIndex.value = MainNavController.tabNews;
      } catch (_) {}
      return;
    }
    if (openScreen != null) {
      openScreen!();
      return;
    }
    if (route != null) Get.toNamed(route!);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROW TILE — colored icon bubble + title/subtitle, matching the icon-led
//  pattern used elsewhere in the app (e.g. ProfileScreen's settings rows)
//  instead of a bare text row.
// ─────────────────────────────────────────────────────────────────────────────

class _HubRow extends StatelessWidget {
  final _HubItem item;
  const _HubRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.open,
      splashColor: item.color.withValues(alpha: 0.06),
      highlightColor: item.color.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.sub,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron / external-link indicator
            Icon(
              item.externalUrl != null ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
              color: AppColors.textSubtle,
              size: item.externalUrl != null ? 18 : 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  UTILITY BUTTON — sharp architectural button card (BorderRadius.circular(4),
//  slate-50 background) for the ecosystem/utility links grouped below the
//  primary 6 trackers.
// ─────────────────────────────────────────────────────────────────────────────

class _HubUtilityButton extends StatelessWidget {
  final _HubItem item;
  const _HubUtilityButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        child: InkWell(
          onTap: item.open,
          borderRadius: BorderRadius.circular(AppRadius.sharp),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sharp),
              border: Border.all(color: AppColors.borderSlate),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, color: item.color, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label,
                          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.headingSlate)),
                      Text(item.sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.captionSlate)),
                    ],
                  ),
                ),
                Icon(
                  item.externalUrl != null ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
                  color: AppColors.captionSlate,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
