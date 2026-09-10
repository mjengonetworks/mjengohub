// lib/shared/widgets/partners_carousel.dart
//
// Homepage section 27: a single-row, continuously auto-scrolling marquee of
// partner/ecosystem-stakeholder logos. Fetches SiteService.getPartners() —
// there's no live /api/v1 endpoint for this yet (see Partner's doc comment
// in site_service.dart), so this starts from (and falls back to, if the
// endpoint ever returns empty) the same real partner set the website's own
// homepage hardcodes (templates/homepage.html's "Our Partners" marquee:
// Associated Construction, ISM, Sogea), pulled from mjengohub.co.ke's own
// static assets. This must never show generic "Partner 1"/"Partner 2"
// placeholder boxes -- those looked broken and shipped genuine partners'
// names nowhere.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/net_image.dart';
import '../services/link_launcher.dart';
import '../services/site_service.dart';
import '../theme/app_theme.dart';

/// The website's real, always-on partner set (templates/homepage.html),
/// hotlinked to its static assets so the app shows genuine logos even
/// before/without a live `site/partners` API response.
const List<Partner> kDefaultPartners = [
  Partner(
    id: -1,
    name: 'Associated Construction',
    logo: 'https://mjengohub.co.ke/static/images/partners/asociated-construction.jpg',
  ),
  Partner(
    id: -2,
    name: 'ISM',
    logo: 'https://mjengohub.co.ke/static/images/partners/ism.webp',
  ),
  Partner(
    id: -3,
    name: 'Sogea',
    logo: 'https://mjengohub.co.ke/static/images/partners/sogea.png',
  ),
];

class PartnersCarousel extends StatefulWidget {
  const PartnersCarousel({super.key});

  @override
  State<PartnersCarousel> createState() => _PartnersCarouselState();
}

class _PartnersCarouselState extends State<PartnersCarousel> {
  final _controller = ScrollController();
  final _service = SiteService();
  Timer? _timer;
  List<Partner> _partners = kDefaultPartners;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    _service.getPartners().then((p) {
      if (mounted && p.isNotEmpty) setState(() => _partners = p);
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
    await LinkLauncher.openLink(context, url);
  }

  @override
  Widget build(BuildContext context) {
    // Tripled so the marquee always has enough width to scroll continuously
    // even with as few as 3 partners.
    final itemCount = _partners.length * 3;

    return SizedBox(
      height: 80,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _PartnerLogoCard(partner: _partners[i % _partners.length], onTap: _openPartner),
      ),
    );
  }
}

// Standard luminance-weighted greyscale matrix — logos sit muted/grayscale
// by default and snap to full color on hover (desktop/web only; touch
// devices simply never trigger MouseRegion, so logos stay muted there).
const List<double> _kGreyscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];

class _PartnerLogoCard extends StatefulWidget {
  final Partner partner;
  final void Function(Partner) onTap;
  const _PartnerLogoCard({required this.partner, required this.onTap});

  @override
  State<_PartnerLogoCard> createState() => _PartnerLogoCardState();
}

class _PartnerLogoCardState extends State<_PartnerLogoCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final hasLogo = widget.partner.logo != null && widget.partner.logo!.isNotEmpty;
    final logo = NetImage(
      url: widget.partner.logo,
      fit: BoxFit.contain,
      placeholderColor: Colors.transparent,
      errorBuilder: (_) => _NameFallback(name: widget.partner.name),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.partner),
        child: Container(
          width: 160,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.sharp),
            border: Border.all(color: _hovering ? AppColors.accentBlue : AppColors.borderSlate),
          ),
          child: hasLogo
              ? (_hovering ? logo : ColorFiltered(colorFilter: const ColorFilter.matrix(_kGreyscaleMatrix), child: logo))
              : _NameFallback(name: widget.partner.name),
        ),
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
