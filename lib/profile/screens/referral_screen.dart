// lib/profile/screens/referral_screen.dart
//
// Referral engine. Gated: `referrals/me` and `referrals/redeem` don't exist
// on the backend yet (see GamificationService), and the User model has no
// `referral_code` column either, so there's no real code/link/redemption to
// show. Kept as a reachable screen (rather than removing the nav entry) so
// it can be wired up once the backend ships these routes.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/coming_soon.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

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
      body: const ComingSoonPlaceholder(
        icon: Icons.card_giftcard_rounded,
        title: 'Referrals are coming soon',
        message: 'Invite links, referral codes and reward tracking will '
            'appear here once this feature is live.',
      ),
    );
  }
}
