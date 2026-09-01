// lib/hub/screens/hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../point/routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — mirrors Videos / Discover screens exactly
// ─────────────────────────────────────────────────────────────────────────────
const _kDark    = Color(0xFF111827);
const _kSubtext = Color(0xFF9CA3AF);
const _kBg      = Color(0xFFF3F4F6);
const _kDivider = Color(0xFFF3F4F6);

// ═════════════════════════════════════════════════════════════════════════════
//  HUB SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class HubScreen extends StatelessWidget {
  const HubScreen({Key? key}) : super(key: key);

  static const String _mjengoNetworksUrl = 'https://mjengonetworks.co.ke/';

  static const _items = [
    _HubItem(
      label: 'Projects Database',
      sub: 'Kenya\'s roads, bridges & buildings',
      route: AppRoutes.projects,
    ),
    _HubItem(
      label: 'Private Projects',
      sub: 'Commercial & residential developments',
      route: AppRoutes.privateProjects,
    ),
    _HubItem(
      label: 'Share Barabara',
      sub: 'Road accidents across Kenya',
      route: AppRoutes.shareBarabara,
    ),
    _HubItem(
      label: 'Site Safety',
      sub: 'Construction site incident database',
      route: AppRoutes.siteSafety,
    ),
    _HubItem(
      label: 'Mshikamano',
      sub: 'Mental health & encouragement',
      route: AppRoutes.mshikamano,
    ),
    _HubItem(
      label: 'Infrastructure Reports',
      sub: 'Report a road, bridge or utility fault',
      route: AppRoutes.reports,
    ),
    _HubItem(
      label: 'Services',
      sub: 'Request construction services',
      route: AppRoutes.services,
    ),
    _HubItem(
      label: 'Reviews',
      sub: 'What our clients say',
      route: AppRoutes.reviews,
    ),
    _HubItem(
      label: 'Mjengo Networks',
      sub: 'Our wider media & social network',
      route: null,
      externalUrl: _mjengoNetworksUrl,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topPad + 12),

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
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Projects, safety, services & community',
                    style: GoogleFonts.montserrat(
                        fontSize: 13, color: _kSubtext),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── List ─────────────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: _kDivider,
                ),
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
  final String? route;
  final String? externalUrl;
  const _HubItem({
    required this.label,
    required this.sub,
    this.route,
    this.externalUrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROW TILE  (mirrors VideoListTile layout)
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
    return GestureDetector(
      onTap: _open,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
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
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.sub,
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: _kSubtext),
                  ),
                ],
              ),
            ),

            // Chevron / external-link indicator
            Icon(
              item.externalUrl != null
                  ? Icons.open_in_new_rounded
                  : Icons.chevron_right_rounded,
              color: _kSubtext,
              size: item.externalUrl != null ? 18 : 22,
            ),
          ],
        ),
      ),
    );
  }
}
