// lib/profile/screens/referral_screen.dart
//
// Referral code + sharing, wired to the live `GET referrals/me` /
// `POST referrals/redeem` endpoints (GamificationService).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../point/models/points_models.dart';
import '../../point/services/gamification_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/social_share_modal.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _api = GamificationService();
  final _redeemCtrl = TextEditingController();

  ReferralInfo? _info;
  bool _loading = true;
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _redeemCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final info = await _api.getReferralInfo();
    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
    });
  }

  Future<void> _redeem() async {
    final code = _redeemCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _redeeming = true);
    final error = await _api.redeemReferralCode(code);
    if (!mounted) return;
    setState(() => _redeeming = false);

    if (error == null) {
      _redeemCtrl.clear();
      Get.snackbar(
        'Code redeemed',
        'Thanks — your referral has been recorded.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      _load();
    } else {
      Get.snackbar(
        'Could not redeem',
        error,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    Get.snackbar(
      'Copied',
      'Referral code copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text('Referrals', style: GoogleFonts.montserrat(color: AppColors.textDark, fontWeight: FontWeight.w500)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : _info == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Could not load your referral details. Pull to refresh or try again later.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(fontSize: 13.5, color: AppColors.textSubtle),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── Code card ──────────────────────────────────────────
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
                            Text(
                              'Your referral code',
                              style: GoogleFonts.montserrat(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _info!.code.isNotEmpty ? _info!.code : '—',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _copyCode(_info!.code),
                                  icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => SocialShareModal.show(
                                  context,
                                  title: 'Join me on Mjengo Hub — Kenya\'s construction industry platform:',
                                  url: _info!.shareUrl,
                                ),
                                icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.primaryBlue),
                                label: Text('Share invite link', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500, color: AppColors.primaryBlue)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Total referred ──────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.sharpLg)),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.people_alt_rounded, color: AppColors.accentBlue, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_info!.totalReferred}', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                                  Text('friends referred', style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Redeem a code ───────────────────────────────────────
                      Text('Have a referral code?', style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text(
                        'Enter a friend\'s code to link your account to their referral.',
                        style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _redeemCtrl,
                              hint: 'Enter code',
                              textCapitalization: TextCapitalization.characters,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _redeeming ? null : _redeem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _redeeming
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text('Redeem', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
