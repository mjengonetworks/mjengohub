// lib/shared/services/link_launcher.dart
//
// Single entry point for opening a link tapped inside the app. Two cases:
//   * Trinity (sister-app) links — sharebarabara.co.ke / mjengonetworks.co.ke
//     — open in-app with a small "Explore our other apps" banner. The sister
//     apps aren't published yet, so this deliberately does not attempt a
//     custom-scheme launch or claim to detect whether they're installed.
//   * Everything else — the same LaunchMode.inAppBrowserView (Chrome Custom
//     Tabs / SFSafariViewController) already used everywhere in this app,
//     which already keeps the user inside an in-app browser overlay rather
//     than handing off to the system browser.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/webview_checkout_screen.dart';
import '../theme/app_theme.dart';

const Set<String> _kTrinityHosts = {
  'sharebarabara.co.ke',
  'www.sharebarabara.co.ke',
  'mjengonetworks.co.ke',
  'www.mjengonetworks.co.ke',
  'mjengonetworks.com',
  'www.mjengonetworks.com',
};

String _trinityAppName(String host) =>
    host.contains('sharebarabara') ? 'Share Barabara' : 'Mjengo Networks';

class LinkLauncher {
  static Future<void> openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (_kTrinityHosts.contains(uri.host.toLowerCase())) {
      Get.to(
        () => WebviewCheckoutScreen(
          title: _trinityAppName(uri.host),
          url: url,
          banner: _TrinityBanner(appName: _trinityAppName(uri.host)),
        ),
      );
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }
}

class _TrinityBanner extends StatelessWidget {
  final String appName;
  const _TrinityBanner({required this.appName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.headingSlate,
      child: Row(
        children: [
          const Icon(Icons.hub_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Explore our other apps — $appName',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
