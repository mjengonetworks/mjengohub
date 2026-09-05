// lib/shared/widgets/partners_carousel.dart
//
// Homepage section 27: a single-row, continuously auto-scrolling marquee of
// partner placeholder cards. There is no partner-listing endpoint under
// /api/v1 (only an admin-side `partners` table used by the website's own
// templates), so — same precedent as AdBannerSlot — this renders clearly
// labeled placeholder cards rather than fabricating partner names/logos.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class PartnersCarousel extends StatefulWidget {
  const PartnersCarousel({super.key});

  @override
  State<PartnersCarousel> createState() => _PartnersCarouselState();
}

class _PartnersCarouselState extends State<PartnersCarousel> {
  final _controller = ScrollController();
  Timer? _timer;
  static const int _placeholderCount = 8;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _placeholderCount * 3,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _PartnerCard(index: i % _placeholderCount),
      ),
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
        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.captionSlate),
      ),
    );
  }
}
