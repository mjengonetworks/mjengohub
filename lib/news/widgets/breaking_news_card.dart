// lib/news/widgets/breaking_news_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/preview_data_badge.dart';
import '../models/article_model.dart';
import 'net_image.dart';

/// Card used in the horizontal "Breaking News" row on the Home screen.
class BreakingNewsCard extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;

  /// True when [article] is fallback/demo content rather than a live API
  /// response — shows a "PREVIEW" badge so it's never mistaken for real news.
  final bool showPreviewBadge;

  const BreakingNewsCard({
    Key? key,
    required this.article,
    this.onTap,
    this.showPreviewBadge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(
                      url: article.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholderColor: const Color(0xFFE5E7EB),
                    ),
                    if (showPreviewBadge)
                      const Positioned(top: 6, left: 6, child: PreviewDataBadge()),
                  ],
                ),
              ),
            ),

            // Text area
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.timeAgo,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  if (article.author != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'By ${article.author!.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
