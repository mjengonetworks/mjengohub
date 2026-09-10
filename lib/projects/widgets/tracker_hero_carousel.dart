// lib/projects/widgets/tracker_hero_carousel.dart
//
// Standardized dynamic hero carousel shared by every tracker screen (Built
// History, Africa & World, Private Developments) — a slim 150px strip that
// auto-rotates through the tracker's top loaded photos with a dark gradient
// overlay and the same clamped indicator lines PageDotIndicator already
// uses on the homepage hero, so trackers read as one consistent system
// rather than four bespoke headers.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/featured_article_card.dart' show PageDotIndicator;
import '../../news/widgets/net_image.dart';
import '../../shared/theme/app_theme.dart';

class TrackerHeroCarousel extends StatefulWidget {
  final String title;
  final String subtitle;

  /// Top loaded/featured project photos for this tracker — deduped,
  /// non-null. An empty list still renders the strip with a flat
  /// placeholder background rather than being skipped.
  final List<String> imageUrls;
  final double height;

  const TrackerHeroCarousel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrls,
    this.height = 150,
  });

  @override
  State<TrackerHeroCarousel> createState() => _TrackerHeroCarouselState();
}

class _TrackerHeroCarouselState extends State<TrackerHeroCarousel> {
  final _controller = PageController();
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _armAutoplay();
  }

  @override
  void didUpdateWidget(covariant TrackerHeroCarousel old) {
    super.didUpdateWidget(old);
    if (old.imageUrls.length != widget.imageUrls.length) {
      _index = 0;
      _armAutoplay();
    }
  }

  void _armAutoplay() {
    _timer?.cancel();
    if (widget.imageUrls.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.imageUrls.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls.isEmpty ? [null] : widget.imageUrls;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => NetImage(
                  url: images[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholderColor: AppColors.deepNavy,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xDE000000), Color(0x8A000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: PageDotIndicator(
                    count: images.length,
                    current: _index,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
