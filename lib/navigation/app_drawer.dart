// lib/navigation/app_drawer.dart
//
// Mobile off-canvas nav drawer, opened from AppHeader's hamburger button —
// mirrors the website's `#mobileNavMenu` (templates/base.html): a search
// entry point, the 8 primary section links in the same fixed order with the
// same odd/even zebra striping (#F0F7FF / white, active row solid
// #1D4ED8), then a full-width profile row (or "Sign In") and, since this is
// a native app rather than a page load, an explicit full-width Log Out
// action below it — the website has no mobile equivalent for that since
// signing out there is reached from the desktop nav / profile page instead.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/controllers/mjengo_auth_controller.dart';
import '../news/widgets/net_image.dart';
import '../point/routes/app_routes.dart';
import '../shared/theme/app_theme.dart';
import 'main_navigation.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const Color _zebraTint = Color(0xFFF0F7FF);
  static const Color _zebraBorder = Color(0xFFDBEAFE);
  static const Color _activeColor = Color(0xFF1D4ED8);

  static void _goToTab(int tabIndex) {
    Get.back(); // close the drawer first
    Get.find<MainNavController>().currentIndex.value = tabIndex;
    if (Get.currentRoute != AppRoutes.home) {
      Get.until((route) => route.settings.name == AppRoutes.home);
    }
  }

  static void _pushRoute(String route) {
    Get.back();
    Get.toNamed(route);
  }

  static const _links = [
    _DrawerLink('Home', tab: MainNavController.tabHome),
    _DrawerLink('News and Articles', tab: MainNavController.tabNews),
    _DrawerLink('Infrastructure Tracker', route: AppRoutes.projects),
    _DrawerLink('Private Projects', route: AppRoutes.privateProjects),
    _DrawerLink('Africa & World', route: AppRoutes.africaWorld),
    _DrawerLink('Built History', route: AppRoutes.builtHistory),
    _DrawerLink('Media', tab: MainNavController.tabMedia),
    _DrawerLink('Site Safety', route: AppRoutes.siteSafety),
    _DrawerLink('Merch', route: AppRoutes.merch),
  ];

  @override
  Widget build(BuildContext context) {
    MjengoAuthController? auth;
    try {
      auth = Get.find<MjengoAuthController>();
    } catch (_) {}

    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.sizeOf(context).width * 0.82,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Image.asset('assets/mjengo_hub_logo.png', height: 27),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Get.back(),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF0F172A),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // ── Search entry point ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: GestureDetector(
                onTap: () => _pushRoute(AppRoutes.search),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.mutedCanvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Search articles, services…',
                        style: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          color: AppColors.captionSlate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Zebra-striped section links — the active row (current tab,
            // or the pushed route this drawer was opened on top of) gets
            // the solid #1D4ED8 highlight instead of its zebra tint. ──────
            Expanded(
              child: Obx(() {
                final currentTab = Get.find<MainNavController>().currentIndex.value;
                final onHome = Get.currentRoute == AppRoutes.home;
                final currentRoute = Get.currentRoute;
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (int i = 0; i < _links.length; i++)
                      _DrawerLinkRow(
                        link: _links[i],
                        zebra: i.isEven ? _zebraTint : Colors.white,
                        zebraBorder: i.isEven ? _zebraBorder : null,
                        active: _links[i].tab != null
                            ? (onHome && currentTab == _links[i].tab)
                            : currentRoute == _links[i].route,
                        onTap: () => _links[i].route != null
                            ? _pushRoute(_links[i].route!)
                            : _goToTab(_links[i].tab!),
                      ),
                  ],
                );
              }),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // ── Profile / Sign in + Log out ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: (auth == null || !auth.isAuthenticated)
                  ? _SignInFullWidthButton(onTap: () => _pushRoute(AppRoutes.login))
                  : Obx(() {
                      final user = auth!.currentUser;
                      return Column(
                        children: [
                          _ProfileFullWidthRow(
                            name: user?.displayNameOrFallback ?? 'My Account',
                            photoUrl: user?.photoURL,
                            initials: user?.initials ?? '?',
                            onTap: () => _goToTab(MainNavController.tabProfile),
                          ),
                          const SizedBox(height: 8),
                          _LogoutFullWidthButton(
                            onTap: () {
                              Get.back();
                              auth!.signOut();
                            },
                          ),
                        ],
                      );
                    }),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerLink {
  final String label;
  final int? tab;
  final String? route;
  const _DrawerLink(this.label, {this.tab, this.route});
}

class _DrawerLinkRow extends StatelessWidget {
  final _DrawerLink link;
  final Color zebra;
  final Color? zebraBorder;
  final bool active;
  final VoidCallback onTap;

  const _DrawerLinkRow({
    required this.link,
    required this.zebra,
    required this.zebraBorder,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? AppDrawer._activeColor : zebra,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: (!active && zebraBorder != null)
                  ? Border.all(color: zebraBorder!)
                  : null,
            ),
            child: Text(
              link.label,
              style: GoogleFonts.montserrat(
                fontSize: 14.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width row spanning exactly like [_LogoutFullWidthButton] beneath it
/// — avatar/initials, full name (no premature ellipsis truncation beyond the
/// row's own width), chevron.
class _ProfileFullWidthRow extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String initials;
  final VoidCallback onTap;

  const _ProfileFullWidthRow({
    required this.name,
    required this.photoUrl,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mutedCanvas,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: NetImage(
                  url: photoUrl,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                  errorBuilder: (_) => Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutFullWidthButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutFullWidthButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 16,
                color: AppColors.danger,
              ),
              const SizedBox(width: 6),
              Text(
                'Log Out',
                style: GoogleFonts.montserrat(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInFullWidthButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SignInFullWidthButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryBlue,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Text(
            'Sign In',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
