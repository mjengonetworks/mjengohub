// lib/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/controllers/mjengo_auth_controller.dart';
import '../auth/models/user_model.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import 'contact_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<MjengoAuthController>();
    return Obx(() => _SettingsView(
          user: auth.currentUser,
          onSignOut: auth.signOut,
        ));
  }
}

// ── Main settings view ────────────────────────────────────────────────────────

class _SettingsView extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onSignOut;

  const _SettingsView({
    required this.user,
    required this.onSignOut,
  });

  static const Color _bg            = Color(0xFFF4F4FB);
  static const Color _surface       = Colors.white;
  static const Color _textPrimary   = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF888888);
  static const Color _divider       = Color(0xFFEEEEF5);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: _bg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topPad),

            // ── Header bar ──────────────────────────────────────────────
            _Header(),

            const SizedBox(height: 20),

            // ── Profile card ─────────────────────────────────────────────
            _ProfileCard(user: user),

            const SizedBox(height: 28),

            // ── Settings items ───────────────────────────────────────────
            _SettingsItem(
              icon: Icons.person_outline_rounded,
              title: 'Account',
              subtitle: 'Edit profile, change email or password',
              onTap: () => _showComingSoon('Account'),
            ),
            _SettingsItem(
              icon: Icons.bookmark_border_rounded,
              title: 'Saved Articles',
              subtitle: 'Reading list, bookmarks & history',
              onTap: () => _showComingSoon('Saved Articles'),
            ),
            _SettingsItem(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'New posts, comments & newsletters',
              onTap: () => _showComingSoon('Notifications'),
            ),
            _SettingsItem(
              icon: Icons.tune_rounded,
              title: 'Reading Preferences',
              subtitle: 'Font size, categories & language',
              onTap: () => _showComingSoon('Reading Preferences'),
            ),
            _SettingsItem(
              icon: Icons.shield_outlined,
              title: 'Privacy & Data',
              subtitle: 'Data usage, personalisation, cookies',
              onTap: () => Navigator.of(Get.context!).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              ),
            ),
            _SettingsItem(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'FAQ, contact us, terms & privacy',
              isLast: true,
              onTap: () => Navigator.of(Get.context!).push(
                MaterialPageRoute(
                  builder: (_) => const ContactScreen(),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Divider ──────────────────────────────────────────────────
            const Divider(color: _divider, thickness: 1, height: 1),

            const SizedBox(height: 8),

            // ── Sign out ─────────────────────────────────────────────────
            _SignOutButton(onTap: onSignOut),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    Get.snackbar(
      feature,
      'Coming soon!',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF6C63FF),
      colorText: Colors.white,
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF1A1A2E), size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Settings',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserModel? user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? user?.firstName ?? 'User';
    final bio = (user?.bio != null && user!.bio!.isNotEmpty)
        ? user!.bio!
        : (user?.email ?? '');
    final initials = user?.initials ?? '?';
    final hasPhoto = user?.photoURL != null && user!.photoURL!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFFB06FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: hasPhoto
                ? ClipOval(
                    child: Image.network(
                      user!.photoURL!,
                      width: 62,
                      height: 62,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initialsWidget(initials),
                    ),
                  )
                : _initialsWidget(initials),
          ),
          const SizedBox(width: 14),
          // Name + bio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  bio,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFF888888),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsWidget(String initials) => Center(
        child: Text(
          initials,
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}

// ── Settings item ─────────────────────────────────────────────────────────────

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            splashColor: const Color(0xFF6C63FF).withOpacity(0.06),
            highlightColor: const Color(0xFF6C63FF).withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF888888).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: const Color(0xFF888888)),
                  ),
                  const SizedBox(width: 14),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            color: const Color(0xFF888888),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFBBBBBB),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (!isLast)
            const Padding(
              padding: EdgeInsets.only(left: 72),
              child: Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFEEEEF5),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sign out button ───────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SignOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            const SizedBox(width: 10),
            Text(
              'Sign Out',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
