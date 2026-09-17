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
import '../search/widgets/omnibar.dart';
import '../shared/services/link_launcher.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/gemini_sparkle_icon.dart';
import 'main_navigation.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  /// Public so [MainNavigation] can reserve exactly this much space for
  /// content padding regardless of the bar's current slide offset.
  static const double barHeight = 50;

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
        color: AppColors.headerTint,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: barHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
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

                // ── Tight action cluster: AI search, verify, notifications,
                // profile — kept to its own min-size Row so narrow screens
                // never fight the Expanded search bar for space.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),

                    // AI Search (Omnibar) — AI-augmented global search,
                    // distinct from the plain-text search bar above (which
                    // routes to the confirmed-live full-page SearchScreen).
                    // See lib/search/widgets/omnibar.dart.
                    IconButton(
                      tooltip: 'Ask AI Intelligence',
                      onPressed: () => showAiSearchSheet(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      splashRadius: 18,
                      icon: const _AiSparkleBadge(),
                    ),

                    const SizedBox(width: 4),

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
                    _AuthAreaButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── AI trigger: multi-star sparkle on a cyan/indigo gradient badge ─────────

class _AiSparkleBadge extends StatelessWidget {
  const _AiSparkleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: const GeminiSparkleIcon(size: 20, color: Colors.white),
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
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mutedCanvas,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primaryBlue, size: 20),
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
    if (auth == null) return const SizedBox(width: 34, height: 34);

    return Obx(() {
      final isPrime = auth!.currentUser?.isPrime == true;
      if (!isPrime) {
        return Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          child: const Icon(
            Icons.verified_outlined,
            color: AppColors.textSubtle,
            size: 20,
          ),
        );
      }
      return Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        child: Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 12, color: Colors.white),
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

// ── Auth area — Sign In pill for guests, avatar (opens Profile tab) for
// signed-in users. Below 360dp there's no room for a labeled pill next to
// the rest of the action cluster, so guests get a bare person icon instead
// that still routes to /login. ──────────────────────────────────────────────

class _AuthAreaButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    MjengoAuthController? auth;
    try {
      auth = Get.find<MjengoAuthController>();
    } catch (_) {}

    if (auth == null) return const _ProfileAvatarButton(authed: false);

    return Obx(() {
      if (!auth!.isAuthenticated) {
        final narrow = MediaQuery.sizeOf(context).width < 360;
        if (narrow) {
          return GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.login),
            behavior: HitTestBehavior.opaque,
            child: const _HeaderIconButton(icon: Icons.login_rounded),
          );
        }
        return GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.login),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Sign In',
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
      return const _ProfileAvatarButton(authed: true);
    });
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  final bool authed;
  const _ProfileAvatarButton({required this.authed});

  @override
  Widget build(BuildContext context) {
    MjengoAuthController? auth;
    try {
      auth = Get.find<MjengoAuthController>();
    } catch (_) {}

    return GestureDetector(
      onTap: () => AppHeader._goToTab(4),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.accentBlue,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: (!authed || auth == null)
                ? const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 18,
                  )
                : Obx(() {
                    final user = auth!.currentUser;
                    final photoUrl = user?.photoURL;
                    final initials = user?.initials ?? '?';
                    return NetImage(
                      url: photoUrl,
                      width: 30,
                      height: 30,
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
