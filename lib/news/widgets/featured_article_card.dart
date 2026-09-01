// lib/news/widgets/featured_article_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/preview_data_badge.dart';
import '../models/article_model.dart';
import 'net_image.dart';

/// Full-bleed hero card shown at the top of the Home feed.
class FeaturedArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;

  /// True when [article] is fallback/demo content rather than a live API
  /// response — shows a "PREVIEW" badge so it's never mistaken for real news.
  final bool showPreviewBadge;

  const FeaturedArticleCard({
    Key? key,
    required this.article,
    this.onTap,
    this.showPreviewBadge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──────────────────────────────────────────
          NetImage(
            url: article.imageUrl,
            fit: BoxFit.cover,
            placeholderColor: const Color(0xFF1F2937),
          ),

          // ── Dark gradient overlay ─────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000),
                  Color(0x88000000),
                  Color(0xEE000000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Preview badge (top-right), only for fallback/demo content ──
          if (showPreviewBadge)
            const Positioned(
              top: 60,
              right: 20,
              child: PreviewDataBadge(),
            ),

          // ── Text content at bottom ────────────────────────────────────
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // "News of the day" badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 0.8),
                  ),
                  child: Text(
                    article.category?.name ?? 'News of the day',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Article title
                Text(
                  article.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),

                // "Learn More →" button
                Row(
                  children: [
                    Text(
                      'Learn More',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimalist line/underscore-dash indicators for the featured PageView —
/// mirrors the website's `.mj-hero-dot` (thin flat segments, not circular
/// dots), sized so they never overlap the hero's search bar or action
/// buttons above/below.
class PageDotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const PageDotIndicator(
      {Key? key, required this.count, required this.current})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 36 : 28,
          height: 3,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
