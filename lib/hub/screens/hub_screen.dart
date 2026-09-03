// lib/hub/screens/hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  HUB SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class HubScreen extends StatelessWidget {
  const HubScreen({Key? key}) : super(key: key);

  static const String _mjengoNetworksUrl = 'https://mjengonetworks.co.ke/';

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
      label: 'Site Safety',
      sub: 'Construction site incident database',
      icon: Icons.engineering_rounded,
      color: AppColors.warning,
      route: AppRoutes.siteSafety,
    ),
    _HubItem(
      label: 'Infrastructure Reports',
      sub: 'Report a road, bridge or utility fault',
      icon: Icons.report_gmailerrorred_rounded,
      color: AppColors.warning,
      route: AppRoutes.reports,
    ),
    _HubItem(
      label: 'Services',
      sub: 'Request construction services',
      icon: Icons.handyman_rounded,
      color: AppColors.accentBlue,
      route: AppRoutes.services,
    ),
    _HubItem(
      label: 'Advertise with Us',
      sub: 'Reach construction professionals across Kenya',
      icon: Icons.campaign_rounded,
      color: AppColors.primeBadge,
      route: AppRoutes.advertise,
    ),
    _HubItem(
      label: 'Mjengo Networks',
      sub: 'Our wider media & social network',
      icon: Icons.hub_rounded,
      color: AppColors.deepNavy,
      route: null,
      externalUrl: _mjengoNetworksUrl,
    ),
  ];

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
                      fontWeight: FontWeight.w800,
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
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: _items.length,
                itemBuilder: (_, i) => _HubRow(item: _items[i]),
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
  const _HubItem({
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
    this.route,
    this.externalUrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROW TILE — colored icon bubble + title/subtitle, matching the icon-led
//  pattern used elsewhere in the app (e.g. ProfileScreen's settings rows)
//  instead of a bare text row.
// ─────────────────────────────────────────────────────────────────────────────

class _HubRow extends StatelessWidget {
  final _HubItem item;
  const _HubRow({required this.item});

  Future<void> _open() async {
    if (item.externalUrl != null) {
      final uri = Uri.parse(item.externalUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    if (item.route != null) Get.toNamed(item.route!);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _open,
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
                      fontWeight: FontWeight.w700,
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
