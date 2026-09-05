// lib/profile/profile_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/controllers/mjengo_auth_controller.dart';
import '../auth/models/user_model.dart';
import '../news/widgets/net_image.dart';
import '../point/routes/app_routes.dart';
import '../shared/services/site_service.dart';
import '../shared/theme/app_theme.dart';
import '../point/models/points_models.dart';
import '../point/services/gamification_service.dart';
import '../shared/widgets/badges.dart';
import '../shared/widgets/form_fields.dart';
import '../shared/widgets/responsive.dart';
import 'account_screen.dart';
import '../notifications/screens/notifications_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import 'contact_screen.dart';
import '../news/screens/submit_article_screen.dart';
import '../shared/screens/webview_checkout_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<MjengoAuthController>();
    return Obx(() => _SettingsView(
          user: auth.currentUser,
          auth: auth,
          onSignOut: auth.signOut,
        ));
  }
}

// ── Main settings view ────────────────────────────────────────────────────────

class _SettingsView extends StatelessWidget {
  final UserModel? user;
  final MjengoAuthController auth;
  final VoidCallback onSignOut;

  const _SettingsView({
    required this.user,
    required this.auth,
    required this.onSignOut,
  });

  static const Color _bg = Color(0xFFF0F4FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ContentWidth(
          maxWidth: 700,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover + avatar + name + Edit Profile action ────────────────
            _ProfileHeader(user: user, auth: auth, topPad: 0),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _PointsSummaryCard(user: user),
            ),

            const SizedBox(height: 10),

            // ── Referral: compact discreet row, not a hero banner ──────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _ReferralCompactTile(),
            ),

            const SizedBox(height: 28),

            // ── My Activity ─────────────────────────────────────────────
            _SettingsGroup(
              title: 'My Activity',
              rows: [
                _GroupRowData(
                  icon: Icons.bookmark_outline_rounded,
                  title: 'Bookmarks & Saved Items',
                  subtitle: 'Bookmarked articles and saved projects',
                  onTap: () => Get.toNamed(AppRoutes.savedItems),
                ),
                _GroupRowData(
                  icon: Icons.inbox_outlined,
                  title: 'My Submissions',
                  subtitle: 'Articles, projects, incidents & comments',
                  onTap: () => Get.toNamed(AppRoutes.submissions),
                ),
                _GroupRowData(
                  icon: Icons.edit_note_rounded,
                  title: 'Submit an Article',
                  subtitle: 'Prime members can submit for editorial review',
                  onTap: () => SubmitArticleScreen.open(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Account ──────────────────────────────────────────────────
            _SettingsGroup(
              title: 'Account',
              rows: [
                _GroupRowData(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notification Preferences',
                  onTap: () => Navigator.of(Get.context!).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
                _GroupRowData(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  onTap: () => Navigator.of(Get.context!).push(
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  ),
                ),
                _GroupRowData(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email Newsletter',
                  onTap: () => showModalBottomSheet<void>(
                    context: Get.context!,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    builder: (_) => const _NewsletterSheet(),
                  ),
                ),
                _GroupRowData(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  onTap: () => Navigator.of(Get.context!).push(
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  ),
                ),
                _GroupRowData(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => Navigator.of(Get.context!).push(
                    MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Ecosystem & Support ─────────────────────────────────────
            _SettingsGroup(
              title: 'Ecosystem & Support',
              rows: [
                if (user?.isPrime != true)
                  _GroupRowData(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Get Verified',
                    subtitle: 'Apply for Mjengo Hub Prime',
                    onTap: () => Get.to(() => const WebviewCheckoutScreen(title: 'Get Verified', nextPath: '/verify')),
                  ),
                _GroupRowData(
                  icon: Icons.campaign_outlined,
                  title: 'Partner With Us',
                  onTap: () => Get.toNamed(AppRoutes.advertise),
                ),
                _GroupRowData(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () => Navigator.of(Get.context!).push(
                    MaterialPageRoute(builder: (_) => const ContactScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Session ──────────────────────────────────────────────────
            _SettingsGroup(
              title: 'Session',
              rows: [
                _GroupRowData(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  titleColor: AppColors.danger,
                  iconColor: AppColors.danger,
                  onTap: onSignOut,
                ),
                _GroupRowData(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Account',
                  titleColor: AppColors.danger,
                  iconColor: AppColors.danger,
                  onTap: () => _showDeleteAccountInfo(context),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Get the app (store buttons, section 8 parity) ─────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _GetTheAppSection(),
            ),

            const SizedBox(height: 32),
          ],
          ),
        ),
      ),
    );
  }

  // Self-service account deletion has no backend endpoint today (confirmed
  // against the real api.py — only an admin-side "deactivated" state
  // exists), so this is an honest "not available yet, contact support"
  // message rather than a submit button to nothing, matching this app's
  // established pattern for other backend gaps (Google sign-in, password
  // reset).
  void _showDeleteAccountInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sharpLg)),
        title: Text('Delete Account', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
        content: Text(
          'Self-service account deletion isn\'t available in the app yet. Contact support and we\'ll take care of it.',
          style: GoogleFonts.montserrat(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactScreen()));
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }
}

// ── Get the app (fetches admin-configured store URLs) ───────────────────────

class _GetTheAppSection extends StatefulWidget {
  const _GetTheAppSection();

  @override
  State<_GetTheAppSection> createState() => _GetTheAppSectionState();
}

class _GetTheAppSectionState extends State<_GetTheAppSection> {
  final _service = SiteService();
  SiteSettings? _settings;

  @override
  void initState() {
    super.initState();
    _service.getSiteSettings().then((s) {
      if (mounted) setState(() => _settings = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get the Mjengo Hub App',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        StoreButtonsRow(
          playStoreUrl: _settings?.playStoreUrl,
          appStoreUrl: _settings?.appStoreUrl,
        ),
      ],
    );
  }
}

// ── Profile header: cover banner + overlapping avatar ──────────────────────────

class _ProfileHeader extends StatefulWidget {
  final UserModel? user;
  final MjengoAuthController auth;
  final double topPad;
  const _ProfileHeader({required this.user, required this.auth, required this.topPad});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  static const double _coverHeight = 150;
  static const double _avatarSize = 84;
  static const double _ringWidth = 3;
  static const double _ringGap = 3;

  final _picker = ImagePicker();
  bool _uploadingAvatar = false;
  bool _uploadingCover = false;

  UserModel? get user => widget.user;
  MjengoAuthController get auth => widget.auth;
  double get topPad => widget.topPad;

  Future<void> _pickAndUpload({required bool isCover}) async {
    if (isCover ? _uploadingCover : _uploadingAvatar) return;

    final XFile? picked = kIsWeb
        ? await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85)
        : await _showSourceSheet();
    if (picked == null) return;

    setState(() => isCover ? _uploadingCover = true : _uploadingAvatar = true);

    final bytes = await picked.readAsBytes();
    final ok = isCover
        ? await auth.uploadCoverImage(bytes, picked.name)
        : await auth.uploadAvatar(bytes, picked.name);

    if (!mounted) return;
    setState(() => isCover ? _uploadingCover = false : _uploadingAvatar = false);

    Get.snackbar(
      ok ? 'Success' : 'Error',
      ok
          ? (isCover ? 'Cover photo updated' : 'Profile photo updated')
          : (auth.errorMessage.isNotEmpty ? auth.errorMessage : 'Failed to upload photo'),
      backgroundColor: ok ? const Color(0xFF22C55E) : AppColors.danger,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
    );
  }

  Future<XFile?> _showSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.accentBlue),
              title: Text('Camera', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.accentBlue),
              title: Text('Photo Library', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return null;
    return _picker.pickImage(source: source, imageQuality: 85);
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? user?.firstName ?? 'User';
    final rawSubtitle = (user?.bio != null && user!.bio!.isNotEmpty)
        ? user!.bio!
        : (user?.company != null && user!.company!.isNotEmpty)
            ? user!.company!
            : (user?.email ?? '');
    final subtitle = rawSubtitle.contains('@') ? _maskEmail(rawSubtitle) : rawSubtitle;
    final initials = user?.initials ?? '?';
    final hasPhoto = user?.photoURL != null && user!.photoURL!.isNotEmpty;
    final hasCover = user?.coverImageUrl != null && user!.coverImageUrl!.isNotEmpty;
    final points = user?.points ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back-of-stack: cover + avatar overlap
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover banner
            GestureDetector(
              onTap: () => _pickAndUpload(isCover: true),
              child: Container(
                width: double.infinity,
                height: _coverHeight,
                decoration: BoxDecoration(
                  gradient: hasCover ? null : AppColors.verifiedPillGradient,
                  image: hasCover
                      ? DecorationImage(image: NetworkImage(user!.coverImageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: topPad + 10, right: 14),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: _uploadingCover
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                    ),
                  ),
                ),
              ),
            ),

            // Avatar — left-aligned, overlapping the cover's lower boundary
            Positioned(
              left: 20,
              top: _coverHeight - (_avatarSize / 2),
              child: GestureDetector(
                onTap: () => _pickAndUpload(isCover: false),
                child: Container(
                  width: _avatarSize + (_ringWidth + _ringGap) * 2,
                  height: _avatarSize + (_ringWidth + _ringGap) * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _SettingsView._bg,
                    border: Border.all(color: AppColors.textDark, width: _ringWidth),
                  ),
                  padding: EdgeInsets.all(_ringGap),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipOval(
                          child: NetImage(
                            url: hasPhoto ? user!.photoURL : null,
                            width: _avatarSize,
                            height: _avatarSize,
                            fit: BoxFit.cover,
                            errorBuilder: (_) => _initialsWidget(initials),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.textDark,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: _uploadingAvatar
                                ? const SizedBox(
                                    width: 11,
                                    height: 11,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                  )
                                : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: (_avatarSize / 2) + 14),

        // Name + badges + subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.montserrat(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: AppColors.headingSlate,
                    ),
                  ),
                  if (user?.isPrime == true) const PrimeBadge(),
                  if (user?.role != null && user!.role!.toUpperCase() != 'USER')
                    RoleBadge(role: user!.role!),
                ],
              ),
              const SizedBox(height: 6),
              ReviewerLevelBadge(points: points),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFF475569),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.sharpLg),
                    border: Border.all(color: AppColors.borderSlate),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined, size: 14, color: AppColors.captionSlate),
                      const SizedBox(width: 6),
                      Text('Edit Profile',
                          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.captionSlate)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1].split('.');
    final maskedLocal = local.length <= 2
        ? '*' * local.length
        : '${local[0]}${'*' * (local.length - 1)}';
    final d = domain[0];
    final maskedDomain =
        d.length <= 2 ? '*' * d.length : '${d[0]}${'*' * (d.length - 1)}';
    return '$maskedLocal@$maskedDomain.${domain.sublist(1).join('.')}';
  }

  Widget _initialsWidget(String initials) => Center(
        child: Text(
          initials,
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      );
}

// ── Points summary card ─────────────────────────────────────────────────────
//
// Points come straight off the cached UserModel (`GET auth/me`'s `points`
// field), so this renders instantly with no network wait — the fuller
// per-source breakdown + activity log lives behind the tap, on PointsScreen.

class _PointsSummaryCard extends StatelessWidget {
  final UserModel? user;
  const _PointsSummaryCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final total = user?.points ?? 0;
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.pointsBreakdown),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sharpLg),
          boxShadow: [
            BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: AppColors.accentBlue, size: 20),
            ),
            const SizedBox(height: 10),
            Text('$total', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textDark)),
            Text('points', style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textSubtle)),
          ],
        ),
      ),
    );
  }
}

// ── Referral: compact, discreet tile (not a hero banner) ───────────────────
//
// Fetches `GET referrals/me` for the current code (GamificationService)
// just to power the copy button; tapping the row itself opens the full
// ReferralScreen for sharing/tracking.

class _ReferralCompactTile extends StatefulWidget {
  const _ReferralCompactTile();

  @override
  State<_ReferralCompactTile> createState() => _ReferralCompactTileState();
}

class _ReferralCompactTileState extends State<_ReferralCompactTile> {
  final _api = GamificationService();
  ReferralInfo? _info;

  @override
  void initState() {
    super.initState();
    _api.getReferralInfo().then((info) {
      if (mounted) setState(() => _info = info);
    });
  }

  void _copyCode() {
    final code = _info?.code;
    if (code == null || code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    Get.snackbar(
      'Copied',
      'Referral code copied to clipboard',
      backgroundColor: AppColors.headingSlate,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.referral),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sharp),
          border: Border.all(color: AppColors.borderSlate),
        ),
        child: Row(
          children: [
            const Icon(Icons.card_giftcard_outlined, size: 18, color: AppColors.captionSlate),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invite Colleagues & Earn Points',
                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.headingSlate)),
                  if (_info?.code.isNotEmpty == true)
                    Text(_info!.code,
                        style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.captionSlate, letterSpacing: 0.4)),
                ],
              ),
            ),
            if (_info?.code.isNotEmpty == true)
              GestureDetector(
                onTap: _copyCode,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppRadius.sharp),
                    border: Border.all(color: AppColors.borderSlate),
                  ),
                  child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.captionSlate),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Settings group: sharp-cornered container of rows under a section
// label, replacing the old flat un-grouped settings list. ──────────────────

class _GroupRowData {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _GroupRowData({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.titleColor,
    this.iconColor,
  });
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_GroupRowData> rows;
  const _SettingsGroup({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.captionSlate, letterSpacing: 0.6),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.sharp),
              border: Border.all(color: AppColors.borderSlate),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  _GroupRow(data: rows[i]),
                  if (i != rows.length - 1) const Divider(height: 1, color: AppColors.borderSlate),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final _GroupRowData data;
  const _GroupRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(data.icon, size: 19, color: data.iconColor ?? AppColors.captionSlate),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w600, color: data.titleColor ?? AppColors.headingSlate),
                  ),
                  if (data.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(data.subtitle!, style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.captionSlate)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 19, color: AppColors.captionSlate),
          ],
        ),
      ),
    );
  }
}

// ── Email Newsletter subscribe sheet ────────────────────────────────────────

class _NewsletterSheet extends StatefulWidget {
  const _NewsletterSheet();

  @override
  State<_NewsletterSheet> createState() => _NewsletterSheetState();
}

class _NewsletterSheetState extends State<_NewsletterSheet> {
  final _api = SiteService();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final res = await _api.subscribeNewsletter(
      email: _email.text.trim(),
      name: _name.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    final ok = res['success'] == true;
    Navigator.of(context).pop();
    Get.snackbar(
      ok ? 'Subscribed' : 'Could not subscribe',
      res['message'] as String? ?? (ok ? 'You are on the list.' : 'Please try again.'),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Subscribe to the newsletter',
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Construction news, safety alerts and product updates in your inbox.',
                style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle),
              ),
              const SizedBox(height: 18),

              const FieldLabel('Name'),
              AppTextField(controller: _name, hint: 'Optional'),
              const SizedBox(height: 14),

              const FieldLabel('Email', required: true),
              AppTextField(
                controller: _email,
                hint: 'you@example.com',
                keyboard: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                validator: emailField,
              ),
              const SizedBox(height: 22),

              AppSubmitButton(
                label: 'Subscribe',
                busy: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
