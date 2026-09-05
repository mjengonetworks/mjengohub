// lib/profile/account_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/controllers/mjengo_auth_controller.dart';
import '../auth/models/user_model.dart';
import '../news/widgets/net_image.dart';
import '../shared/theme/theme_controller.dart';
import '../shared/widgets/badges.dart';
import '../shared/widgets/responsive.dart';

// ─── Email masking helper ─────────────────────────────────────────────────────
String _maskEmailStatic(String email) {
  if (email.isEmpty) return '—';
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

// ─── palette (matches the rest of the app) ────────────────────────────────────
const _blue       = Color(0xFF2563EB);
const _blueDark   = Color(0xFF1D4ED8);
const _bg         = Color(0xFFF0F4FF);
const _surface    = Colors.white;
const _textPri    = Color(0xFF1A1A2E);
const _textSec    = Color(0xFF475569);
const _divider    = Color(0xFFEEEEF5);
const _error      = Color(0xFFEF4444);

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  late final MjengoAuthController _auth;
  late final TabController _tabController;

  // ── Profile tab controllers ────────────────────────────────────────────────
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _bioCtrl        = TextEditingController();
  final _locationCtrl   = TextEditingController();
  final _companyCtrl    = TextEditingController();
  final _mjengoNetworksUrlCtrl = TextEditingController();
  final _shareBarabaraUrlCtrl  = TextEditingController();

  // ── Password tab controllers ───────────────────────────────────────────────
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureNew     = true;
  bool _obscureConfirm = true;

  bool _profileDirty  = false;
  bool _saving        = false;
  bool _uploadingAvatar = false;

  final _picker = ImagePicker();

  final _profileFormKey  = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _auth = Get.find<MjengoAuthController>();
    _tabController = TabController(length: 2, vsync: this);
    _populateFields(_auth.currentUser);

    // mark dirty when any profile field changes
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _phoneCtrl,
      _bioCtrl, _locationCtrl, _companyCtrl,
      _mjengoNetworksUrlCtrl, _shareBarabaraUrlCtrl,
    ]) {
      c.addListener(_onProfileChanged);
    }
  }

  void _populateFields(UserModel? user) {
    if (user == null) return;
    _firstNameCtrl.text = user.firstName ?? '';
    _lastNameCtrl.text  = user.lastName  ?? '';
    _phoneCtrl.text     = user.phoneNumber ?? '';
    _bioCtrl.text       = user.bio       ?? '';
    _locationCtrl.text  = user.location  ?? '';
    _companyCtrl.text   = user.company   ?? '';
    _mjengoNetworksUrlCtrl.text = user.mjengoNetworksUrl ?? '';
    _shareBarabaraUrlCtrl.text  = user.shareBarabaraUrl  ?? '';
    _profileDirty = false;
  }

  void _onProfileChanged() {
    if (!_profileDirty && mounted) setState(() => _profileDirty = true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _phoneCtrl,
      _bioCtrl, _locationCtrl, _companyCtrl,
      _mjengoNetworksUrlCtrl, _shareBarabaraUrlCtrl,
      _newPassCtrl, _confirmPassCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Save profile ───────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ok = await _auth.updateProfile(
      firstName : _firstNameCtrl.text.trim(),
      lastName  : _lastNameCtrl.text.trim(),
      phone     : _phoneCtrl.text.trim(),
      bio       : _bioCtrl.text.trim(),
      location  : _locationCtrl.text.trim(),
      company   : _companyCtrl.text.trim(),
      mjengoNetworksUrl : _mjengoNetworksUrlCtrl.text.trim(),
      shareBarabaraUrl  : _shareBarabaraUrlCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _saving       = false;
      _profileDirty = !ok;
    });

    if (ok) {
      _showSnack('Profile updated successfully', success: true);
      _populateFields(_auth.currentUser);
    } else {
      _showSnack(_auth.errorMessage.isNotEmpty
          ? _auth.errorMessage
          : 'Failed to update profile');
    }
  }

  // ── Save password ──────────────────────────────────────────────────────────
  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ok = await _auth.updateProfile(
      password: _newPassCtrl.text,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      _showSnack('Password changed successfully', success: true);
    } else {
      _showSnack(_auth.errorMessage.isNotEmpty
          ? _auth.errorMessage
          : 'Failed to change password');
    }
  }

  // ── Avatar upload ──────────────────────────────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar) return;

    final XFile? picked = kIsWeb
        ? await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85)
        : await _showAvatarSourceSheet();
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    final bytes = await picked.readAsBytes();
    final ok = await _auth.uploadAvatar(bytes, picked.name);

    if (!mounted) return;
    setState(() => _uploadingAvatar = false);

    _showSnack(
      ok
          ? 'Profile photo updated'
          : (_auth.errorMessage.isNotEmpty ? _auth.errorMessage : 'Failed to upload photo'),
      success: ok,
    );
  }

  Future<XFile?> _showAvatarSourceSheet() async {
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
              leading: const Icon(Icons.camera_alt_rounded, color: _blue),
              title: Text('Camera', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: _blue),
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

  void _showSnack(String msg, {bool success = false}) {
    Get.snackbar(
      success ? 'Success' : 'Error',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      backgroundColor: success ? const Color(0xFF22C55E) : _error,
      colorText: Colors.white,
      icon: Icon(
        success ? Icons.check_circle_outline : Icons.error_outline,
        color: Colors.white,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Obx(() {
      final user = _auth.currentUser;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _bg,
          body: Column(
            children: [
              // ── Hero header ──────────────────────────────────────────────
              _Hero(
                user: user,
                topPad: topPad,
                onBack: () => Get.back(),
                onTapAvatar: _pickAndUploadAvatar,
                uploadingAvatar: _uploadingAvatar,
              ),

              // ── Tab bar ──────────────────────────────────────────────────
              _TabBar(controller: _tabController),

              // ── Tab views ────────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _ProfileTab(
                      formKey      : _profileFormKey,
                      firstNameCtrl: _firstNameCtrl,
                      lastNameCtrl : _lastNameCtrl,
                      phoneCtrl    : _phoneCtrl,
                      bioCtrl      : _bioCtrl,
                      locationCtrl : _locationCtrl,
                      companyCtrl  : _companyCtrl,
                      mjengoNetworksUrlCtrl: _mjengoNetworksUrlCtrl,
                      shareBarabaraUrlCtrl: _shareBarabaraUrlCtrl,
                      user         : user,
                      dirty        : _profileDirty,
                      saving       : _saving,
                      onSave       : _saveProfile,
                    ),
                    _PasswordTab(
                      formKey       : _passwordFormKey,
                      newPassCtrl   : _newPassCtrl,
                      confirmCtrl   : _confirmPassCtrl,
                      obscureNew    : _obscureNew,
                      obscureConfirm: _obscureConfirm,
                      saving        : _saving,
                      onToggleNew   : () =>
                          setState(() => _obscureNew = !_obscureNew),
                      onToggleConfirm: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      onSave: _savePassword,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Hero header ─────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final UserModel? user;
  final double topPad;
  final VoidCallback onBack;
  final VoidCallback onTapAvatar;
  final bool uploadingAvatar;

  const _Hero({
    required this.user,
    required this.topPad,
    required this.onBack,
    required this.onTapAvatar,
    this.uploadingAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    final initials    = user?.initials ?? '?';
    final name        = user?.fullName ?? user?.firstName ?? 'My Account';
    final email       = _maskEmail(user?.email ?? '');
    final hasPhoto    = user?.photoURL != null && user!.photoURL!.isNotEmpty;
    final memberSince = user?.createdAt != null
        ? 'Member since ${_monthYear(user!.createdAt!)}'
        : '';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_blue, _blueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              // back + title row
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Account',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // avatar
              GestureDetector(
                onTap: onTapAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                      ),
                      child: ClipOval(
                        child: NetImage(
                          url: hasPhoto ? user!.photoURL : null,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (_) => _initialsW(initials),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _blueDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: uploadingAvatar
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                              )
                            : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // name + verified badge + email + member-since
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (user?.isPrime == true) const PrimeBadge(),
                ],
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
              if (memberSince.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  memberSince,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialsW(String i) => Center(
        child: Text(
          i,
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      );

  static String _maskEmail(String email) {
    if (email.isEmpty) return email;
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

  String _monthYear(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Custom tab bar ───────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      child: TabBar(
        controller: controller,
        labelColor: _blue,
        unselectedLabelColor: _textSec,
        indicatorColor: _blue,
        indicatorWeight: 2.5,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Edit Profile'),
          Tab(text: 'Change Password'),
        ],
      ),
    );
  }
}

// ─── Profile tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController companyCtrl;
  final TextEditingController mjengoNetworksUrlCtrl;
  final TextEditingController shareBarabaraUrlCtrl;
  final UserModel? user;
  final bool dirty;
  final bool saving;
  final VoidCallback onSave;

  const _ProfileTab({
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.phoneCtrl,
    required this.bioCtrl,
    required this.locationCtrl,
    required this.companyCtrl,
    required this.mjengoNetworksUrlCtrl,
    required this.shareBarabaraUrlCtrl,
    required this.user,
    required this.dirty,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ContentWidth(
        maxWidth: 600,
        child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Personal info ──────────────────────────────────────────────
            _SectionLabel('Personal Information'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          controller: firstNameCtrl,
                          label: 'First Name',
                          icon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          controller: lastNameCtrl,
                          label: 'Last Name',
                          icon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1, thickness: 0.8, color: _divider),
                  _Field(
                    controller: phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    hint: '+254 7XX XXX XXX',
                  ),
                  const Divider(height: 1, thickness: 0.8, color: _divider),
                  _Field(
                    controller: locationCtrl,
                    label: 'Location',
                    icon: Icons.location_on_outlined,
                    hint: 'e.g. Nairobi, Kenya',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Professional info ──────────────────────────────────────────
            _SectionLabel('Professional Details'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  _Field(
                    controller: companyCtrl,
                    label: 'Company / Organisation',
                    icon: Icons.business_outlined,
                    hint: 'Where do you work?',
                  ),
                  const Divider(height: 1, thickness: 0.8, color: _divider),
                  _Field(
                    controller: bioCtrl,
                    label: 'Bio',
                    icon: Icons.notes_outlined,
                    hint: 'Tell us about your professional background…',
                    maxLines: 3,
                    maxLength: 500,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Ecosystem links (self-service) ─────────────────────────────
            _SectionLabel('Ecosystem Links'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  _Field(
                    controller: mjengoNetworksUrlCtrl,
                    label: 'Mjengo Networks Profile',
                    icon: Icons.hub_rounded,
                    hint: 'https://mjengonetworks.co.ke/...',
                    keyboardType: TextInputType.url,
                  ),
                  const Divider(height: 1, thickness: 0.8, color: _divider),
                  _Field(
                    controller: shareBarabaraUrlCtrl,
                    label: 'Share Barabara Profile',
                    icon: Icons.directions_car_filled_rounded,
                    hint: 'https://sharebarabara.co.ke/...',
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Read-only email row ────────────────────────────────────────
            _SectionLabel('Account Info'),
            const SizedBox(height: 10),
            _Card(
              child: _ReadOnlyField(
                label: 'Email Address',
                value: _maskEmailStatic(user?.email ?? ''),
                icon: Icons.email_outlined,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Verified',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Appearance ──────────────────────────────────────────────────
            _SectionLabel('Appearance'),
            const SizedBox(height: 10),
            const _Card(child: _DarkModeToggle()),

            const SizedBox(height: 32),

            // ── Save button ────────────────────────────────────────────────
            _SaveButton(
              label   : 'Save Changes',
              enabled : dirty,
              loading : saving,
              onTap   : onSave,
            ),

            const SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );
  }
}

// ─── Password tab ─────────────────────────────────────────────────────────────

class _PasswordTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController newPassCtrl;
  final TextEditingController confirmCtrl;
  final bool obscureNew;
  final bool obscureConfirm;
  final bool saving;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSave;

  const _PasswordTab({
    required this.formKey,
    required this.newPassCtrl,
    required this.confirmCtrl,
    required this.obscureNew,
    required this.obscureConfirm,
    required this.saving,
    required this.onToggleNew,
    required this.onToggleConfirm,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ContentWidth(
        maxWidth: 600,
        child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info banner ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: _blue, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Choose a strong password with at least 6 characters. '
                      'You will be kept logged in after changing it.',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: _blue,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _SectionLabel('New Password'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  _PasswordField(
                    controller: newPassCtrl,
                    label: 'New Password',
                    obscure: obscureNew,
                    onToggle: onToggleNew,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter a new password';
                      if (v.length < 6) return 'At least 6 characters required';
                      return null;
                    },
                  ),
                  const Divider(height: 1, thickness: 0.8, color: _divider),
                  _PasswordField(
                    controller: confirmCtrl,
                    label: 'Confirm Password',
                    obscure: obscureConfirm,
                    onToggle: onToggleConfirm,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm password';
                      if (v != newPassCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),

            // ── strength hints ─────────────────────────────────────────────
            const SizedBox(height: 12),
            _StrengthHint(controller: newPassCtrl),

            const SizedBox(height: 32),

            _SaveButton(
              label  : 'Change Password',
              enabled: true,
              loading: saving,
              onTap  : onSave,
            ),

            const SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );
  }
}

// ─── Password strength hint ───────────────────────────────────────────────────

class _StrengthHint extends StatefulWidget {
  final TextEditingController controller;
  const _StrengthHint({required this.controller});

  @override
  State<_StrengthHint> createState() => _StrengthHintState();
}

class _StrengthHintState extends State<_StrengthHint> {
  String _pass = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  void _update() {
    if (mounted) setState(() => _pass = widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  int get _score {
    int s = 0;
    if (_pass.length >= 6)  s++;
    if (_pass.length >= 10) s++;
    if (_pass.contains(RegExp(r'[A-Z]')))  s++;
    if (_pass.contains(RegExp(r'[0-9]')))  s++;
    if (_pass.contains(RegExp(r'[^A-Za-z0-9]'))) s++;
    return s;
  }

  Color get _color {
    switch (_score) {
      case 0:
      case 1: return _error;
      case 2:
      case 3: return const Color(0xFFF59E0B);
      default: return const Color(0xFF22C55E);
    }
  }

  String get _label {
    switch (_score) {
      case 0:
      case 1: return 'Weak';
      case 2:
      case 3: return 'Fair';
      default: return 'Strong';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pass.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < _score ? _color : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            'Strength: $_label',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: _color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _textSec,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _DarkModeToggle extends StatelessWidget {
  const _DarkModeToggle();

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPri,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Applies immediately and is remembered on this device.',
                  style: GoogleFonts.montserrat(fontSize: 11.5, color: _textSec),
                ),
              ],
            ),
          ),
          Obx(() => Switch(
                value: theme.isDarkMode,
                activeColor: _blue,
                onChanged: theme.setDarkMode,
              )),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _blue.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: validator,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          color: _textPri,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: _textSec),
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.montserrat(
            fontSize: 12,
            color: _textSec,
          ),
          hintStyle: GoogleFonts.montserrat(
            fontSize: 12,
            color: const Color(0xFF475569),
          ),
          counterStyle: GoogleFonts.montserrat(fontSize: 10.5, color: _textSec),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          isDense: true,
          errorStyle: GoogleFonts.montserrat(fontSize: 10, color: _error),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          color: _textPri,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: _textSec),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: _textSec,
            ),
            onPressed: onToggle,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          labelText: label,
          labelStyle: GoogleFonts.montserrat(fontSize: 12, color: _textSec),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          isDense: true,
          errorStyle: GoogleFonts.montserrat(fontSize: 10, color: _error),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textSec),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: _textSec,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: _textPri,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _SaveButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(colors: [_blue, _blueDark])
              : null,
          color: enabled ? null : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: (enabled && !loading) ? onTap : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: enabled ? Colors.white : _textSec,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
