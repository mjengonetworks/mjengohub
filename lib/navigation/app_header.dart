// lib/navigation/app_header.dart
//
// Persistent top navigation bar, mirroring the website's sticky `.desktop-nav`
// (templates/base.html): pure white background, logo+brand on the far left
// routing home, and search / verification / notifications / profile grouped
// on the far right in that exact order. Mounted once in MainNavigation so it
// stays visible across every tab, matching the website's nav persisting
// across every page.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/controllers/mjengo_auth_controller.dart';
import '../news/widgets/net_image.dart';
import '../notifications/controllers/notifications_controller.dart';
import '../notifications/screens/notifications_screen.dart';
import '../point/routes/app_routes.dart';
import '../shared/services/link_launcher.dart';
import '../shared/theme/app_theme.dart';
import 'main_navigation.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  static const double _barHeight = 64;

  /// Jumps the bottom nav to [tabIndex] and, when called from a screen pushed
  /// on top of MainNavigation (e.g. ProjectsScreen), pops back to it first —
  /// otherwise the index change has no visible effect until the user
  /// manually backs out of the current screen.
  static void _goToTab(int tabIndex) {
    Get.find<MainNavController>().currentIndex.value = tabIndex;
    if (Get.currentRoute != AppRoutes.home) {
      Get.until((route) => route.settings.name == AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 390;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _barHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // ── Brand: logo only, routes home (mirrors the website's
                // nav-brand, which is the logo image with no adjacent
                // wordmark text) ────────────────────────────────────────────
                SizedBox(
                  width: isCompact ? 76 : 112,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _goToTab(0),
                      child: Image.asset(
                        'assets/mjengo_hub_logo.png',
                        height: 30,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.search),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mutedCanvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF64748B),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search Mjengo Hub',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 11.5,
                                color: AppColors.captionSlate,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // ── Far-right actions: search, verify, notifications, profile
                if (!isCompact) ...[
                  GestureDetector(
                    onTap: () => LinkLauncher.openLink(
                      context,
                      'https://mjengohub.co.ke/verify',
                    ),
                    child: const _VerifiedBadgeButton(),
                  ),
                  const SizedBox(width: 4),
                ],
                _NotificationBellButton(),
                const SizedBox(width: 8),
                _ProfileAvatarButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared icon button chrome ────────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  const _HeaderIconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.mutedCanvas,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryBlue, size: 19),
      ),
    );
  }
}

// ── Verification badge: clean blue checkmark, active state for Prime users ──

class _VerifiedBadgeButton extends StatelessWidget {
  const _VerifiedBadgeButton();

  @override
  Widget build(BuildContext context) {
    MjengoAuthController? auth;
    try {
      auth = Get.find<MjengoAuthController>();
    } catch (_) {}
    if (auth == null) return const SizedBox(width: 38, height: 38);

    return Obx(() {
      final isPrime = auth!.currentUser?.isPrime == true;
      return Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        child: Icon(
          Icons.verified_rounded,
          color: isPrime ? AppColors.primaryBlue : AppColors.textSubtle,
          size: 21,
        ),
      );
    });
  }
}

// ── Notification bell with unread-count badge ───────────────────────────────

class _NotificationBellButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    NotificationsController? ctrl;
    try {
      ctrl = Get.find<NotificationsController>();
    } catch (_) {}

    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _HeaderIconButton(icon: Icons.notifications_none_rounded),
          if (ctrl != null)
            Positioned(
              top: 6,
              right: 6,
              child: Obx(
                () => ctrl!.unreadCount.value > 0
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Profile avatar — far right, opens the Profile tab directly ─────────────

class _ProfileAvatarButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    MjengoAuthController? auth;
    try {
      auth = Get.find<MjengoAuthController>();
    } catch (_) {}

    return GestureDetector(
      onTap: () => AppHeader._goToTab(4),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
        decoration: const BoxDecoration(
          color: AppColors.accentBlue,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
            child: auth == null
            ? const Icon(Icons.person_rounded, color: Colors.white, size: 18)
            : Obx(() {
                final user = auth!.currentUser;
                final photoUrl = user?.photoURL;
                final initials = user?.initials ?? '?';
                return NetImage(
                  url: photoUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_) => Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
          ),
        ),
      ),
    );
  }
}
