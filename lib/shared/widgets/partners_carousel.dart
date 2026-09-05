// lib/shared/widgets/partners_carousel.dart
//
// Homepage section 27: a single-row, continuously auto-scrolling marquee of
// partner/ecosystem-stakeholder logos. Fetches SiteService.getPartners() —
// there's no live /api/v1 endpoint for this yet (see Partner's doc comment
// in site_service.dart), so this always falls back to clearly-labeled
// placeholder cards today, the same guaranteed-non-empty precedent used
// elsewhere on the homepage (Built History, Africa & World, etc.).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../news/widgets/net_image.dart';
import '../services/site_service.dart';
import '../theme/app_theme.dart';

class PartnersCarousel extends StatefulWidget {
  const PartnersCarousel({super.key});

  @override
  State<PartnersCarousel> createState() => _PartnersCarouselState();
}

class _PartnersCarouselState extends State<PartnersCarousel> {
  final _controller = ScrollController();
  final _service = SiteService();
  Timer? _timer;
  List<Partner> _partners = [];
  static const int _placeholderCount = 8;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    _service.getPartners().then((p) {
      if (mounted) setState(() => _partners = p);
    });
  }

  void _tick() {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    if (max <= 0) return;
    final next = _controller.offset + 0.6;
    _controller.jumpTo(next >= max ? 0 : next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openPartner(Partner p) async {
    final url = p.websiteUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useReal = _partners.isNotEmpty;
    final itemCount = useReal ? _partners.length * 3 : _placeholderCount * 3;

    return SizedBox(
      height: 72,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => useReal
            ? _PartnerLogoCard(partner: _partners[i % _partners.length], onTap: _openPartner)
            : _PartnerCard(index: i % _placeholderCount),
      ),
    );
  }
}

class _PartnerLogoCard extends StatelessWidget {
  final Partner partner;
  final void Function(Partner) onTap;
  const _PartnerLogoCard({required this.partner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(partner),
      child: Container(
        width: 132,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sharp),
          border: Border.all(color: AppColors.borderSlate),
        ),
        child: (partner.logo != null && partner.logo!.isNotEmpty)
            ? NetImage(
                url: partner.logo,
                fit: BoxFit.contain,
                placeholderColor: Colors.transparent,
                errorBuilder: (_) => _NameFallback(name: partner.name),
              )
            : _NameFallback(name: partner.name),
      ),
    );
  }
}

class _NameFallback extends StatelessWidget {
  final String name;
  const _NameFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.captionSlate),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final int index;
  const _PartnerCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: AppColors.borderSlate),
      ),
      child: Text(
        'Partner ${index + 1}',
        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.captionSlate),
      ),
    );
  }
}
