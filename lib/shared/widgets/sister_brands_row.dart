// lib/shared/widgets/sister_brands_row.dart
//
// Compact horizontal row for the two sister brands (Mjengo Networks, Share
// Barabara) — small circular icon chips, never stacking vertically. Distinct
// from the full-width promotional banners (MjengoNetworksBanner /
// ShareBarabaraBanner in home_extra_sections.dart), which stay as-is; this is
// a lightweight brand-affiliation strip. No bundled logo image assets exist
// for either sister brand, so each chip uses a themed Material icon inside a
// ClipOval frame (BoxFit.contain semantics — an icon glyph, never clipped)
// rather than a raw Image.network guess at a logo URL.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/link_launcher.dart';
import '../theme/app_theme.dart';

class SisterBrandsRow extends StatelessWidget {
  const SisterBrandsRow({super.key});

  static const String _mjengoNetworksUrl = 'https://mjengonetworks.co.ke/';
  static const String _shareBarabaraUrl = 'https://sharebarabara.co.ke';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BrandChip(
          label: 'Mjengo Networks',
          icon: Icons.hub_rounded,
          color: AppColors.deepNavy,
          onTap: () => LinkLauncher.openLink(context, _mjengoNetworksUrl),
        ),
        const SizedBox(width: 20),
        _BrandChip(
          label: 'Share Barabara',
          icon: Icons.directions_car_filled_rounded,
          color: AppColors.danger,
          onTap: () => LinkLauncher.openLink(context, _shareBarabaraUrl),
        ),
      ],
    );
  }
}

class _BrandChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _BrandChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              color: color.withValues(alpha: 0.12),
              child: Icon(icon, size: 12, color: color),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.captionSlate,
            ),
          ),
        ],
      ),
    );
  }
}
