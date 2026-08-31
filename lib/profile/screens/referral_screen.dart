// lib/profile/screens/referral_screen.dart
//
// Referral engine: shows the user's unique code + shareable invite link with
// one-tap copy/share, and a manual redemption field for Google-OAuth /
// existing users who signed up without a ?ref= link.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../point/models/points_models.dart';
import '../../point/services/gamification_service.dart';
import '../../shared/theme/app_theme.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _service = GamificationService();
  final _redeemCtrl = TextEditingController();
  ReferralInfo? _info;
  bool _loading = true;
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Get.find<MjengoAuthController>();
    final fetched = await _service.getReferralInfo();
    final code = fetched?.code.isNotEmpty == true
        ? fetched!.code
        : (auth.currentUser?.referralCode ?? '');
    if (!mounted) return;
    setState(() {
      _info = ReferralInfo(
        code: code,
        shareUrl: fetched?.shareUrl ??
            (code.isNotEmpty ? 'https://mjengohub.co.ke/register?ref=$code' : 'https://mjengohub.co.ke'),
        totalReferred: fetched?.totalReferred ?? 0,
      );
      _loading = false;
    });
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _info?.shareUrl ?? ''));
    Get.snackbar('Copied', 'Invite link copied to clipboard',
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
  }

  void _share() {
    if (_info == null) return;
    Share.share(
      'Join me on Mjengo Hub — Kenya\'s construction & infrastructure platform! '
      'Sign up with my link and we both earn points: ${_info!.shareUrl}',
      subject: 'Join me on Mjengo Hub',
    );
  }

  Future<void> _redeem() async {
    final code = _redeemCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _redeeming = true);
    final error = await _service.redeemReferralCode(code);
    if (!mounted) return;
    setState(() => _redeeming = false);
    if (error == null) {
      _redeemCtrl.clear();
      Get.snackbar('Success', 'Referral code applied — thanks for joining!',
          backgroundColor: AppColors.success, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    } else {
      Get.snackbar('Couldn\'t redeem', error,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text('Referrals', style: GoogleFonts.montserrat(color: AppColors.textDark, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.verifiedPillGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invite friends, earn points',
                            style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(
                          '+5 points when they join, +20 more if they go Mjengo Hub Prime.',
                          style: GoogleFonts.montserrat(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _info?.code.isNotEmpty == true ? _info!.code : '—',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 2),
                                ),
                              ),
                              GestureDetector(
                                onTap: _copy,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                                  child: const Icon(Icons.copy_rounded, size: 17, color: AppColors.primaryBlue),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _share,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.ios_share_rounded, size: 17),
                            label: Text('Share Invite Link', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.groups_rounded, color: AppColors.accentBlue, size: 22),
                        const SizedBox(width: 10),
                        Text('${_info?.totalReferred ?? 0} people joined with your code',
                            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Have a referral code?',
                      style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text('Signed up with Google or missed the invite link? Redeem a code here.',
                      style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _redeemCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: GoogleFonts.montserrat(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Enter code',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _redeeming ? null : _redeem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _redeeming
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Apply', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
